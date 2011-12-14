#!/usr/bin/env bash

cp .gitconfig .gitconfig.backup
sed 's/--hidden--/08d16bdfc1221e87df40dd20b8ff41f9/' .gitconfig-hidden-token > .gitconfig

