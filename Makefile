
SINGULARITY_VERSION=3.7.1
GO_VERSION=1.13
PKG_VERSION=1
PKG_NAME=singularity-container_${SINGULARITY_VERSION}-${PKG_VERSION}

GO_TAR_FILE=go${GO_VERSION}.linux-amd64.tar.gz
SINGULARITY_TAR_FILE=singularity-${SINGULARITY_VERSION}.tar.gz

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BUILD_DIR=${ROOT_DIR}/build

build_folder:
	mkdir -p ${BUILD_DIR}

go: build_folder
	cd ${BUILD_DIR}; wget "https://dl.google.com/go/${GO_TAR_FILE}"
	cd ${BUILD_DIR}; tar -xzf "${GO_TAR_FILE}"


singularity: go
	cd ${BUILD_DIR}; wget "https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/${SINGULARITY_TAR_FILE}"
	cd ${BUILD_DIR}; tar -xzf "${SINGULARITY_TAR_FILE}"

	# This is a hack to enable building singularity in the subdirectory of a git
	# repository.  In their current build script, they first go up the file
	# system tree until they find a `.git` directory and try to get the version
	# from it.  If that fails it looks for a VERSION file in the same directory
	# as the `.git`.  If it is not found there, the build fails.  Since here the
	# build is happening in a subdirectory of a git repo, this breaks the
	# build...  As a workaround, copy the VERSION file to the root of the
	# repository.
	cp ${BUILD_DIR}/singularity/VERSION ${BUILD_DIR}

	export PATH=${BUILD_DIR}/go/bin:$$PATH; cd ${BUILD_DIR}/singularity; ./mconfig
	export PATH=${BUILD_DIR}/go/bin:$$PATH; cd ${BUILD_DIR}/singularity/builddir; make

	# sudo is needed to ensure correct file permissions
	cd ${BUILD_DIR}/singularity/builddir; sudo make install DESTDIR="${BUILD_DIR}/${PKG_NAME}"

.PHONY: tar
tar: singularity
	cd ${BUILD_DIR}; tar --xz -cf ${PKG_NAME}.tar.xz -C ${PKG_NAME} usr/

.PHONY: deb
deb: singularity
	
	# need sudo because the "PKG_NAME" directory is owned by root
	cd ${BUILD_DIR}; sudo mkdir -p "${PKG_NAME}/DEBIAN"
	sudo cp ${ROOT_DIR}/tmpl/DEBIAN_control "${BUILD_DIR}/${PKG_NAME}/DEBIAN/control"
	sudo sed -i "s/%VERSION%/${SINGULARITY_VERSION}-${PKG_VERSION}/" "${BUILD_DIR}/${PKG_NAME}/DEBIAN/control"

	cd ${BUILD_DIR};dpkg-deb --build ${PKG_NAME}


.PHONY: clean
clean:
	rm -rf ${BUILD_DIR}
