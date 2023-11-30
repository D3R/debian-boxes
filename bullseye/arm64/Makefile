# Default target
.PHONY: default

# Alias targets
default: build
all: prepare clean build

# Prepare a build, initialising the packer template
prepare:
	/usr/bin/time /usr/bin/env packer init template.pkr.hcl

# Clean up old artifacts
clean:
	rm -f output/*.box
	rm -f output/*.checksum

build: export PYTHONPATH=/Library/Frameworks/ParallelsVirtualizationSDK.framework/Versions/11/Libraries/Python/3.7
build: prepare clean
build:
	test -n "$(BOX_VERSION)"
	/usr/bin/time /usr/bin/env packer build \
		-force \
		-var "box_version=${BOX_VERSION}" \
		template.pkr.hcl

upload:
	test -n "$(BOX_VERSION)"
	test -n "$(BOX_CHANNEL)"
	aws s3 cp \
		--acl public-read \
		output/base-parallels-arm64.box \
		s3://d3r-vagrant-stack/${BOX_CHANNEL}/base-parallels-arm64-${BOX_VERSION}.box
	shasum -a 256 output/base-parallels-arm64.box
	echo "IMAGE URL : https://d3r-vagrant-stack.s3.eu-west-2.amazonaws.com/${BOX_CHANNEL}/base-parallels-arm64-${BOX_VERSION}.box"
