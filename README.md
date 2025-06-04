# jamdock-suite
This suite is designed to support researchers in the early stages of drug discovery and drug repurposing projects, helping to streamline large-scale virtual screening workflows and lower the barriers to performing molecular docking experiments. The suite includes five Bash scripts to simplify and automate key steps in a virtual screening pipeline such as compound library preparation, receptor setup, automated docking, job resumption, and docking result analysis, using tools such as QuickVina 2, Open Babel, AutoDockTools and fpocket.

## Content

- **jamlib** – Automatically generates compound libraries in PDBQT format, including FDA-approved drugs and custom libraries of purchasable compounds, ready for use with QuickVina 2.
- **jamreceptor** – Prepares receptor structures (in PDB format) by converting them to PDBQT, identifying binding pockets using fpocket, and generating grid box configuration files.
- **jamqvina** – Automates the setup and execution of docking jobs with QuickVina 2, including parameter configuration and time estimation.
- **jamresume** – Enables the resumption of interrupted docking jobs, whether due to planned pauses or unexpected failures.
- **jamrank** – Provides two modes for analyzing docking results:
      - A fast mode that outputs affinities, ZINC links, and compound IDs.
      - A detailed mode that additionally computes a similarity score among poses, molecular weight, number of modes, and generates a comprehensive summary.

# System setup
Current version of jamdock-suite is designed to run into a Linux machine. Windows 11 users can install a desired Linux distribution under WSL (https://learn.microsoft.com/en-us/windows/wsl/install).

Before executing the scripts install and setup your equipment following the next steps:

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
**4. Installing QuickVina 2**
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
**5. Installing jamdock-suite**
```bash
cd ~/Programs
git clone https://github.com/jamanso/jamdock-suite.git
cd jamdock-suite
chmod +x jamlib jamreceptor jamqvina jamresume jamrank
echo 'export PATH="$HOME/Programs/jamdock-suite:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
# Getting started
To begin using the jamdock-suite, follow the steps below to set up and run a full virtual screening workflow. These steps assume you have installed all required dependencies and added the suite to your system PATH.
