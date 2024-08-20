# Default target
.PHONY: default

# Default variable values
# BOX_VERSION has no default and must be set explicitly
OS_CODENAME ?= bullseye
BOX_CHANNEL ?= stable

# Alias targets
default: build
all: prepare clean build

# Prepare a build, initialising the packer template
prepare:
	/usr/bin/time /usr/bin/env packer init template.pkr.hcl

# Clean up old artifacts
clean-all:
	rm -fR output

clean:
	test -n "$(OS_CODENAME)"
	rm -f output/$(OS_CODENAME).*

build: prepare clean-all
build:
	test -n "$(OS_CODENAME)"
	test -n "$(BOX_VERSION)"
	/usr/bin/time /usr/bin/env packer build \
		-force \
		-var "os_codename=${OS_CODENAME}" \
		-var "box_version=${BOX_VERSION}" \
		template.pkr.hcl

upload:
	test -n "$(OS_CODENAME)"
	test -n "$(BOX_VERSION)"
	test -n "$(BOX_CHANNEL)"
	aws s3 cp \
		--acl public-read \
		output/${OS_CODENAME}-amd64.box \
		s3://d3r-vagrant-stack/${BOX_CHANNEL}/${OS_CODENAME}-amd64-${BOX_VERSION}.box
	cat output/${OS_CODENAME}-amd64.box.checksum
	echo "IMAGE URL : https://d3r-vagrant-stack.s3.eu-west-2.amazonaws.com/${BOX_CHANNEL}/${OS_CODENAME}-amd64-${BOX_VERSION}.box"

# See https://developer.hashicorp.com/vagrant/vagrant-cloud/api/v2#providers
# register:
# 	test -n "$(VC_TOKEN)"
# 	test -n "$(OS_CODENAME)"
# 	test -n "$(BOX_VERSION)"
# 	test -n "$(BOX_CHANNEL)"
# 	JSON_PAYLOAD = \{ "provider": \{ "checksum": "${shell awk '{print $$1}' output/${OS_CODENAME}-amd64.box.checksum}", "checksum_type": "sha256", "name": "parallels", "url": "https://d3r-vagrant-stack.s3.eu-west-2.amazonaws.com/${BOX_CHANNEL}/${OS_CODENAME}-amd64-${BOX_VERSION}.box", "architecture": "amd64", "default_architecture": true \}\}
# 	echo $(OS_CODENAME)
# 	# echo "${JSON_PAYLOAD}"
# 	# curl \
# 	# 	--request POST \
# 	# 	--header "Content-Type: application/json" \
# 	# 	--header "Authorization: Bearer ${VC_TOKEN}" \
# 	# 	--data '{ \
# 	# 		"provider": { \
# 	# 			"checksum": "a59e7332e8bbe896f11f478fc61fa8a6", \
# 	# 			"checksum_type": "md5", \
# 	# 			"name": "virtualbox", \
# 	# 			"url": "https://example.com/virtualbox-1.2.3.box", \
# 	# 			"architecture": "amd64", \
# 	# 			"default_architecture": true \
# 	# 		} \
# 	# 	}'
