#!/bin/sh -f

./xcbuild.pl -s alterBTSDK -v 2.0.34
./xcbuild.pl -s kairosBTSDK -v 2.0.34
./xcbuild.pl -s ethosBTSDK -v 2.0.34
./xcbuild.pl -s livotalBTSDK -v 2.0.34
./xcbuild.pl -s universalBTSDK -v 2.0.34
./xcbuild.pl -s pods
