#!/bin/bash
num=0
ext=svg
while [ $num -le 22 ]
do
   /Applications/draw.io.app/Contents/MacOS/draw.io --export ./blake-tree.drawio --format $ext --page-index $num --width 564 --height 464 && cp blake-tree.$ext blake-tree-$num.$ext
   num=$((num+1))
done