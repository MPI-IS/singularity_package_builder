Singularity Package Builder
===========================

This repository contains a Makefile to automatically download and build
Singularity from source and create either a Debian package or a `tar.xz` file
for installing it.

To build, simply call

    make tar

or

    make deb

To specify the maintainer of the generated deb use

    make deb MAINTAINER="Bob <bob@example.com>"

The generated files will be located in the build folder.

## Requirements

For the general build dependencies of Singularity, please see the Singularity
documentation.  Note that you don't need to provide Go, this is handled by this
Makefile.

Additional requirements by this Makefile are:

- wget
- dpkg-deb


## Building a specific version

To build a different version than the default, set the `SINGULARITY_VERSION`
variable.  For example:

    make deb SINGULARITY_VERSION=3.5.0

If needed, you can also specify which version of GO is used for building by
setting `GO_VERSION` in the same way.


## Why is it using sudo?

When building singularity, a few steps are executed as root (using `sudo`) to
ensure that the files in the resulting packages have the correct permissions.
Therefore you will be prompted for your sudo password at some point during the
build.
