# jamdock-suite
This suite includes five Bash scripts to simplify and automate key steps in a virtual screening pipeline. The scripts facilitate compound library preparation, receptor setup, automated docking, job resumption, and docking result analysis, using tools such as QuickVina 2, OpenBabel, AutoDockTools and fpocket.
2. Update and install essential packages:
	
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y build-essential gedit cmake openbabel pymol libxmu6 wget bc git libboost1.74-all-dev xutils-dev

    == Note for WSL users using Ubuntu: You may also need the zombie-imp Python module: sudo apt install python3-zombie-imp ==

3. Install AutoDockTools (MGLTools)

	mkdir ~/Programs
	cd ~/Programs
	wget https://ccsb.scripps.edu/mgltools/download/491/mgltools_Linux-x86_64_1.5.7.tar.gz
	tar -zxf mgltools_Linux-x86_64_1.5.7.tar.gz
	cd mgltools_x86_64Linux2_1.5.7/
	./install.sh

    - Add alias to your .bashrc:
	
	gedit ~/.bashrc  

    - Add the following line to the end of the file:

	alias adt='$HOME/Programs/mgltools_x86_64Linux2_1.5.7/bin/adt'

    - Activate the changes:

	source ~/.bashrc

4. Installing Fpocket

	cd ~/Programs
	git clone https://github.com/Discngine/fpocket.git
	cd fpocket
	make
	sudo make install

5. Installing QuickVina 2

	cd ~/Programs
	git clone https://github.com/QVina/qvina.git
	cd qvina
	git checkout qvina2

    - Edit the top of the Makefile to match your Boost installation:

	BASE = /usr/include/boost
	BOOST_VERSION=1_74 #or your installed version

    - Build the program:

	make

    - Configure environment variables for QuickVina 2. Edit the .bashrc file.
	
	gedit ~/.bashrc

    - Append the following lines:

	alias qvina02='$HOME/Programs/qvina/qvina02'
	export PATH=$HOME/Programs/qvina:$PATH

    - Activate the changes:

	source ~/.bashrc
