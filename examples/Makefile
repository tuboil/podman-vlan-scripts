# Makefile to package the examples directory
NAME := podman-vlan-examples
VERSION := $(shell git describe --tags --abbrev=0 2>/dev/null || echo v1.0.0)
ARCHIVE := ../$(NAME)-$(VERSION)
INSTALL_DIR ?= /usr/local/share/$(NAME)

.PHONY: all tar zip install clean

all: tar zip

# Create a tar.gz archive of the examples directory (output one level up)
tar:
	@echo "Creating $@: $(ARCHIVE).tar.gz"
	tar czf $(ARCHIVE).tar.gz --owner=0 --group=0 -C . .

# Create a zip archive of the examples directory (output one level up)
zip:
	@echo "Creating $@: $(ARCHIVE).zip"
	@which zip >/dev/null 2>&1 || (echo "zip not found, install it to create zip archives" && exit 1)
	zip -r $(ARCHIVE).zip . -x "*.pyc" "*.swp"

# Install the tarball into a system location (requires sudo)
install: tar
	@echo "Installing examples to $(INSTALL_DIR)"
	sudo mkdir -p $(INSTALL_DIR)
	sudo tar xzf $(ARCHIVE).tar.gz -C $(INSTALL_DIR)

clean:
	@echo "Cleaning generated archives"
	rm -f $(ARCHIVE).tar.gz $(ARCHIVE).zip || true

print:
	@echo "NAME=$(NAME)"
	@echo "VERSION=$(VERSION)"
	@echo "ARCHIVE=$(ARCHIVE)"

# End of Makefile
