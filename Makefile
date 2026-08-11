SHELL := /bin/bash

.PHONY: check build verify clean

check:
	scripts/check.sh

build: check
	@if [ "$$(id -u)" -eq 0 ]; then scripts/build.sh; else pkexec scripts/build.sh; fi

verify:
	scripts/verify-iso.sh

clean:
	rm -rf out
