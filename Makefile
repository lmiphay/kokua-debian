KD_DEBIAN_VERSION ?= stretch
KD_KOKUA_IMAGE ?= kokua/debian:$(KD_DEBIAN_VERSION)
KD_KOKUA_CONTAINER ?= kokua-debian-$(KD_DEBIAN_VERSION)
KD_HOST_REPOS_DIR ?= /local/src/kokua

KD_CONTAINER_REPOS_DIR ?= /local/src/kokua
KD_CONTAINER_USER_GROUP ?= $(shell id -un):$(shell id -gn)

KD_AUTOBUILD_BUILD_ID ?= $(shell hostname)-$(shell date +'%F-%T')

KD_BASE_URL ?= https://bitbucket.org/kokua
KD_REPOS ?= viewer-build-variables kokua

EXEC_CMD = \
	docker exec \
		--user $(KD_CONTAINER_USER_GROUP) \
		$(KD_KOKUA_CONTAINER)

BUILD_CMD = \
	docker exec \
		--workdir $(KD_CONTAINER_REPOS_DIR)/kokua \
		--env AUTOBUILD_VARIABLES_FILE=$(KD_CONTAINER_REPOS_DIR)/viewer-build-variables/variables \
		--env AUTOBUILD_VARIABLES_ID=$(KD_AUTOBUILD_BUILD_ID) \
		--env PATH=/usr/local/bin:/usr/bin:/bin \
		--user $(KD_CONTAINER_USER_GROUP) \
		$(KD_KOKUA_CONTAINER)

nocmd: help

all: settings image container start

.PHONY: nocmd all settings pullimage image container build start copy-user clone pull configure compile run clean help

.EXPORT_ALL_VARIABLES:

settings:
	@env | egrep 'KD_' | sort | awk -F'=' '{print $$1 "=" "\"" $$2 "\""}'
	@echo -ne "\nexport "; env | egrep 'KD_' | sort | awk -F'=' '{printf $$1 " "}'; echo ""

pullimage:
	docker pull debian:$(KD_DEBIAN_VERSION)

image:
	docker build --progress=plain --tag $(KD_KOKUA_IMAGE) .
	@docker images | grep kokua/debian

container:
	if [ ! -d "$(KD_HOST_REPOS_DIR)" ] ; then  mkdir -p $(KD_HOST_REPOS_DIR) ; fi
	docker create \
		--tmpfs /tmp --tmpfs /run \
		--name $(KD_KOKUA_CONTAINER) \
		--volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
		--mount type=bind,source=$(KD_HOST_REPOS_DIR),destination=$(KD_CONTAINER_REPOS_DIR) \
		$(KD_KOKUA_IMAGE)

build: start setup clone_update configure compile

start:
	docker start $(KD_KOKUA_CONTAINER)
	@docker ps

shell:
	docker exec --user $(KD_CONTAINER_USER_GROUP) -it $(KD_KOKUA_CONTAINER) /bin/bash

rootshell:
	docker exec -it $(KD_KOKUA_CONTAINER) /bin/bash

copy-user:
	docker exec $(KD_KOKUA_CONTAINER) groupadd --force --gid $(shell id -g) $(shell id -gn)
	docker exec $(KD_KOKUA_CONTAINER) useradd --uid $(shell id -u) --gid $(shell id -g) $(USER)
	docker exec $(KD_KOKUA_CONTAINER) chown $(KD_CONTAINER_USER_GROUP) $(KD_CONTAINER_REPOS_DIR)
	@docker exec $(KD_KOKUA_CONTAINER) ls -l $(KD_CONTAINER_REPOS_DIR)

clone:
	for repo in $(KD_REPOS) ; do $(EXEC_CMD) git clone $(KD_BASE_URL)/$$repo $(KD_CONTAINER_REPOS_DIR)/$$repo ; done

pull:
	for repo in $(KD_REPOS) ; do $(EXEC_CMD) git -C $(KD_CONTAINER_REPOS_DIR)/$$repo pull ; done

configure:
	$(BUILD_CMD) autobuild configure -A 64 -c ReleaseOS

compile:
	$(BUILD_CMD) autobuild build -A 64 -c ReleaseOS
	@ls -l $(KD_HOST_REPOS_DIR)/kokua/build-linux-x86_64/newview/*.xz

run:
	cd $(KD_HOST_REPOS_DIR)/kokua/build-linux-x86_64/newview/packaged && ./kokua

clean:
	-docker rm --force $(KD_KOKUA_CONTAINER)
	-docker rmi --force $(KD_KOKUA_IMAGE)
	@echo ""
	@docker ps -a
	@echo ""
	@docker images

help:
	@echo "settings - list the current settings"
	@echo "pullimage - pull down the base debian $(KD_DEBIAN_VERSION) image"
	@echo "image - create the docker image"
	@echo "container - create the docker container"
	@echo "start - start the container"
	@echo "copy-user - copy $(KD_CONTAINER_USER_GROUP) into the container"
	@echo "shell - start a user shell on the container"
	@echo "rootshell - start a rootshell on the container"
	@echo "clone - clone the projects"
	@echo "pull - update the projects"
	@echo "configure - the project"
	@echo "compile - the project"
	@echo "run - execute the binary built by compile"
	@echo "clean - remove container and image"
