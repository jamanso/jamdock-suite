# jamdock-suite
This suite includes five Bash scripts to simplify and automate key steps in a virtual screening pipeline. The scripts facilitate compound library preparation, receptor setup, automated docking, job resumption, and docking result analysis, using tools such as QuickVina 2, Open Babel, AutoDockTools and fpocket.

The scripts included are:

1. **jamlib.sh** – Automatically generates compound libraries in PDBQT format, including FDA-approved drugs and custom libraries of purchasable compounds, ready for use with QuickVina 2.
2. **jamreceptor.sh** – Prepares receptor structures (in PDB format) by converting them to PDBQT, identifying binding pockets using fpocket, and generating grid box configuration files.
3. **jamqvina.sh** – Automates the setup and execution of docking jobs with QuickVina 2, including parameter configuration and time estimation.
4. **jamresume.sh** – Enables the resumption of interrupted docking jobs, whether due to planned pauses or unexpected failures.
5. **jamrank.sh** – Provides two modes for analyzing docking results:
      - A fast mode that outputs affinities, ZINC links, and compound IDs.
      - A detailed mode that additionally computes a similarity score among poses, molecular weight, number of modes, and generates a comprehensive summary.
        
This suite is designed to support researchers in the early stages of drug discovery and drug repurposing projects, helping to streamline large-scale virtual screening workflows and lower the barriers to performing molecular docking experiments.
# System setup
