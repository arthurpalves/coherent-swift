SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
srcdir = Sources
templatesdir = Templates

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
GITHUBCIBUILDDIR = $(REPODIR)/.githubci-build
SOURCES = $(wildcard $(srcdir)/**/*.swift)
TEMPLATES = $(wildcard $(templatesdir)/*)

.DEFAULT_GOAL = all

.PHONY: all
all: coherent-swift

coherent-swift: $(SOURCES)
	@swift build \
		-c release \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

.PHONY: install
install: coherent-swift
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/coherent-swift" "$(bindir)"
	@mkdir -p "$(libdir)/coherent-swift/templates/"
	@cp "$(TEMPLATES)" "$(libdir)/coherent-swift/templates/"

.PHONY: githubci-install
githubci-install:
	@install -d "$(bindir)" "$(libdir)"
	@install "$(GITHUBCIBUILDDIR)/release/coherent-swift" "$(bindir)"
	@mkdir -p "$(libdir)/coherent-swift/templates/"
	@cp "$(TEMPLATES)" "$(libdir)/coherent-swift/templates/"

.PHONY: prepare-githubci-build
prepare-githubci-build: coherent-swift
	@cp "$(BUILDDIR)/release/coherent-swift" "$(GITHUBCIBUILDDIR)/release/coherent-swift"

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/coherent-swift"
	@rm -rf "$(libdir)/coherent-swift"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)
