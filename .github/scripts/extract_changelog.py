import re
import sys


def main():
    if len(sys.argv) < 2:
        print("notes=")
        return

    version = sys.argv[1]

    with open("CHANGELOG.md") as f:
        content = f.read()

    pattern = r"(?ms)\[" + re.escape(version) + r"\].*?(?=\[|\Z)"
    match = re.search(pattern, content)

    if match:
        body = match.group(0)
        body = re.sub(r"^## .*", "", body).strip()
        body = body.replace("%", "%25")
        body = body.replace("\n", "%0A")
        print(f"notes={body}")
    else:
        print(f"notes=Release {version}")


if __name__ == "__main__":
    main()
