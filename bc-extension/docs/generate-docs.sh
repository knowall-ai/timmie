#!/bin/bash

# Generate the Thyme BC Extension Technical Solution Document PDF
# from the AsciiDoc sources in this directory.

set -e

echo "Thyme BC Extension - Technical Solution Document Generator"
echo "=========================================================="
echo ""

if ! command -v asciidoctor-pdf &> /dev/null; then
    echo "Error: asciidoctor-pdf is not installed."
    echo "Install with: sudo gem install asciidoctor-pdf"
    exit 1
fi

cd "$(dirname "$0")"

echo "Generating Technical Solution Document..."
asciidoctor-pdf \
    -a pdf-theme=knowall \
    -a pdf-themesdir=../themes \
    TECHNICAL_SOLUTION_DOCUMENT.adoc \
    -o TECHNICAL_SOLUTION_DOCUMENT.pdf

echo ""
echo "Generated: docs/TECHNICAL_SOLUTION_DOCUMENT.pdf"
