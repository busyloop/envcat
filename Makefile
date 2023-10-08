export UNAME := $(shell uname -sm | sed 's/ /-/' | tr '[:upper:]' '[:lower:]')
export MAKE_UNAME := $(shell uname -sm | sed 's/ /_/' | tr '[:lower:]' '[:upper:]')
export VERSION := $(shell grep "^version" shard.yml | cut -d ' ' -f 2)

SRC_FILES = $(shell find src)
CRYSTAL ?= crystal
CRYSTAL_SPEC_ARGS = --fail-fast --order random

CRYSTAL_ARGS_LOCAL_DARWIN_X86_64   = --progress
CRYSTAL_ARGS_LOCAL_LINUX_X86_64    = --progress
CRYSTAL_ARGS_LOCAL_LINUX_AARCH64   = --progress
CRYSTAL_ARGS_RELEASE_DARWIN_X86_64 = --release --no-debug
CRYSTAL_ARGS_RELEASE_LINUX_X86_64  = --static --release --no-debug
CRYSTAL_ARGS_RELEASE_LINUX_AARCH64 = --static --release --no-debug

DOCKER_IMAGE = 84codes/crystal:1.6.2-alpine
ALPINE_VERSION = $(shell which apk)

EXE_SRC = src/envcat.cr
EXE_BASENAME = envcat-$(VERSION)

.PHONY: init release

lint_and_test: lint test

test:
	$(CRYSTAL) spec $(CRYSTAL_SPEC_ARGS)

lint:
	bin/ameba

clean:
	rm -f build/*

build: build/$(EXE_BASENAME).$(UNAME)

release: test
	$(MAKE) build/$(EXE_BASENAME).$(UNAME) BUILD_MODE=RELEASE
	# mkdir -p build && date >build/$(EXE_BASENAME).$(UNAME)
	rm -f build/*.dwarf

release_linux:
	$(MAKE) release UNAME=linux-x86_64

ci:
	shards install --without-development

init:
	@mkdir -p build

tag:
	git tag v$(VERSION)

version:
	@echo $(VERSION)

prepare_alpine:
ifeq ($(shell [[ ! -z "$(ALPINE_VERSION)" ]] && echo true),true)
	apk add yaml-static libxml2-static xz-static
endif

# Static linux release build inside alpine
build/$(EXE_BASENAME).linux-x86_64: $(SRC_FILES) | init prepare_alpine
ifeq ($(shell [[ -z "$(ALPINE_VERSION)" && "$(BUILD_MODE)" == "RELEASE" ]] && echo true),true)
	time docker run --rm -it -w /src -v `pwd`:/src --entrypoint make $(DOCKER_IMAGE) $@ BUILD_MODE=RELEASE
else
	$(CRYSTAL) build $(CRYSTAL_ARGS_$(or $(BUILD_MODE),LOCAL)_$(MAKE_UNAME)) -o $@ ${EXE_SRC}
	@ldd $@ 2>/dev/null && { echo "ERROR: Compiler did not produce a static executable - see http://bit.ly/3jnS5yV"; exit 1; } || true
endif

build/$(EXE_BASENAME).%: $(SRC_FILES) | init prepare_alpine
	time $(CRYSTAL) build $(CRYSTAL_ARGS_$(or $(BUILD_MODE),LOCAL)_$(MAKE_UNAME)) -o $@ ${EXE_SRC}

README.md: docs/templates/README.md.j2 build/$(EXE_BASENAME).$(UNAME)
	HELP_SCREEN=$$(build/$(EXE_BASENAME).$(UNAME) --help 2>&1 | tac | tail -n +3 | tac | tail -n +2 | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g') build/$(EXE_BASENAME).$(UNAME) -f j2 HELP_SCREEN VERSION <$^ >$@

README: README.md
readme: README.md
