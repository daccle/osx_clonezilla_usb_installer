#!/bin/sh


# The MIT License (MIT)

# Copyright (c) 2015 Daniel Clerc <mail@clerc.eu>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

### TO UPDATE TO CLONEZILLA VERSIONS BEIGN USED CHANGE THE FOLLOWING LINES

i686_file="clonezilla-live-2.3.2-22-i686-pae.iso"
i686_md5="6a0951f5d1c4a7d1f7ff1dde95f31e18"

i586_file="clonezilla-live-2.3.2-22-i586.iso"
i586_md5="444e4aed940bdc43073024ced2bf4035"

amd64_file="clonezilla-live-2.3.2-22-amd64.iso"
amd64_md5="c18e3a27725a7b22b82e022eef44b688"

sourceforge_url="http://downloads.sourceforge.net/project/clonezilla/clonezilla_live_stable/2.3.2-22/"

### NO CHANGES NEEDED BELOW THESE LINES


# Check for needed software. All these are default to OSX Yosemite

if ! [ -x /usr/bin/curl ]
    then
        echo "ABORT! - curl is missing!"
        exit 1
fi

if ! [ -x /usr/sbin/diskutil ]
    then
        echo "ABORT! - diskutil is missing!"
        exit 1
fi

if ! [ -x /usr/bin/hdiutil ]
    then
        echo "ABORT! - hdiutil is missing!"
        exit 1
fi

echo "Here is a list of all disk devices:"
/usr/sbin/diskutil list
echo ""
echo "To which device you would like to write clonezilla?"
read -p "(Please only enter the number like 2 for /dev/disk2) " -r
if [[ ! $REPLY =~ ^[0-9]$ ]]
    then
        echo "You haven't entered a number."
        echo "Aborted due user request."
        exit 1
    else
        if [[ ! $REPLY -ge 2 ]]
            then
                echo "The number is lower than 2. Since /dev/disk0 and /dev/disk1 are very often system drives"
                echo "we can't accept this as input. We don't want you to destroy your system. ;-)"
                exit 1
            else
                usb_device="/dev/disk${REPLY}"
                target_device="/dev/rdisk${REPLY}"
        fi
fi


echo "Which version of Clonezilla would you like to write to ${usb_device}"
echo ""
echo "1 = i586"
echo "2 = i686-pae"
echo "3 = amd64"
echo ""
read -p "Please enter choice: (1/2/3) any other choice quits: " -r
if [[ ! $REPLY =~ ^[1-3]$ ]]
    then
        echo "You haven't entered a valid number."
        echo "Aborted due user request."
        exit 1
    else

        case $REPLY in
        1 )
            clonezilla_file=${i586_file}
            clonezilla_md5=${i586_md5}
            ;;
        2 )
            clonezilla_file=${i686_file}
            clonezilla_md5=${i686_md5}
            ;;
        3 )
            clonezilla_file=${amd64_file}
            clonezilla_md5=${amd64_md5}
            ;;
        esac
fi

# Download ISO image:
/usr/bin/curl -o ${clonezilla_file} -L ${sourceforge_url}${clonezilla_file}

# Get md5 sum of downloaded file
download_md5=`md5 -q ${clonezilla_file}`

#Check md5 sum
if [ ${download_md5} != ${clonezilla_md5} ]
    then
        echo "md5 sums mismatch, the downloaded file might be bogus"
        exit 1
    else
        echo "Checksums OK"
        echo "Convert image to proper format"
        /usr/bin/hdiutil convert -format UDRW -o ${clonezilla_file} ${clonezilla_file}
        /usr/sbin/diskutil unmountDisk ${usb_device}
        read -p "Are sure to WRITE on ${usb_device}? All data will be lost! (y/n)" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]
            then
                echo "aborted due user request"
                exit 1
            else
                echo "Write image to ${usb_device}"
                sudo dd if=${clonezilla_file}.dmg of=${target_device} bs=1m
                echo "Eject ${usb_device}"
                /usr/sbin/diskutil eject ${usb_device}
                rm ${clonezilla_file}.dmg
                rm ${clonezilla_file}
        fi
fi
