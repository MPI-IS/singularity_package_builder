
SINGULARITY_VERSION=3.7.1
GO_VERSION=1.13
PKG_VERSION=1
PKG_NAME=singularity-container_${SINGULARITY_VERSION}-${PKG_VERSION}

GO_TAR_FILE=go${GO_VERSION}.linux-amd64.tar.gz
SINGULARITY_TAR_FILE=singularity-${SINGULARITY_VERSION}.tar.gz

go:
	wget "https://dl.google.com/go/${GO_TAR_FILE}"
	tar -xzf "${GO_TAR_FILE}"


singularity: go
	wget "https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/${SINGULARITY_TAR_FILE}"
	tar -xzf "${SINGULARITY_TAR_FILE}"

	# This is a hack to enable building singularity in the subdirectory of a git
	# repository.  In their current build script, they first go up the file
	# system tree until they find a `.git` directory and try to get the version
	# from it.  If that fails it looks for a VERSION file in the same directory
	# as the `.git`.  If it is not found there, the build fails.  Since here the
	# build is happening in a subdirectory of a git repo, this breaks the
	# build...  As a workaround, copy the VERSION file to the root of the
	# repository.
	cp singularity/VERSION .

	export PATH=$$(pwd)/go/bin:$$PATH; cd singularity; ./mconfig
	export PATH=$$(pwd)/go/bin:$$PATH; cd singularity/builddir; make

	# sudo is needed to ensure correct file permissions
	cd singularity/builddir; sudo make install DESTDIR="../../${PKG_NAME}"

.PHONY: tar
tar: singularity
	tar --xz -cf ${PKG_NAME}.tar.xz -C ${PKG_NAME} usr/

.PHONY: deb
deb: singularity
	# need sudo because the "PKG_NAME" directory is owned by root
	sudo mkdir -p "${PKG_NAME}/DEBIAN"
	sudo cp tmpl/DEBIAN_control "${PKG_NAME}/DEBIAN/control"
	sudo sed -i "s/%VERSION%/${SINGULARITY_VERSION}-${PKG_VERSION}/" "${PKG_NAME}/DEBIAN/control"

	dpkg-deb --build ${PKG_NAME}


.PHONY: clean
clean:
	rm -f "${GO_TAR_FILE}" "${SINGULARITY_TAR_FILE}" VERSION
	rm -rf go singularity "${PKG_NAME}"
