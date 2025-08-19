import re
import sys


def count_bytes(text):
    """
    Count all occurrences of 0x followed by 1–2 hex digits.
    """
    # This finds things like 0x00, 0x1A, 0xff, etc.
    matches = re.findall(r"0x[0-9A-Fa-f]{1,2}", text)
    return len(matches)


def main():
    if len(sys.argv) > 1:
        # Read from the file you pass as first argument
        with open(sys.argv[1], "r", encoding="utf-8") as f:
            data = f.read()
    else:
        # Otherwise read from standard input (paste and then Ctrl-D / Ctrl-Z)
        print(
            "Paste your byte array (e.g. 0x00,0xff,0x1A,…) then press Ctrl-D (on Linux/macOS) or Ctrl-Z (Windows):"
        )
        data = sys.stdin.read()

    total = count_bytes(data)
    print(f"Total bytes found: {total}")


if __name__ == "__main__":
    main()
