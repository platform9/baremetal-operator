BUILD_NUMBER ?= 0
BMO_VERSION ?= 0.5.1
IMG_TAG = v$(BMO_VERSION)-$(BUILD_NUMBER)
IMG_REGISTRY ?= artifactory.platform9.horse/docker-local
IMG_REPO = bmo-bulk-add

.PHONY: default
default: push-image

.PHONY: image
image:
	docker build . -t ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}

.PHONY: push-image
push-image: image
	docker push ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}
	docker rmi ${IMG_REGISTRY}/${IMG_REPO}:${IMG_TAG}
