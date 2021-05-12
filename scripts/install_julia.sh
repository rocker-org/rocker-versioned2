#!/bin/bash
set -e

# Latest Julia version (this needs to be manually updated, periodically)
JULIA_LATEST=1.6-latest

JULIA_VERSION=${1:-${JULIA_VERSION:-latest}}

if [ "$JULIA_VERSION" = "latest" ]; then
    JULIA_VERSION=$JULIA_LATEST
fi
JULIA_MAJOR_VERSION=${JULIA_VERSION:0:3}

# Download and extract Julia. We'll use a common /opt/julia/ location regardless of version 
wget https://julialang-s3.julialang.org/bin/linux/x64/$JULIA_MAJOR_VERSION/julia-$JULIA_VERSION-linux-x86_64.tar.gz -O /opt/julia.tar.gz
mkdir /opt/julia
tar zxvf /opt/julia.tar.gz -C /opt/julia --strip-components 1
rm -rf /opt/julia.tar.gz

# Add to path
echo 'export PATH="/opt/julia/bin:$PATH"' >> .bashrc
source .bashrc

# Add RCall package for interoperability from Julia
julia -e 'using Pkg; Pkg.add("RCall")'

# Add R packages for interoperability the other way around
#Rscript -e 'install.packages(c("JuliaCall", "JuliaConnectoR")); JuliaCall::julia_setup()'
install2.r --error --skipinstalled JuliaCall JuliaConnectoR
Rscript -e 'JuliaCall::julia_setup()'

# Make sure we start in bash
CMD ["bash"]
