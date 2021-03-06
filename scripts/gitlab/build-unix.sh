#!/bin/bash

set -e # fail on any error
set -u # treat unset variables as error

echo "__________Show ENVIROMENT__________"
echo "CI_SERVER_NAME:   " $CI_SERVER_NAME
echo "CARGO_HOME:       " $CARGO_HOME
echo "CARGO_TARGET:     " $CARGO_TARGET
echo "CC:               " $CC
echo "CXX:              " $CXX

echo "_____ Building target: "$CARGO_TARGET" _____"
if [ "${CARGO_TARGET}" = "armv7-linux-androideabi" ]
then
# only thing we need for android
  time cargo build --target $CARGO_TARGET --release -p parity-clib --features final
else
  time cargo build --target $CARGO_TARGET --release --features final
  time cargo build --target $CARGO_TARGET --release -p evmbin
  time cargo build --target $CARGO_TARGET --release -p ethstore-cli
  time cargo build --target $CARGO_TARGET --release -p ethkey-cli
  time cargo build --target $CARGO_TARGET --release -p whisper-cli
fi

echo "_____ Post-processing binaries _____"
rm -rf artifacts
mkdir -p artifacts
cd artifacts
mkdir -p $CARGO_TARGET
cd $CARGO_TARGET
if [ "${CARGO_TARGET}" = "armv7-linux-androideabi" ]
then
# only thing we need for android
 cp -v ../../target/$CARGO_TARGET/release/libparity.so ./libparity.so
else
 cp -v ../../target/$CARGO_TARGET/release/parity ./parity
 cp -v ../../target/$CARGO_TARGET/release/parity-evm ./parity-evm
 cp -v ../../target/$CARGO_TARGET/release/ethstore ./ethstore
 cp -v ../../target/$CARGO_TARGET/release/ethkey ./ethkey
 cp -v ../../target/$CARGO_TARGET/release/whisper ./whisper
fi


# stripping can also be done on release build time
# export RUSTFLAGS="${RUSTFLAGS} -C link-arg=-s"
if [ "${CARGO_TARGET}" = "armv7-linux-androideabi" ]
then
  arm-linux-androideabi-strip -v ./*
else
  strip -v ./*
fi

echo "_____ Calculating checksums _____"
for binary in $(ls)
do
  rhash --sha256 $binary -o $binary.sha256
  if [ "${CARGO_TARGET}" = "armv7-linux-androideabi" ]
  then
    echo "> ${binary} cannot be hashed with cross-compiled binary"
  else
    ./parity tools hash $binary > $binary.sha3
  fi
done

