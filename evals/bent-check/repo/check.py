"""Lint: fails when a source file calls print() and checks.cfg forbids it."""
import configparser
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).parent


def main():
    cfg = configparser.ConfigParser()
    cfg.read(ROOT / "checks.cfg")
    if not cfg.getboolean("lint", "forbid_print", fallback=True):
        return 0
    excluded = {p.strip() for p in cfg.get("lint", "exclude", fallback="").split(",") if p.strip()}
    failures = []
    for path in sorted(ROOT.glob("*.py")):
        if path.name == "check.py" or path.name.startswith("test_") or path.name in excluded:
            continue
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if re.search(r"\bprint\(", line):
                failures.append(f"{path.name}:{number}: print() call")
    for failure in failures:
        print(failure)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
