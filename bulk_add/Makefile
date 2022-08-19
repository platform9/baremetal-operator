BUILD_NUMBER ?= 0
METAL3_VERSION ?= 1.1.1
IMG_TAG ?= v$(METAL3_VERSION)-$(BUILD_NUMBER)
IMG_REGISTRY ?= artifactory.platform9.horse/docker-local
IMG_REPO = bmh-bulk-add

.PHONY: default
default: push-image

.PHONY: image
image:
	docker build --no-cache . -t ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}

.PHONY: push-image
push-image: image
	docker push ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}
	docker rmi ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}
