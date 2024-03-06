#! /bin/bash

# Install Java 17
echo "# Install Java 17"
bash install_java17.sh
echo "# Finish install Java 17"

# Jmeter
filenamezip="apache-jmeter-5.6.2.zip"
filename="apache-jmeter-5.6.2"

echo "# Install Jmeter"
echo "Download from GDrive"
bash download_gdrive.sh
echo "Unzip to user home"
unzip -o "$filenamezip" -d ~/
echo "# Finish install Jmeter"

# Install repo epel=release
echo "# Install epel-release"
sudo dnf -y install epel-release
echo "# Finish install epel-release"

# Install htop and nload
echo "# Install htop and nload"
sudo dnf -y install htop nload
echo "# Finish install htop and nload"

# Install Wrk
echo "# Install Wrk"
bash install_wrk.sh
echo "# Finish install Wrk"
