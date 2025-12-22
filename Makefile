.PHONY: bump help

help:
	@echo "Usage: make bump <version>"
	@echo "       make bump VERSION=<version>"
	@echo "Example: make bump 0.9.0"
	@echo ""
	@echo "This command updates the version number in the following files:"
	@echo "  - lib/ruwi/version.rb"
	@echo "  - package.json"
	@echo "  - packages/npm-packages/runtime/package.json"
	@echo "  - README.md"
	@echo "  - package-lock.json (via npm install)"
	@echo "  - packages/npm-packages/runtime/package-lock.json (via npm install)"

# Get version from position argument (if VERSION is not already set)
VERSION_ARG := $(word 2,$(MAKECMDGOALS))
ifndef VERSION
  ifneq ($(VERSION_ARG),)
    VERSION := $(VERSION_ARG)
  endif
endif

bump:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make bump 0.9.0"; \
		exit 1; \
	fi
	@echo "Bumping version to $(VERSION)..."
	@# Update lib/ruwi/version.rb
	@sed -i '' 's/VERSION = ".*"/VERSION = "$(VERSION)"/' lib/ruwi/version.rb
	@echo "✓ Updated lib/ruwi/version.rb"
	@# Update Gemfile.lock
	@bundle install
	@echo "✓ Updated Gemfile.lock"
	@# Update root package.json
	@sed -i '' 's/"version": ".*"/"version": "$(VERSION)"/' package.json
	@echo "✓ Updated package.json"
	@# Update packages/npm-packages/runtime/package.json
	@sed -i '' 's/"version": ".*"/"version": "$(VERSION)"/' packages/npm-packages/runtime/package.json
	@echo "✓ Updated packages/npm-packages/runtime/package.json"
	@# Update README.md (unpkg.com URL)
	@sed -i '' 's|unpkg.com/ruwi@[0-9.]*|unpkg.com/ruwi@$(VERSION)|' README.md
	@echo "✓ Updated README.md"
	@echo ""
	@echo "Updating package-lock.json files..."
	@npm install --package-lock-only
	@echo "✓ Updated root package-lock.json"
	@cd packages/npm-packages/runtime && npm install --package-lock-only && cd ../../..
	@echo "✓ Updated packages/npm-packages/runtime/package-lock.json"
	@echo ""
	@echo "Version bumped to $(VERSION) successfully!"

# Prevent make from treating the version argument as a target
%:
	@:
