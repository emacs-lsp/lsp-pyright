SHELL=/usr/bin/env bash

EMACS ?= emacs
EASK ?= eask

.PHONY: ci compile checkdoc lint test clean

ci: clean build compile checkdoc lint

build:
	$(EASK) package
	$(EASK) install

compile:
	@echo "Compiling..."
	$(EASK) compile

checkdoc:
	$(EASK) lint checkdoc

lint:
	@echo "package linting..."
	$(EASK) lint package

test:
	$(EASK) install-deps --dev
	$(EASK) ert ./test/*.el

clean:
	$(EASK) clean all
