#!/bin/bash
# Parameters
# $1 = compiler command
# $2 = sketch path
# $3 = build path
# $4 = build project name
# $5 = flag name ('release_flags' or 'debug_flags')

# create previous option file if not already there
touch $3/options.$5

# make a backup copy if previous option file
cp $3/options.$5 $3/options.$5.bak

# create new option file
$1 -fpreprocessed -dD -E -x c++ $2/$4 | grep -E "^\s*#\s*pragma\s+arduino\s+$5" | sed -E 's/# *pragma +arduino +(debug|release)_flags//'g | tr '\n' ' ' >$3/options.$5

# compare old an new
if  [[ `diff -q $3/options.$5 $3/options.$5.bak` ]]; then
    echo "Options changed: Delete cache!"
    rm -rf $3/core/*.a
    rm -rf $3/core/*.o
    rm -rf $3/../../cores
    rm -rf $3/sketch/*.a
fi

#remove backup options
rm $3/options.$5.bak