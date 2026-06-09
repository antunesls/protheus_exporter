import re
import sys


def main():
    if len(sys.argv) < 2:
        return

    version = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    with open("CHANGELOG.md") as f:
        content = f.read()

    pattern = r"(?ms)##\s*\[" + re.escape(version) + r"\].*?(?=\[|\Z)"
    match = re.search(pattern, content)

    if match:
        body = match.group(0)
        body = re.sub(r"^## .*", "", body).strip()
    else:
        body = f"Release {version}"

    if output_file:
        with open(output_file, "w") as f:
            f.write(body)
    else:
        print(body)


if __name__ == "__main__":
    main()
