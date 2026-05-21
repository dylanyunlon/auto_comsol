1. Make sure the DVD or folder used to install COMSOL is accessible under same path
   it was during COMSOL Server setup

2. Open terminal as user who installed COMSOL Server (typically, as root)
   CD to COMSOL Server installation directory (where comsolsetup.log resides)
   and run "comsol_Server_Workaround.sh"

3. Wait until script completes

4. Run "<COMSOL Installation directory>/bin/comsol server". Specify login and password
   for COMSOL Server administrative user. The server starts.

5. Open "http://localhost:2036" and login with your COMSOL Server user account 
   and password

Fixed by TeAM dylan-dylan