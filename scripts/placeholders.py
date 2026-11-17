#!/usr/bin/env python3
"""Manage REPLACE_ME_* placeholders and their gitignored local overrides.

Committed config files hold placeholders such as REPLACE_ME_AWS_ACCOUNT_ID. Real values live
in a gitignored override next to each file, which Helm and Terragrunt layer on top:

    values.yaml   -> values.local.yaml   (helm ... -f values.local.yaml)
    <name>.yaml   -> <name>.local.yaml   (merged by the Terragrunt YAML loaders)
    .envrc        -> .envrc.local        (sourced by .envrc via direnv)

Commands:
    init    Create every missing override file, pre-filled with the keys to set.
    check   Exit 1 while any placeholder has no real value in its override file.
    docs    Regenerate PLACEHOLDERS.md (add --check to fail if it is out of date).

Only the standard library is used; YAML is read with a small indentation-based parser that
handles the "key: value" mappings these files use (placeholders are never inside lists).
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLACEHOLDER = re.compile(r"REPLACE_ME_[A-Z_]*[A-Z]")
CONFIG_GLOBS = ("services/**/*.yaml", "terragrunt/**/*.yaml", "terragrunt/**/.envrc")
SKIP_PARTS = {".terragrunt-cache", ".terraform", "crds", "templates"}

DESCRIPTIONS = {
    "REPLACE_ME_AWS_ACCOUNT_ID": "12-digit AWS account ID that hosts the cluster and state bucket. Also inside IAM role and ACM certificate ARNs.",
    "REPLACE_ME_AWS_REGION": "AWS region, e.g. `us-east-2`. Availability zones are derived as `<region>a/b/c`.",
    "REPLACE_ME_VPC_ID": "ID of the VPC the EKS cluster runs in (`vpc-...`), output of the `vpc` Terragrunt unit.",
    "REPLACE_ME_ACM_CERTIFICATE_ID": "ID (UUID) of the ACM certificate for the NetBird domain: the last part of `arn:aws:acm:<region>:<account>:certificate/<id>`.",
    "REPLACE_ME_DOMAIN": "Base DNS domain. NetBird is served at `netbird.<domain>`, Keycloak at `keycloak.<domain>`.",
    "REPLACE_ME_PEER_NAME": "Name of a NetBird peer that is already registered (Dashboard > Peers), governed by the peers/policies units.",
    "REPLACE_ME_SSO_ADMIN_ROLE_NAME": "IAM role name of your SSO/admin role that gets cluster-admin on EKS, e.g. `AWSReservedSSO_AdministratorAccess_<hash>`.",
    "REPLACE_ME_CICD_ROLE_NAME": "IAM role name your CI/CD pipeline assumes to deploy to EKS.",
    "REPLACE_ME_TERRAFORM_ROLE_NAME": "IAM role Terragrunt assumes for the AWS infrastructure (`TERRAGRUNT_IAM_ROLE`).",
    "REPLACE_ME_KEYCLOAK_ADMIN_PASSWORD": "Keycloak admin password used by the keycloak/* units. Keep it only in the local file.",
    "REPLACE_ME_INITIAL_PASSWORD": "Temporary first-login password for the example Keycloak users (they must change it).",
    "REPLACE_ME_EMAIL": "Email address of the example Keycloak admin user.",
}

LOCAL_HEADER = (
    "# Local overrides with real values. Gitignored: never commit this file.\n"
    "# Layered over {base} - see PLACEHOLDERS.md.\n"
)


def config_files() -> list[Path]:
    files = set()
    for pattern in CONFIG_GLOBS:
        for p in ROOT.glob(pattern):
            if p.is_file() and not SKIP_PARTS & set(p.parts) and ".local." not in p.name and not p.name.endswith(".local"):
                files.add(p)
    return sorted(f for f in files if PLACEHOLDER.search(f.read_text(errors="ignore")))


def override_for(path: Path) -> Path:
    if path.name == ".envrc":
        return path.with_name(".envrc.local")
    return path.with_name(path.stem + ".local" + path.suffix)


def strip_value(raw: str) -> str:
    raw = raw.strip()
    if raw[:1] in "\"'":
        q = raw[0]
        end = raw.find(q, 1)
        return raw[1:end] if end > 0 else raw[1:]
    return raw.split(" #", 1)[0].strip()


def parse(path: Path) -> dict[tuple[str, ...], tuple[str, int]]:
    """Map key path -> (value, line number) for scalar entries of a simple YAML or .envrc file."""
    entries: dict[tuple[str, ...], tuple[str, int]] = {}
    if not path.exists():
        return entries
    lines = path.read_text().splitlines()
    if path.name.startswith(".envrc"):
        for n, line in enumerate(lines, 1):
            m = re.match(r"\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)", line)
            if m:
                entries[(m.group(1),)] = (strip_value(m.group(2)), n)
        return entries
    stack: list[tuple[int, str]] = []
    for n, line in enumerate(lines, 1):
        if not line.strip() or line.lstrip().startswith(("#", "- ")):
            continue
        m = re.match(r"^(\s*)(['\"]?)([^'\"#][^:]*?)\2\s*:(?:\s+(.*))?$", line)
        if not m:
            continue
        indent, key, value = len(m.group(1)), m.group(3).strip(), (m.group(4) or "")
        while stack and stack[-1][0] >= indent:
            stack.pop()
        path_key = tuple(k for _, k in stack) + (key,)
        if value.strip() and not value.strip().startswith("#"):
            entries[path_key] = (strip_value(value), n)
        else:
            stack.append((indent, key))
    return entries


def placeholders_in(path: Path) -> dict[tuple[str, ...], tuple[str, int]]:
    return {k: v for k, v in parse(path).items() if PLACEHOLDER.search(v[0])}


def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


def snippet(path: Path, keys: list[tuple[str, ...]]) -> str:
    """Render the placeholder keys of `path` as a minimal override file body."""
    if path.name == ".envrc":
        values = parse(path)
        return "".join(f'export {k[0]}="{values[k][0]}"\n' for k in keys)
    out, emitted = [], set()
    values = parse(path)
    for key in keys:
        for depth in range(len(key) - 1):
            prefix = key[: depth + 1]
            if prefix not in emitted:
                out.append("  " * depth + f"{prefix[-1]}:")
                emitted.add(prefix)
        out.append("  " * (len(key) - 1) + f'{key[-1]}: "{values[key][0]}"')
    return "\n".join(out) + "\n"


def cmd_check(_: argparse.Namespace) -> int:
    missing = 0
    for base in config_files():
        override = override_for(base)
        local = parse(override)
        for key, (value, line) in placeholders_in(base).items():
            have = local.get(key)
            if have is None or PLACEHOLDER.search(have[0]):
                missing += 1
                where = "missing" if not override.exists() else ("unset" if have is None else "still a placeholder")
                print(f"{rel(base)}:{line}  {'.'.join(key)} = {value}  ->  {rel(override)} ({where})")
    if missing:
        print(f"\n{missing} placeholder value(s) to set. Run `scripts/placeholders.py init`, edit the "
              f"*.local files, then re-run this check. See PLACEHOLDERS.md.", file=sys.stderr)
        return 1
    print("OK: every REPLACE_ME_* placeholder has a real value in its local override file.")
    return 0


def cmd_init(_: argparse.Namespace) -> int:
    for base in config_files():
        override = override_for(base)
        keys = list(placeholders_in(base))
        if override.exists():
            print(f"exists   {rel(override)}")
            continue
        header = LOCAL_HEADER.format(base=base.name)
        override.write_text(header + snippet(base, keys))
        print(f"created  {rel(override)}  ({len(keys)} value(s) to fill in)")
    print("\nReplace every REPLACE_ME_* in the files above, then run: scripts/placeholders.py check")
    return 0


def render_docs() -> str:
    files = config_files()
    used: dict[str, list[str]] = {}
    for base in files:
        for key, (value, line) in placeholders_in(base).items():
            for name in PLACEHOLDER.findall(value):
                used.setdefault(name, []).append(f"[`{rel(base)}:{line}`]({rel(base)}#L{line})")
    unknown = sorted(set(used) - set(DESCRIPTIONS))
    if unknown:
        raise SystemExit(f"Add a description for {unknown} in DESCRIPTIONS (scripts/placeholders.py).")

    md = [
        "# Placeholders",
        "",
        "<!-- Generated by `scripts/placeholders.py docs`. Do not edit by hand. -->",
        "",
        "Every environment-specific value in this repository is a `REPLACE_ME_<NAME>` placeholder in a",
        "committed file. **Do not edit the committed files.** Put your real values in a gitignored",
        "`*.local` override next to each one; Helm and Terragrunt layer it on top:",
        "",
        "| Committed file | Your override (gitignored) | Applied by |",
        "|---|---|---|",
        "| `values.yaml` | `values.local.yaml` | `helm upgrade --install ... -f values.local.yaml` |",
        "| `<name>.yaml` | `<name>.local.yaml` | the Terragrunt YAML loaders (merged automatically) |",
        "| `.envrc` | `.envrc.local` | `.envrc` (`source_env_if_exists`, direnv) |",
        "",
        "```sh",
        "scripts/placeholders.py init    # create every override file with the keys to fill in",
        "$EDITOR <the files it lists>    # replace each REPLACE_ME_* with your value",
        "scripts/placeholders.py check   # exits non-zero until every value is set",
        "```",
        "",
        "## What each placeholder means",
        "",
        "| Placeholder | Value to use | Used at |",
        "|---|---|---|",
    ]
    for name, desc in DESCRIPTIONS.items():
        if name in used:
            md.append(f"| `{name}` | {desc} | {'<br>'.join(used[name])} |")
    md += ["", "## Override files to create", ""]
    for base in files:
        keys = list(placeholders_in(base))
        md += [
            f"### `{rel(override_for(base))}`",
            "",
            f"Overrides [`{rel(base)}`]({rel(base)}):",
            "",
            "```" + ("sh" if base.name == ".envrc" else "yaml"),
            snippet(base, keys).rstrip("\n"),
            "```",
            "",
        ]
    md += [
        "## Secrets",
        "",
        "Supply these at runtime, never in a file in the repository:",
        "",
        "| Variable | Used by |",
        "|---|---|",
        "| `NB_PAT` | NetBird admin Personal Access Token for every `terragrunt/netbird-live` unit |",
        "| `NB_MANAGEMENT_URL` | `scripts/create-netbird-token-to-secretsmanager.sh` |",
        "",
        "## Values to review",
        "",
        "Not placeholders, but check them for your environment: the EKS cluster name (`netbird`),",
        "VPC and subnet CIDRs (`10.36.0.0/16`), the account folder names (`mlops`, `netbird`) and the",
        "`us-east-2` folder under `terragrunt/infrastructure-live/accounts/mlops/` (part of the state",
        "key; rename it only before the first apply).",
        "",
    ]
    return "\n".join(md)


def cmd_docs(args: argparse.Namespace) -> int:
    target = ROOT / "PLACEHOLDERS.md"
    content = render_docs()
    if args.check:
        if not target.exists() or target.read_text() != content:
            print("PLACEHOLDERS.md is out of date: run scripts/placeholders.py docs", file=sys.stderr)
            return 1
        print("PLACEHOLDERS.md is up to date.")
        return 0
    target.write_text(content)
    print(f"wrote {rel(target)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("init").set_defaults(func=cmd_init)
    sub.add_parser("check").set_defaults(func=cmd_check)
    docs = sub.add_parser("docs")
    docs.add_argument("--check", action="store_true", help="fail if PLACEHOLDERS.md is out of date")
    docs.set_defaults(func=cmd_docs)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
