1. Mount COMSOL DVD into virtual DVD drive and start installation with shell:

     ./setup

   NOTE: IF running on VM with number of processors smaller than maximum installed,
   set COMSOL_NUM_NUMA=<number of sockets> or COMSOL_NUM_NUMA=1 for ordinary PC to 
   avoid error at startup:

     export COMSOL_NUM_NUMA=1
     ./setup

2. Select "_dylan_/LMCOMSOL_Multiphysics_6.4+_dylan.lic" to install COMSOL Multiphysics
   --or--
   Select "_dylan_/LMCOMSOL_Server_6.4+_dylan.lic" to install COMSOL Server

3. Select Components, Installation folder and options.
   At installation step "Options" untick "Check for updates after installation" and 
   "Enable automatic check for updates"

4. (OPTIONAL) If installing COMSOL Server:

   4.1 Open terminal as user who installed COMSOL Server (typically, as root)
       CD to COMSOL Server installation directory (where comsolsetup.log resides)
       and run "comsol_Server_Workaround.sh"

   4.2 Wait until script completes

5. Run "<COMSOL Installation directory>/bin/comsol multiphysics" or click on desktop
   shortcut
   --or--
   Run "<COMSOL Installation directory>/bin/comsol server". Specify login and password
   for COMSOL Server administrative user. The server starts

6. (OPTIONAL) If installing COMSOL Server, open "http://localhost:2036" and login with 
   the COMSOL Server user account and password

   NOTE: If the user and password do not match, run "<COMSOL Installation directory>/setup"
         and select "Add/remove components and reinstall", then recreate administrative user

7. Enjoy!

Createdby TeAM dylan-dylan