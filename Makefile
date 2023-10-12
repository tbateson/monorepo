ROOT_DIR:=$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BACKEND_DIR:=$(ROOT_DIR)/backend
FRONTEND_DIR:=$(ROOT_DIR)/frontend
GO_TOOLS:=$(BACKEND_DIR)/.go-tools
GO_WORKS:=$(filter-out .go-tools,$(notdir $(patsubst %/,%,$(dir $(sort $(wildcard $(BACKEND_DIR)/*/go.mod))))))
NODE_WORKS:=$(notdir $(patsubst %/,%,$(dir $(sort $(wildcard $(FRONTEND_DIR)/*/package.json)))))
GO_SOURCES:=$(wildcard $(foreach work,$(GO_WORKS),$(foreach wc,*.go */*.go */*/*.go,$(BACKEND_DIR)/$(work)/$(wc))))
NPM_CACHE:=$(FRONTEND_DIR)/.npm_cache

ifeq ($(OS),Windows_NT)
  EXE_EXT:=.exe
  NOOP:=echo "" > NUL
  RM:=del /s /q
  RMDIR:=rmdir /s /q
else
  NOOP:=:
  RM:=rm -rf
  RMDIR:=rm -rf
endif

all: update lint build

$(GO_TOOLS)/go-shadow$(EXE_EXT): $(GO_TOOLS)/go.mod $(GO_TOOLS)/go.sum
	cd "$(GO_TOOLS)" && go build -o=go-shadow$(EXE_EXT) -mod=vendor vendor/golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow/main.go

$(GO_TOOLS)/staticcheck$(EXE_EXT): $(GO_TOOLS)/go.mod $(GO_TOOLS)/go.sum
	cd "$(GO_TOOLS)" && go build -mod=vendor vendor/honnef.co/go/tools/cmd/staticcheck/staticcheck.go

$(BACKEND_DIR)/%$(EXE_EXT): $(wildcard $(foreach wc,go.mod go.sum *.go */*.go */*/*.go,$(dir $@)$(wc)))
	cd "$(dir $@)" && go build -o=$@ -mod=vendor

$(NPM_CACHE): $(NPM_CACHE).tar.xz
	@cd "$(NPM_CACHE)/.." && tar -xJf "$(NPM_CACHE).tar.xz"

build: go-build node-build

clean: go-clean go-tools-clean node-clean node-cache-clean

go-build: $(foreach work,$(GO_WORKS),$(BACKEND_DIR)/$(work)/$(work)$(EXE_EXT))

go-tools-clean:
	-@cd "$(GO_TOOLS)" && $(RM) go-shadow$(EXE_EXT) && $(RM) staticcheck$(EXE_EXT)

go-clean:
	-@$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && $(RM) $(work)$(EXE_EXT) &&) $(NOOP)

go-fmt: $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS),$(if $(shell cd "$(BACKEND_DIR)/$(work)" && go fmt -mod=vendor),exit 1,$(NOOP)) &&) $(NOOP)

go-lint: go-fmt go-shadow go-vet staticcheck

go-shadow: $(GO_TOOLS)/go-shadow$(EXE_EXT) $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && $(GO_TOOLS)/go-shadow$(EXE_EXT) . &&) $(NOOP)

go-test:
	@$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && go test -mod=vendor &&) $(NOOP)

go-tools-update:
	cd "$(GO_TOOLS)" && go get -u && go mod tidy

go-update:
	$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && go get -u && go mod tidy &&) $(NOOP)

go-vet: $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && go vet -mod=vendor &&) $(NOOP)

lint: go-lint

node-build: $(NPM_CACHE) $(NODE_SOURCES)
	$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && npm install && npm run build &&) $(NOOP)

node-clean:
	-@$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && $(RMDIR) node_modules && $(RMDIR) .svelte-kit &&) $(NOOP)

node-cache-clean:
	-@$(RMDIR) "$(NPM_CACHE)"

node-cache-update: node-cache-clean
	$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && npm ci &&) $(RMDIR) "$(NPM_CACHE)/_logs" && cd "$(NPM_CACHE)/.." && tar -cJf "$(NPM_CACHE).tar.xz" .npm_cache

node-lint: $(NPM_CACHE) $(NODE_SOURCES)
	@$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && npm run --silent lint &&) $(NOOP)

node-test: $(NPM_CACHE) $(NODE_SOURCES)
	@$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && npm run test:unit &&) $(NOOP)

node-update:
	$(foreach work,$(NODE_WORKS),cd "$(FRONTEND_DIR)/$(work)" && npm update &&) $(NOOP)

staticcheck: $(GO_TOOLS)/staticcheck$(EXE_EXT) $(GO_SOURCES)
	@$(foreach work,$(GO_WORKS),cd "$(BACKEND_DIR)/$(work)" && $(GO_TOOLS)/staticcheck$(EXE_EXT) . &&) $(NOOP)

test: go-test node-test

update: go-update go-tools-update node-update node-cache-update

.PHONY: all build clean go-build go-clean go-fmt go-lint go-shadow go-test go-tools-clean go-tools-update go-update go-vet lint node-build node-clean node-cache-clean node-cache-update node-lint node-test node-update staticcheck test update
