#!/bin/bash

export BASEIMAGE=${REGISTRY}/nginx-fips:${TAG}
docker run -e OPENSSL_FIPS=1 ${BASEIMAGE} openssl md5 /dev/null
status=$?
if test $status -eq 0
then
    echo "fips test failed"
    exit 1
else
	echo "fips test pass"
fi
