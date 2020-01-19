#
# This script contains utility functions
# related to the apt package manager
#


update() {
    # Updates the apt repositories.
    sudo apt-get update
}


upgrade() {
    # Upgrades all the packages.
    sudo apt-get upgrade -y
}