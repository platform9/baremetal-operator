PF9_VERSION ?= 5.5.0
IMG_TAG = latest
IMG_REPO = platform9/shweta-bulk-add
.PHONY: build
build: generate manifests manager tools

.PHONY: docker
docker:  ## Build the docker image
	docker build . -t ${IMG_REPO}:${IMG_TAG}

.PHONY: docker-push
docker-push: docker
	docker push ${IMG_REPO}:${IMG_TAG}

.PHONY: release
release: docker-push
	docker rmi -f `docker images ${IMG_REPO}:${IMG_TAG} -q`
