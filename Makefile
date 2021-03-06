REPOSITORY := gravitational.io
NAME := storage-app
VERSION ?= $(shell git describe --tags)
OUT_DIR ?= $(shell pwd)/build
OUT ?= $(OUT_DIR)/$(NAME)-$(VERSION).tar.gz
GRAVITY ?= gravity
export

OPENEBS_VERSION := 1.7.0
OPENEBS_NDM_VERSION := v0.4.7
DEBIAN_VERSION := buster

GRAVITY_EXTRA_FLAGS ?=
GRAVITY_IMAGE_FLAGS := --set-image=quay.io/openebs/m-apiserver:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/openebs-k8s-provisioner:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/snapshot-controller:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/snapshot-provisioner:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/admission-server:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/provisioner-localpv:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/jiva:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/cstor-istgt:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/cstor-pool:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/cstor-pool-mgmt:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/cstor-volume-mgmt:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/m-exporter:$(OPENEBS_VERSION) \
	--set-image=quay.io/openebs/node-disk-manager-amd64:$(OPENEBS_NDM_VERSION) \
	--set-image=quay.io/openebs/node-disk-operator-amd64:$(OPENEBS_NDM_VERSION) \
	--set-image=quay.io/openebs/linux-utils:$(OPENEBS_VERSION) \
	--set-image=quay.io/gravitational/debian-tall:$(DEBIAN_VERSION) \
	--set-image=gravitational/storage-app-hook:$(VERSION)

.PHONY: tarball
tarball: check-vars import
	$(GRAVITY) package export \
		$(GRAVITY_EXTRA_FLAGS) \
		$(REPOSITORY)/$(NAME):$(VERSION) $(OUT)

.PHONY: import
import: $(shell mkdir -p $(OUT_DIR)) check-vars hook
	-$(GRAVITY) app delete --force --insecure  \
		$(GRAVITY_EXTRA_FLAGS) \
		$(REPOSITORY)/$(NAME):$(VERSION)
	$(GRAVITY) app import --vendor --version=$(VERSION) \
		$(GRAVITY_IMAGE_FLAGS) $(GRAVITY_EXTRA_FLAGS) \
		--include=resources --include=registry .

.PHONY: hook
hook: check-vars
	$(MAKE) -C images hook

.PHONY: version
version:
	@echo $(VERSION)

.PHONY: check-vars
check-vars:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is not set"; exit 1; \
	fi;

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)
