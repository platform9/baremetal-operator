METAL3_VERSION ?= 0.5.1
IMG_TAG = v$(METAL3_VERSION)
IMG_REPO ?= platform9/bmh-bulk-add

.PHONY: default
default: push-image

.PHONY: image
image:
	docker build . -t ${IMG_REPO}:${IMG_TAG}

.PHONY: push-image
push-image: image
	docker push ${IMG_REPO}:${IMG_TAG}
	docker rmi ${IMG_REPO}:${IMG_TAG}
