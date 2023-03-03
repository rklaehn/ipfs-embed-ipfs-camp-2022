#!/bin/bash
ext=svg
for num in {0..25}
do
   /Applications/draw.io.app/Contents/MacOS/draw.io --export ./blake-tree.drawio --format $ext --page-index $num --width 564 --height 464 && mv blake-tree.$ext img/blake-tree-$num.$ext
done