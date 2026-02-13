import string
import sys


def main():
    file_count = int(sys.argv[1])
    letters = string.ascii_lowercase[:file_count]
    for i, me in enumerate(letters):
        content = [
            f"from {other} import {other}_func" for other in letters[i + 1 :]
        ] + ["", f"def {me}_func():"]
        if letters[i + 1 :]:
            content.extend([f"    {other}_func()" for other in letters[i + 1 :]])
        else:
            content.append("    pass")
        with open(f"{me}.py", "w") as f:
            f.write("\n".join(content))


if __name__ == "__main__":
    main()
