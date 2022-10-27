#!/bin/bash
# pandoc \
#     -f markdown \
#     -t revealjs \
#     -V theme=beige -i --slide-level=2 \
#     --standalone --embed-resources \
#     -o target/ipfs-embed.html \
#     --verbose \
#     raw.md
pandoc \
    -f markdown \
    -t revealjs \
    -V theme=beige -i --slide-level=2 \
    -o target/ipfs-embed.html \
    --verbose \
    raw.md
# pandoc -f markdown -t beamer -i --slide-level 2 -o target/ipfs-embed.pdf ipfs-embed.md
