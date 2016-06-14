Makelabels Script to Generate Specimen Labels

June 14, 2016

Marek Lab, Department of Entomology, Virginia Tech

• INTRODUCTION

Makelabels is a bash script that creates and prints pages of specimen labels with customized data matrix barcodes and sequential reference numbers. Each label has a reference number consisting of "VTEC<num>", where <num> is a 9-digit number. The reference number is printed in text and encoded in the data matrix code printed on the label. Dividing lines are printed to aid in cutting the labels. All commands are run in a terminal window.


• REQUIREMENTS

This script requires the following open source packages or their most recent versions:

Note: the README was written for a Raspberry Pi running Rasbian. The time to run will depend on machine speed as well (i.e., approximately 10 minutes on a Raspberry Pi). However, now that the steps to use dmtxwrite and the commands in ImageMagick are known, a user could write a program to create a page of labels in memory without using intermediate files in each run.

ImageMagick (http://www.imagemagick.org/script/binary-releases.php)
libdmtx (http://libdmtx.sourceforge.net/)
 
In the terminal:
%> sudo apt-get install imagemagick
%> sudo apt-get install libsdmtx-utils

Note: If you get, %> unable to fetch some archives
Then run: %> run apt-get update 
Or: %> run apt-get update --fix-missing
Then redo:
%> sudo apt-get install imagemagick
%> sudo apt-get install libdmtx-utils 

Arial fonts must also be installed in Linux:
%> sudo apt-get install ttf-mscorefonts-installer
%> sudo fc-cache

Check for proper installation using:
%> fc-match Arial
You should receive the message: %> ARIAL.TTF: "ARIAL" "NORMAL"


• INSTALLATION

The makelabels script can be installed anywhere in the file system. The following assumes that the script will be installed in your current directory:

%> curl "https://github.com/apheloria/makelabels/blob/master/makelabels.bash" >> makelabels.bash

Note: The sudo command is used to allow the user to write to directories owned by the system. If the user installing the script does not have permissions to use the sudo command, the script can be installed in any directory in the user's path. The makelabels script is also available for download at http://web2.ento.vt.edu/labels/ Clicking on the link will download the script into the browser's default downloads directory, typically ~/Downloads

If the script is downloaded, then following suggested sequence of commands can be used:

%> cd
%> mkdir Labels

Drag makelabels.bash into the Labels folder in a GUI.

%> cd Labels

If not using a GUI, to drag makelabels.bash into the Labels folder, use this command to place makelabels.bash in Labels:
%> mv ~/Downloads/makelabels.bash

After makelabels.bash is placed in Labels, continue with:

%> chmod +x makelabels.bash
%> ./makelabels.bash

Note: On a Raspberry PI, if no printer is installed then you can make a PNG file and email it to yourself or put it on a USB drive to transfer to a computer with a printer.

When initiated, makelabels.bash will display the following: 
makelabels.bash [-P <printer>] <start> [<stop>]

where <printer> is the CUPS printer name and <start> and <stop> are the beginning and ending reference numbers to be printed (not including the "VTEC" prefix). Items in square brackets are optional. If a printer is not specified, labels are generated into PNG files: page1.png, page2.png, pagex.png. If no <stop> number is provided, the script will terminate after generating a total of 26 labels (start number plus 25 additional labels).


• Examples: 

To print 26 labels to "myprinter" starting with VTEC000000001, execute the script as follows:

%> ./makelabels.bash -P myprinter 1

The following example creates 26 labels beginning with VTEC000000100 and ending with VTEC000000125. The labels are in file page1.png.

%> ./makelabels.bash 100

To create labels VTEC000000100 through VTEC000000250, execute the following command. The labels will be generated in files page1.png, page2.png...

%> ./makelabels.bash 100 250

To create 26 labels beginning with VTEC000000100 and ending with VTEC000000126 and to print these to the default printer, execute:

%> ./makelabels.bash 100 
%> lpr page1.png

Note: the PNG files will be saved in the the Labels folder.

Note: running the script is slow on a Raspberry Pi and one sheet requires ~ 10 minutes


• CONFIGURATION

Currently the user must edit the script itself to change any configuration parameters.

The default resolution is 300 dpi. The "resolution" variable is used as an argument to ImageMagick commands and can be used to change the printer resolution.  

resolution="-density 300x300 -units PixelsPerInch"

The page is described in pixels based on the resolution. The margin offsets can be used if the printer does not allow borderless printing. The margins and page size in dots/inch are specified with these variables. At 300 dpi, the page size given is for 8.5 x 11".

xMargin=10
yMargin=10
xPage=2550
yPage=3300

A cell consists of the reference number (VTEC<num>) in text plus the data matrix code. Changing the length of the reference number (default is VTEC+9 characters) will alter the size of the cell and require other label parameters to be adjusted accordingly. These cell parameters can be used to make adjustments for different size reference numbers and to change the location of the text label and data matrix in the cell.

xSize=293
ySize=100

This variable is the offset from left edge of the cell to the left edge of the data matrix code based on 0,0 starting point:

xOffset=190

These variables give the number of pixels above and below and left and right of the dividers:

yBreak=2
xBreak=2

Label font size and font: 
On the Mac, font=Arial. Under Linux, the path is needed (font="/usr/share/fonts/truetype/msttcorefonts/Arial.ttf"). Label offset in the cell is also given. Changing the font and font size may alter the size of the cell and require other label parameters to be adjusted accordingly.

pointSize=5.5
font=Arial-Bold
xLabelOffset=5
yLabelOffset=68

The reference number (VTEC<num>) can be modified as needed by changing the "seq" variable:

seq=`printf VTEC%09d $id`

The location of the reference number and the datamatrix code on the label can be modified using ImageMagick commands.

  composite label.png -gravity northwest -geometry +$x+$y canvas.png tmp.png
  mv tmp.png canvas.png
  convert -pointsize $pointSize -font $font $resolution label:$seq tmp.png
  composite tmp.png -gravity northwest -geometry +$xLabel+$yLabel


• NOTES

This approach is slow but easy to develop using existing tools. It is slow because files are passed between individual steps rather than keeping the page image in memory. Now that the steps to use dmtxwrite and the commands in ImageMagick are known, a user could write a
program to create a page of labels in memory without using intermediate files in each run.
