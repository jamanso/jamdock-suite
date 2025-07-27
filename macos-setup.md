Before running the scripts, make sure to install and set up your equipment by following the steps below. These instructions (tested on macOS Sonoma 14.6.7) assume a clean system. If you already have some of the required software installed, you may skip the corresponding steps.

Begin by ensuring Xcode Command Line Tools are installed. Open a Terminal (zsh) and run:
```bash
 xcode-select --install
```
This will prompt a pop-up window. Click Install to proceed.

**1.	Install Homebrew and essential packages**
Install Homebrew (a package manager for macOS):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Then install required packages and configure the environment:
```bash
brew update
brew install makedepend xquartz open-babel pymol git wget curl nedit bash coreutils
echo 'alias shuf="gshuf"' >> ~/.zprofile
```
Restart your computer to complete the setup.
**2. Install AutoDockTools (MGLTools)**
Download, extract, and install AutoDockTools:
```bash
mkdir ~/Programs
cd ~/Programs
wget https://ccsb.scripps.edu/download/529/mgltools_1.5.7_MacOS-X.tar_.gz
tar -zxf mgltools_1.5.7_MacOS-X.tar_.gz
cd mgltools_1.5.7_MacOS-X
./install.sh
```
*Note:* If you encounter the following error during installation:
```bash
sed /opt/XC11/lib/X11/xinit/xinitrc: No such file or directory
```
Press Ctrl + Z to halt the process, then run:
```bash
rm -f ~/.xinitrc
./install.sh
```
Configure the environment:
```bash
echo 'alias adt="$HOME/Programs/mgltools_1.5.7_MacOS-X/bin/adt"' >> ~/.zprofile
source ~/.zprofile
```



**3. Install fpocket**
The jamreceptor script also utilizes fpocket, an open-source tool for identifying and characterizing ligand-binding pockets. To install:
```bash
cd ~/Programs
git clone https://github.com/Discngine/fpocket.git
cd fpocket
make ARCH=MACOSXX86_64        #(Note: Use ARCH=MACOSXARM64 for M1 and M2 processors)
sudo make install
```
Restart the terminal before using fpocket.

**4. Install QuickVina 2**
This guide uses QuickVina 2, a fast and accurate fork of AutoDock Vina used in the jamqvina script. To install:
```bash
cd ~/Programs
git clone https://github.com/QVina/qvina.git
cd qvina
git checkout qvina2
wget https://archives.boost.io/release/1.74.0/source/boost_1_74_0.tar.gz
tar -zxf boost_1_74_0.tar.gz
cd boost_1_74_0
./bootstrap.sh
./b2 install
cd ..
```
Edit the top of the Makefile to ensure it matches your Boost installation:
```bash
BASE = /usr/local
BOOST_VERSION=1_74 #or your installed version
C_PLATFORM=-pthread
```
Then build QuickVina:
```bash
make
```
Configure your environment:
```bash
echo 'export DYLD_LIBRARY_PATH=”/usr/local/lib/:$DYLD_LIBRARY_PATH”' >> ~/.zprofile
echo 'alias qvina02="$HOME/Programs/qvina/qvina02"' >> ~/.zprofile
echo 'export PATH="$HOME/Programs/qvina:$PATH"' >> ~/.zprofile
source ~/.zprofile
```
**5. Install jamdock-suite**
```bash
cd ~/Programs
git clone https://github.com/jamanso/jamdock-suite.git
cd jamdock-suite
chmod +x jam*
echo 'export PATH="$HOME/Programs/jamdock-suite:$PATH"' >> ~/.zprofile
echo 'alias jamlib="/usr/local/bin/bash/ jamlib"' >> ~/.zprofile
source ~/.zprofile
```
