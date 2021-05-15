#!/usr/bin/env bash

SOURCE_FORMAT="markdown\
+pipe_tables\
+backtick_code_blocks\
+auto_identifiers\
+strikeout\
+yaml_metadata_block\
+implicit_figures\
+all_symbols_escapable\
+link_attributes\
+smart\
+fenced_divs"

pandoc  --dpi=300 \
        --slide-level 2 \
        --toc \
        --columns=50 \
        -f "$SOURCE_FORMAT" \
        --pdf-engine xelatex \
        -V classoption:aspectratio=169 \
        -H templates/my.sty \
        -t beamer \
        --filter pandoc-plantuml \
        -s -o k8s-workloads-2021.05.14.pdf k8s-workloads.md
