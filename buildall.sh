#!/bin/sh -f

./xcbuild.pl -s pods

./xcbuild.pl -s alterBTSDK
./xcbuild.pl -s kairosBTSDK
./xcbuild.pl -s ethosBTSDK
./xcbuild.pl -s livotalBTSDK
./xcbuild.pl -s universalBTSDK
