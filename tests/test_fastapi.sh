#! /usr/bin/env bash

set -x
set -e

cd fastapi
git fetch --tags
latest_tag_commit=$(git rev-list --tags --max-count=1)
latest_tag=$(git describe --tags "${latest_tag_commit}")
git checkout "0.79.0"
pip install --force-reinstall --index-url "https://:2022-09-05T00:17:14.391Z@time-machines-pypi.sealsecurity.io/" setuptools wheel
pip install --index-url "https://:2022-09-05T00:17:14.391Z@time-machines-pypi.sealsecurity.io/" .[all,dev,doc,test]

./scripts/test.sh
