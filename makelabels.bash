#!/bin/bash

# Program to print pages of data matrix labels.  Each label has
# text with a code VTEC<num> and a corresponding data matrix version
# where <num> is a 9 digit sequence number.
#
# This approach is slow but easy to make from existing tools.  It's
# slow because of all the file operations rather than keeping the page
# image in memory.  In a real programming language, we could generate
# an entire page in memory.
#
# Modified to use 300 dpi so text isn't fuzzy.
# Modified to handle more than one page.  Usage:
#
# ./makelabels [-P <printer>] <start> [<stop>]
#
# where <printer> is the cups printer name and <start> and <stop> are
# the beginning and ending sequence numbers.  If a printer is not given,
# the labels are generated into PNG files:  page1.png, page2.png,...
# If stop is not given, then stop=start+25.
#
# 10/2015.

# Configuration parameters.  We could generate some of these, but for
# now, user has to edit this script to change them.

# resolution:  default is 72 dpi.  This variable is used as an argument
# to ImageMagick commands.

resolution="-density 300x300 -units PixelsPerInch"

# Describe the page in pixels.  The definition is based on the resolution.
# Margin is needed since printer doesn't seem to handle the margins well.

xMargin=10
yMargin=10
xPage=2550
yPage=3300

# Describe a cell (label plus data matrix).

xSize=293
ySize=100

# Offset from cell left to data matrix code left based on 0,0.

xOffset=190

# Number of pixels above and below and left and right of the dividers.

yBreak=2
xBreak=2

# Label font size and font.  On the Mac, font is just Arial.  Under Linux,
# the path is needed.  Label offset in cell is also given.
# font="/usr/share/fonts/truetype/msttcorefonts/Arial.ttf"
# OR font=Arial if using a Mac.

pointSize=5.5
font=Arial-Bold
xLabelOffset=5
yLabelOffset=68

# End of configuration.

# Compute images per row and rows per page.  yBreak gives the number
# of extra pixels above and below the dividing line.

imagesPerRow=$(( ($xPage - 2*$xMargin - 2*xBreak - 1)/$xSize ))
fullYSize=$(( $ySize + 2*$yBreak + 1))
rowsPerPage=$(( ($yPage - 2*$yMargin)/$fullYSize))

# Down and dirty argument processing.  More error checking would be nice.

args=("$@")
top=$(($# - 1))

start=0
stop=0
printer=""
page=1

if [ $# -lt 1 ] ; then
    echo "Usage:  ./makelabels [-P printer] <start> [<stop>]" 
    exit
fi 

j=0
until [ $j -gt $top ] ; do
    arg=${args[$j]}

    # Check for and save printer name in variable printer.

    if [ "$arg" == "-P" ] ; then
	next=$(($j + 1))
	if [ $next -le $top ] ; then
	    printer=${args[$j+1]}
	    j=$(($j+1))
        fi
    else

	# Get the first and last sequence number.

	if [ $start -eq 0 ] ; then
	    start=${args[$j]}
	else
	    stop=${args[$j]}
	fi
    fi
    j=$(($j + 1))
done

# Defaults for start and stop are 1 and 25.

if [ $start -eq 0 ] ; then
    start=1
fi
if [ $stop -eq 0 ] ; then
    stop=$(($start + 25))
fi

# Make the blank canvas

convert -size ${xPage}x$yPage $resolution canvas:none canvas.png

# Make the grid.

convert -size ${xPage}x$yPage $resolution canvas:none grid.png

echo "Making Grid"

# Make horizontal lines.

y=$(($yMargin + $ySize + $yBreak + 1))
lineEnd=$(( $xPage - 2*$xMargin))

for j in `seq 1 $rowsPerPage`
do
    convert -size ${xPage}x${yPage} xc:none $resolution -stroke "gray(50%)" -draw "line $xMargin, $y $lineEnd, $y" line.png
    composite line.png canvas.png tmp.png
    mv tmp.png canvas.png
    y=$(( $y + $fullYSize ))
done

# Make vertical lines.

x=$(($xMargin + $xSize + $xBreak + 1))
pageEnd=$(( $yPage - 2*$yMargin))

for j in `seq 1 $imagesPerRow`
do
    convert -size ${xPage}x${yPage} xc:none $resolution -stroke "gray(50%)" -draw "line $x, $yMargin $x, $pageEnd" line.png
    composite line.png canvas.png tmp.png
    mv tmp.png canvas.png
    x=$(( $x + $xSize + 2*xBreak + 1))
done

# Save the canvas with the grid in case we do more than one page.

cp canvas.png canvas.template.png

# Make a page of labels.  ID is VTEC<num> where <num> is a nine-digit integer.

id=$start

# Main loop.  Outer loop is for pages.  Next loop if for rows.  Last loop
# is for cells in a row.

done=0
for (( ; ; ))
do
    x=$(( $xMargin + $xOffset ))
    y=$(( $yMargin ))
    xLabel=$(( $xMargin + $xLabelOffset))
    yLabel=$(( $yMargin + $yLabelOffset))

    for j in `seq 1 $rowsPerPage`
    do

	# Each cell is made by compositing the canvas with the data matrix and
	# its label.

	echo "Making row $j"
	for i in `seq 1 $imagesPerRow`
	do

	    # When we've done the last number, it's time to stop.

	    if [ $id -gt $stop ] ; then
		done=1
	        break
	    fi

	    seq=`printf VTEC%09d $id`
	    echo $seq | dmtxwrite -d 5 -r 300 -o label.png
	    composite label.png -gravity northwest -geometry +$x+$y canvas.png tmp.png
	    mv tmp.png canvas.png
	    convert -pointsize $pointSize -font $font $resolution label:$seq tmp.png
	    composite tmp.png -gravity northwest -geometry +$xLabel+$yLabel canvas.png tmp2.png
	    mv tmp2.png canvas.png
	    id=$(($id + 1))
	    x=$(($x+$xSize+2*xBreak+1))
	    xLabel=$(($xLabel+$xSize + 2*$xBreak + 1))
	done

	# Finished a row.  Move to the next one.

	x=$(( $xMargin + $xOffset ))
	y=$(($y + $fullYSize))
	xLabel=$(( $xMargin + $xLabelOffset))
	yLabel=$(( $yMargin + $j * $fullYSize + $yLabelOffset))
	if [ $done -eq 1 ] ; then
	    break
	fi
    done

# Either print the page or name it page<x>.png.

    if [ "x$printer" == "x" ] ; then
	mv canvas.png page${page}.png
	page=$(($page + 1))
    else
	lpr -P $printer canvas.png
    fi

    cp -p canvas.template.png canvas.png

    if [ $done -eq 1 ] ; then
	rm -f canvas.png grid.png line.png tmp.png canvas.template.png label.png
	break
    fi
done
