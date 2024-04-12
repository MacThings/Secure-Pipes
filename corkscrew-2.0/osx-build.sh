#! /bin/sh

#  osx-build.sh
#  Secure Pipes
#
#  Created by Timothy Stonis on 11/12/14.
#  Copyright (c) 2014 Timothy Stonis. All rights reserved.

echo "Making: $1..." 

if [ $1 = clean ]; then
  echo "Cleaning old distribution..."
  make distclean
  exit 0
fi

echo "Running configure script..."
#./configure --host=i386-pc-mach3
./configure --build=aarch64 --host=aarch64 --enable-all

echo "Running make..."

if [ ! -e Makefile ]; then
  echo "Error: Configure failed to produce Makefile"
  exit 1
else 
  make
fi

