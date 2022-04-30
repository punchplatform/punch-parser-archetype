#!/bin/bash
# @author: Punch Team
# @desc: Installer script for the PunchPlatform Standalone.

rc=0

for file in $(find . -path "*/test/*.json" -o -path "*/test/*.txt");
do
	cmd="docker run -v $PWD:/test ghcr.io/punchplatform/puncher:8.0-dev -T /test/$file"
	echo "[INFO] Running $cmd"
  if $cmd; then
		echo [INFO] TEST $file PASSED ;
	else
		echo [ERROR] >&2 ;
		echo [ERROR] TEST $file FAILED  >&2 ;
		echo [ERROR] to repeat the test type in: >&2 ;
		echo [ERROR]  $cmd >&2 ;
		echo [ERROR] >&2 ;
		rc=1
	fi
done
exit $rc