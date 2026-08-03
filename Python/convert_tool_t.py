from pathlib import Path


SOURCE_FILE = "tool_.t"
TARGET_TEMPLATE = "tool.t"
OUTPUT_FILE = "tool_conv.t"


def parse_header(header):
    """
    Ermittelt Feldname, Startposition und Breite aus einer Fixed-Width-Headerzeile.
    """
    starts = []
    names = []

    inside = False
    for i, c in enumerate(header + " "):
        if not inside and c != " ":
            start = i
            inside = True

        elif inside and c == " ":
            names.append(header[start:i])
            starts.append(start)
            inside = False

    fields = []

    for i, name in enumerate(names):
        start = starts[i]

        if i + 1 < len(starts):
            width = starts[i + 1] - start
        else:
            width = len(header) - start

        fields.append(
            {
                "name": name,
                "start": start,
                "width": width,
            }
        )

    return fields


def extract(line, start, width):
    return line[start:start + width]


def main():

    src = Path(SOURCE_FILE).read_text(encoding="latin1").splitlines()
    dst = Path(TARGET_TEMPLATE).read_text(encoding="latin1").splitlines()

    src_fields = parse_header(src[1])
    dst_fields = parse_header(dst[1])

    src_lookup = {f["name"]: f for f in src_fields}

    missing = [f["name"] for f in dst_fields if f["name"] not in src_lookup]

    if missing:
        raise RuntimeError(
            "Folgende Felder fehlen in der Quelldatei:\n"
            + "\n".join(missing)
        )

    out = []

    out.append(dst[0])      # BEGIN...
    out.append(dst[1])      # Zielheader

    for line in src[2:]:

        if line.strip() == "[END]":
            break

        newline = [" "] * len(dst[1])

        for field in dst_fields:

            src_field = src_lookup[field["name"]]

            value = extract(
                line,
                src_field["start"],
                src_field["width"],
            )

            value = value[:field["width"]].ljust(field["width"])

            start = field["start"]

            newline[start:start + field["width"]] = value

        out.append("".join(newline))

    out.append("[END]")

    Path(OUTPUT_FILE).write_text(
        "\n".join(out),
        encoding="latin1"
    )

    print(f"{OUTPUT_FILE} wurde erfolgreich erstellt.")


if __name__ == "__main__":
    main()
