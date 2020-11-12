#!/bin/sh

echo "Start to run build_python_lambdas.sh file"
set -e

DIR_BASE=$(pwd)
DIR_SRC="python_lambda_functions"
DIR_BUILD="./build"
DIR_DIST="`pwd`/dist"

mkdir -p "${DIR_BUILD}"
mkdir -p "${DIR_DIST}"

for LAMBDA in $(find $DIR_SRC/*/* -name '__init__.py' | cut -d/ -f2); do
  echo "Lambda: ${LAMBDA}"
  ZIP_FILE="${LAMBDA//_/-}.zip"
  mkdir -p "${DIR_BUILD}/${LAMBDA}"

  # Clear previous "build" files
  rm -fr "${DIR_BUILD}/${LAMBDA}" "${DIR_DIST}/${ZIP_FILE}"

  # Do the "build"
  cp -r "${DIR_SRC}/${LAMBDA}/" "${DIR_BUILD}/${LAMBDA}/"
  pip3 install --no-cache-dir -r requirements.freeze.txt -t "${DIR_BUILD}/${LAMBDA}/"

  # Shrink the zip
  find "${DIR_BUILD}/${LAMBDA}" -name '*.pyc' -delete
  find "${DIR_BUILD}/${LAMBDA}" -name '__pycache__' -delete
  find "${DIR_BUILD}/${LAMBDA}" -name '.pytest_cache' -delete

  cd "${DIR_BUILD}/${LAMBDA}"
  zip -r9 "${DIR_DIST}/${ZIP_FILE}" ./*
  cd "${DIR_BASE}"
done
