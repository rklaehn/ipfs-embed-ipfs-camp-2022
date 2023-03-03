#!/bin/bash
pandoc \
    -f markdown \
    -t revealjs \
    -V theme=white -V transition=none -i --slide-level=2 \
    --standalone --embed-resources \
    -o target/bao.html \
    --verbose \
    bao.md
# pandoc \
#     -f markdown \
#     -t revealjs \
#     -V theme=beige -i --slide-level=2 \
#     -o target/bao.html \
#     --verbose \
#     bao.md
# pandoc -f markdown -t beamer -i --slide-level 2 -o target/bao.pdf bao.md
