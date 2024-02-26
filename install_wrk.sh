#! /bin/bash

echo "# Install dependencies"
sudo dnf -y install make automake gcc openssl-devel git

echo "# Clone the wrk repository"
git clone https://github.com/wg/wrk.git
cd wrk

echo "# Build wrk"
make

echo "# Move the wrk binary to a directory in PATH"
sudo mv wrk /usr/local/bin/

echo "# Clean up"
cd ..
rm -rf wrk

echo "wrk installed successfully."
