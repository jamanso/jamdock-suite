**1. Update and install essential packages:**

Open a terminal (Bash Shell) and execute
```bash
 sudo apt update && sudo apt upgrade -y
```
```bash
 sudo apt install -y build-essential gedit cmake openbabel pymol libxmu6 wget bc git libboost1.74-all-dev xutils-dev
```
**2. Install AutoDockTools (MGLTools)**
```bash
mkdir ~/Programs
cd ~/Programs
wget https://ccsb.scripps.edu/mgltools/download/491/mgltools_Linux-x86_64_1.5.7.tar.gz
tar -zxf mgltools_Linux-x86_64_1.5.7.tar.gz
cd mgltools_x86_64Linux2_1.5.7/
./install.sh
echo 'alias adt='$HOME/Programs/mgltools_x86_64Linux2_1.5.7/bin/adt'' >> ~/.bashrc
source ~/.bashrc
```
**3. Install fpocket**
```bash
cd ~/Programs
git clone https://github.com/Discngine/fpocket.git
cd fpocket
make
sudo make install
```
**4. Install QuickVina 2**
```bash
cd ~/Programs
git clone https://github.com/QVina/qvina.git
cd qvina
git checkout qvina2
```
Edit the top of the Makefile to match your Boost installation:
```bash
BASE = /usr/include/boost
BOOST_VERSION=1_74 #or your installed version
```
Build the program:
```bash
make
```
Configure environment variables for QuickVina 2.
```bash
echo 'alias qvina02='$HOME/Programs/qvina/qvina02'' >> ~/.bashrc
echo 'export PATH=$HOME/Programs/qvina:$PATH' >> ~/.bashrc
source ~/.bashrc
```
**5. Install jamdock-suite**
```bash
cd ~/Programs
git clone https://github.com/jamanso/jamdock-suite.git
cd jamdock-suite
chmod +x jamlib jamreceptor jamqvina jamresume jamrank
echo 'export PATH="$HOME/Programs/jamdock-suite:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
