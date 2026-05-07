#!/bin/bash

set -e

# The list of version to build docker packages for
DOLIBARR_VERSIONS=("20.0.4" "21.0.4" "22.0.4" "23.0.2" "develop")
DOLIBARR_VERSIONS=("develop")

# The version to use when installing dolibarr/dolibarr:latest
DOLIBARR_LATEST_TAG="23.0.2"

# The version to use to find the dump file for the init of demo with branch "develop"
DOLIBARR_VERSION_FOR_INIT_DEMO="23.0"
