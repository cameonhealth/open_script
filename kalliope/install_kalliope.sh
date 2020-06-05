#!/usr/bin/env bash

# This script will install automatically everything needed for Kalliope
# usage: ./rpi_install_kalliope.sh [<branch_name>]
# E.g: ./rpi_install_kalliope.sh dev
# If no branch are set, the master branch will be installed

#------------------------------------------
# Variables
#------------------------------------------
# name of the branch to install
branch="master"
python_version="3.7.6"
#------------------------------------------
# Functions
#------------------------------------------
echo_green(){
    echo -e "\e[32m$1\033[0m"
}

echo_yellow(){
    echo -e "\e[33m$1\033[0m"
}

install_default_packages(){
    echo_green "Installing system packages..."
    sudo apt-get update
    sudo apt-get install -y git python3-dev libsmpeg0 \
    flac libffi-dev libffi-dev libssl-dev portaudio19-dev build-essential \
    libssl-dev libffi-dev sox libatlas3-base mplayer libyaml-dev libpython3-dev libjpeg-dev
    sudo apt-get install -y libportaudio0 libportaudio2 libportaudiocpp0  \
    apt-transport-https python3-venv
    echo_green "Installing system packages...[OK]"
}

install_default_packages_ubuntu(){
    echo_green "Installing system packages..."
    sudo apt-get update
    sudo apt install -y git python3-dev python3.7-dev libsmpeg0 
    libttspico-utils flac libffi-dev libssl-dev portaudio19-dev build-essential \
    sox libatlas3-base mplayer wget vim sudo locales alsa-base alsa-utils \
    pulseaudio-utils libasound2-plugins python3-pyaudio libasound-dev \
    libportaudio2 libportaudiocpp0 ffmpeg python3-venv
    echo_green "Installing system packages...[OK]"

}

install_python3(){
     sudo apt-get install build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev libdb5.3-dev \
     libgdbm-dev libsqlite3-dev libssl-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev -y

     wget https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tar.xz
     tar xf Python-${python_version}.tar.xz
     cd Python-${python_version}
     ./configure
     make -j 4
     sudo make altinstall
     echo_green "Installing python3... [OK]"
}

install_pip3(){
    echo_green "Installing python pip..."
    sudo apt-get install -y python3-distutils
    wget https://bootstrap.pypa.io/get-pip.py
    sudo python3 get-pip.py
    echo_green "Installing python pip... [OK]"
}

install_pico2wave(){
    debian_version=`cat /etc/os-release |grep buster`
    retVal=$?
    if [[ ${retVal} -ne 0 ]]; then
        echo "Debian < 10"
        sudo apt-get install ffmpeg libttspico-utils
    else
        echo "Debian 10 Buster detected. Installing pico2wave manually"
        sudo apt-get install -y ffmpeg
        wget http://ftp.fr.debian.org/debian/pool/non-free/s/svox/libttspico-utils_1.0+git20130326-9_armhf.deb
        wget http://ftp.fr.debian.org/debian/pool/non-free/s/svox/libttspico0_1.0+git20130326-9_armhf.deb
        wget http://ftp.fr.debian.org/debian/pool/non-free/s/svox/libttspico-data_1.0+git20130326-9_all.deb
        sudo dpkg -i libttspico-data_1.0+git20130326-9_all.deb
        sudo dpkg -i libttspico-utils_1.0+git20130326-9_armhf.deb
        sudo dpkg -i libttspico0_1.0+git20130326-9_armhf.deb
    fi
}

install_kalliope(){
    if [[ -d "cavu-kalliope" ]]; then
        echo_green "Source folder already cloned"
    else
        echo_yellow "Cloning the project"
        git_credential_set
        # clone the project
        git clone https://github.com/cavuai/cavu-kalliope.git
        git clone https://github.com/cavuai/smartor-kalliope.git
        echo_green "Cloning the project...[OK]"
    fi
    # Install the project
    echo_yellow "Installing Kalliope..."

    # Create virtualenv
    python3 -m venv venv
    source venv/bin/activate
    # fix for last ansible
    pip install "ansible==2.9.5"
    pip install "Cython" 
    cd cavu-kalliope    
    python setup.py install
    cd ..
    echo_green "Installing Kalliope...[OK]"
}
git_credential_set(){
    echo_green "Git credential set..."
    git config --global credential.helper cache --timeout=360
    echo_green "Git credential set...[OK]"
}
#------------------------------------------
# Main
#------------------------------------------
# get the branch name to install from passed arguments if exist
if [[ $# -eq 0 ]]
  then
    echo "No arguments supplied. Master branch will be installed"
else
    branch=$1
    echo "Selected branch name to install: ${branch}"
fi

## install packages
platform=$(cat /etc/os-release | grep ID= | awk '/[a-b]/{print $1}' | sed -e "s/ID=//")
if [ ${platform} = "ubuntu" ]
    then
    echo_green "OS name : Ubuntu"
    install_default_packages_ubuntu
elif [ ${platform} = "raspbian" ]
    then
    echo_green "OS name : Raspbian"
    install_default_packages
    if command -v pico2wave &>/dev/null; then
        echo_green "Pico2wave is installed"
    else
        echo_yellow "Pico2wave is not installed"
        install_pico2wave
    fi
else
    echo "platform check please"
fi


if command -v python3 &>/dev/null; then
    echo_green "Python 3 is installed"
else
    echo_yellow "Python 3 is not installed"
    install_python3
fi

if command -v pip3 &>/dev/null; then
    echo_green "Pip 3 is installed"
else
    echo_yellow "Pip 3 is not installed"
    install_pip3
fi

install_kalliope

# fix https://github.com/kalliope-project/kalliope/issues/487
sudo chmod -R o+r /usr/local/lib/python3.7/dist-packages/
