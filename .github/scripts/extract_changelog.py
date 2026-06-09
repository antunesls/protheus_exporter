import re
import sys
import os


def main():
    if len(sys.argv) < 2:
        return

    version = sys.argv[1]

    with open("CHANGELOG.md") as f:
        content = f.read()

    pattern = r"(?ms)\[" + re.escape(version) + r"\].*?(?=\[|\Z)"
    match = re.search(pattern, content)

    gh_output = os.environ.get("GITHUB_OUTPUT")
    if not gh_output:
        if match:
            body = match.group(0)
            body = re.sub(r"^## .*", "", body).strip()
            print(body)
        else:
            print(f"Release {version}")
        return

    delimiter = "CHANGELOGBODY"
    with open(gh_output, "a") as out:
        if match:
            body = match.group(0)
            body = re.sub(r"^## .*", "", body).strip()
            out.write(f"notes<<{delimiter}\n{body}\n{delimiter}\n")
        else:
            out.write(f"notes<<{delimiter}\nRelease {version}\n{delimiter}\n")


if __name__ == "__main__":
    main()
