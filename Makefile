IMAGE_VERSION=19.03.x
IMAGE_NAME=corvexconnected/jenkins-agent-dind
IMAGE_TAGNAME=$(IMAGE_NAME):$(IMAGE_VERSION)
DOCKER_REGISTRY=registry.gitlab.com

default: build

build:
	docker buildx build --load -t $(IMAGE_TAGNAME) -f Dockerfile .

push:
	docker tag $(IMAGE_TAGNAME) $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)
	docker tag $(IMAGE_TAGNAME) $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest

