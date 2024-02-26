#! /bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 [-r]"
    echo "Options:"
    echo "  -r    Remove existing alternatives for java and javac before configuring new ones"
    exit 1
}
# Set default values
remove_existing_alternatives=false

# Parse command line options
while getopts ":r" opt; do
    case $opt in
        r)
            remove_existing_alternatives=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

#Step 1: Download Oracle JDK 17
echo "Step 1: Downloading Oracle JDK 17..."
JDK_DOWNLOAD_URL="https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz"
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$JDK_DOWNLOAD_URL"

# Step 2: Create directory /opt/java and Extract the JDK Archive to /opt/java
echo "Step 2: Creating directory /opt/java and Extracting the JDK Archive..."
sudo mkdir -p /opt/java
sudo tar -xvf jdk-17_linux-x64_bin.tar.gz -C /opt/java

echo "Step 3: Setting up Environment Variables..."
echo "Removing existing JAVA_HOME entry..."
sed -i '/export JAVA_HOME=.*\/jdk-17/d' ~/.bashrc
# Extracted directory name of the JDK
JDK_DIR=$(tar -tf jdk-17_linux-x64_bin.tar.gz | head -1 | cut -d '/' -f 1)
echo "export JAVA_HOME=/opt/java/$JDK_DIR"
echo "export JAVA_HOME=/opt/java/$JDK_DIR" >> ~/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc

# Step 4: Apply Changes
echo "Step 4: Applying Changes..."
source ~/.bashrc

# Step 5: Verify Installation
echo "Step 5: Verifying Installation..."
java -version
javac -version

# Step 6: Remove the downloaded .tar.gz file
echo "Step 6: Remove the downloaded .tar.gz file"
rm jdk-17_linux-x64_bin.tar.gz

# Step 7: Optional - Configure Alternatives
echo "Step 7: Configuring Alternatives (optional)..."
if [ "$remove_existing_alternatives" = true ]; then
    echo "Step 7: Configuring Alternatives (optional)..."
    echo "Removing existing alternatives..."
    sudo alternatives --remove-all java
    sudo alternatives --remove-all javac
    echo "Add new alternatives for java 17"
    sudo alternatives --install /usr/bin/java java /opt/java/$JDK_DIR/bin/java 1
    sudo alternatives --install /usr/bin/javac javac /opt/java/$JDK_DIR/bin/javac 1

fi

echo "Java 17 installation completed successfully!"
