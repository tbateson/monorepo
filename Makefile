ROOT_DIR:=$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BACKEND_DIR:=$(ROOT_DIR)/backend
FRONTEND_DIR:=$(ROOT_DIR)/frontend
GO_TOOLS_DIR:=$(BACKEND_DIR)/.go-tools
GO_WORKS:=$(filter-out .go-tools,$(notdir $(patsubst %/,%,$(dir $(wildcard $(BACKEND_DIR)/*/go.mod)))))
GO_WORKS_DIRS:=$(addprefix $(BACKEND_DIR)/,$(GO_WORKS))
GO_TEST_PATTERNS:=*_test.go */*_test.go */*/*_test.go
GO_TEST_SOURCES:=$(wildcard $(addprefix $(addsuffix $(GO_WORKS_DIRS),/),$(GO_TEST_PATTERNS)))
GO_SOURCES_PATTERNS:=*.go */*.go */*/*.go
GO_SOURCES:=$(filter-out $(GO_TEST_SOURCES),$(wildcard $(addprefix $(addsuffix $(GO_WORKS_DIRS),/),$(GO_SOURCES_PATTERNS))))
NODE_WORKS:=$(notdir $(patsubst %/,%,$(dir $(sort $(wildcard $(FRONTEND_DIR)/*/package.json)))))
NODE_WORKS_DIRS:=$(addprefix $(FRONTEND_DIR)/,$(NODE_WORKS))
NPM_CACHE:=$(FRONTEND_DIR)/.npm_cache

ifeq ($(OS),Windows_NT)
  EXE_EXT:=.exe
  NOOP:=echo "" > NUL
  NULL:=NUL
  RM:=del /s /q
  RMDIR:=rmdir /s /q
else
  NOOP:=:
  NULL:=/dev/null
  RM:=rm -rf
  RMDIR:=rm -rf
endif

all: update lint build

GO_SHADOW_EXE:=$(GO_TOOLS_DIR)/go-shadow$(EXE_EXT)
$(GO_SHADOW_EXE): $(GO_TOOLS_DIR)/go.mod $(GO_TOOLS_DIR)/go.sum
	cd "$(GO_TOOLS_DIR)" && go build -o=go-shadow$(EXE_EXT) -mod=vendor vendor/golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow/main.go

STATICCHECK_EXE:=$(GO_TOOLS_DIR)/staticcheck$(EXE_EXT)
$(STATICCHECK_EXE): $(GO_TOOLS_DIR)/go.mod $(GO_TOOLS_DIR)/go.sum
	cd "$(GO_TOOLS_DIR)" && go build -mod=vendor vendor/honnef.co/go/tools/cmd/staticcheck/staticcheck.go

$(BACKEND_DIR)/%$(EXE_EXT): $(filter-out $(wildcard $(addprefix $(@D),$(GO_TEST_PATTERNS))),$(wildcard $(addprefix $(@D),go.mod go.sum $(GO_SOURCES_PATTERNS))))
	cd "$(@D)" && go build -o=$@ -mod=vendor

$(NPM_CACHE): $(NPM_CACHE).tar.xz
	@cd "$(abspath $(NPM_CACHE)/..)" && tar -xJf "$(NPM_CACHE).tar.xz"

build: go-build node-build

clean: go-clean go-tools-clean node-clean node-cache-clean

go-build: $(foreach work,$(GO_WORKS_DIRS),$(work)/$(notdir $(work))$(EXE_EXT))

go-tools-clean:
	-@cd "$(GO_TOOLS_DIR)" && $(if $(realpath $(GO_SHADOW_EXE)),$(RM) $(notdir $(GO_SHADOW_EXE)) > $(NULL) &&,) $(if $(realpath $(STATICCHECK_EXE)),$(RM) $(notdir $(STATICCHECK_EXE)) > $(NULL),$(NOOP))

go-clean:
	-@$(foreach work,$(GO_WORKS_DIRS),$(if $(realpath $(work)/$(notdir $(work))$(EXE_EXT)),cd "$(work)" && $(RM) $(notdir $(work))$(EXE_EXT) > $(NULL) &&,)) $(NOOP)

go-fmt: $(GO_SOURCES) $(GO_TEST_SOURCES)
	@$(foreach work,$(GO_WORKS_DIRS),$(if $(shell cd "$(work)" && go fmt -mod=vendor),exit 1,$(NOOP)) &&) $(NOOP)

go-lint: go-fmt go-shadow go-vet staticcheck

go-shadow: $(GO_SHADOW_EXE) $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS_DIRS),cd "$(work)" && $(GO_SHADOW_EXE) ./... &&) $(NOOP)

go-test: $(GO_SOURCES) $(GO_TEST_SOURCES)
	@$(foreach work,$(GO_WORKS_DIRS),cd "$(work)" && go test -mod=vendor &&) $(NOOP)

go-tools-update:
	cd "$(GO_TOOLS_DIR)" && go get -u && go mod tidy

go-update:
	$(foreach work,$(GO_WORKS_DIRS),cd "$(work)" && go get -u && go mod tidy &&) $(NOOP)

go-vet: $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS_DIRS),cd "$(work)" && go vet -mod=vendor &&) $(NOOP)

lint: go-lint node-lint

node-install: $(NPM_CACHE)
	@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm install --silent &&) $(NOOP)

node-build: node-install
	@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm run --silent build &&) $(NOOP)

node-clean:
	-@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && $(if $(realpath $(work)/node_modules),$(RMDIR) node_modules &&,) $(if $(realpath $(work)/.svelte-kit),$(RMDIR) .svelte-kit &&,)) $(NOOP)

node-cache-clean:
	-@$(if $(realpath $(NPM_CACHE)),$(RMDIR) "$(NPM_CACHE)",)

node-cache-update: node-cache-clean
	$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm ci &&) $(RMDIR) "$(NPM_CACHE)/_logs" && cd "$(abspath $(NPM_CACHE)/..)" && tar -cJf "$(NPM_CACHE).tar.xz" .npm_cache

node-fmt: node-install
	@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm run --silent format &&) $(NOOP)

node-lint: node-install node-fmt
	@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm run --silent lint &&) $(NOOP)

node-test: node-install
	@$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm run --silent test &&) $(NOOP)

node-update:
	$(foreach work,$(NODE_WORKS_DIRS),cd "$(work)" && npm update &&) $(NOOP)

staticcheck: $(STATICCHECK_EXE) $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS_DIRS),cd "$(work)" && $(STATICCHECK_EXE) ./... &&) $(NOOP)

test: go-test node-test

update: go-update go-tools-update node-update node-cache-update

.PHONY: all build clean go-build go-clean go-fmt go-lint go-shadow go-test go-tools-clean go-tools-update go-update go-vet lint node-build node-clean node-cache-clean node-cache-update node-fmt node-install node-lint node-test node-update staticcheck test update
