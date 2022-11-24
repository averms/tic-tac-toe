#!/usr/bin/env python3
#
# A very simple (probably incomplete) implementation of the .eqv substitution directive
# in MARS. It is not described in the textbook and it's not implemented in SPIM.

import re
import sys

macro_definition = re.compile(r"\s*[.]eqv")
replacements: dict[str, str] = {}


def add_to_replacements(line: str, startpos: int) -> None:
    tokens = line[startpos:].split()
    if len(tokens) != 2:
        sys.stderr.write("Macro definition '{}' ill-formed\n".format(line.strip("\r\n")))
        return
    replacements[r"\b" + re.escape(tokens[0]) + r"\b"] = tokens[1].replace("\\", "\\\\")


def replaced(s: str) -> str:
    for k, v in replacements.items():
        s = re.sub(k, v, s)
    return s


if sys.stdin.isatty():
    sys.exit("Give me some input from a file, please.")

for line in sys.stdin:
    define_match = macro_definition.match(line)
    if define_match:
        add_to_replacements(line, define_match.end())
    else:
        sys.stdout.write(replaced(line))
