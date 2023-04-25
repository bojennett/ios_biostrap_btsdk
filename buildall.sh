#!/bin/sh -f

./xcbuild.pl -s alterBTSDK
./xcbuild.pl -s kairosBTSDK
./xcbuild.pl -s ethosBTSDK
./xcbuild.pl -s livotalBTSDK
./xcbuild.pl -s universalBTSDK
./xcbuild.pl -s pods
