#!/bin/bash
#
# Title:      PlexGuide (Reference Title File)
# Author(s):  Admin9705 - Deiteq
# URL:        https://plexguide.com - http://github.plexguide.com
# GNU:        General Public License v3.0
################################################################################

# FUNCTIONS START ##############################################################
source /opt/plexguide/menu/functions/functions.sh
source /opt/plexguide/menu/functions/keys.sh
source /opt/plexguide/menu/functions/keyback.sh

keymenu () {
gcloud info | grep Account: | cut -c 10- > /var/plexguide/project.account
account=$(cat /var/plexguide/project.account)
finalprojectid=$(cat /var/plexguide/project.final)

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 PG Blitz Key Generation             📓 Reference: pgblitz.plexguide.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1 - Log-In to Your Account      $account
2 - Build a New Project
3 - Establish Project ID        [$finalprojectid]
4 - Make Service Keys
Z - Exit
A - Destory all Service Accounts Created

EOF

read -p '🌍 Type Number | Press [ENTER]: ' typed < /dev/tty

if [ "$typed" == "1" ]; then
  gcloud auth login
  echo "[NOT SET]" > /var/plexguide/project.final
  keymenu
elif [ "$typed" == "2" ]; then
  date=`date +%m%d`
  rand=$(echo $((1 + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM + RANDOM )))
  projectid="pg-$date-$rand"
  gcloud projects create $projectid
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ID: $projectid ~ Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -p '🌍 Confirm Info | Press [ENTER]: ' typed < /dev/tty
  keymenu
elif [ "$typed" == "3" ]; then
  projectid
  keymenu
elif [ "$typed" == "4" ]; then
  deploykeys
  keymenu
elif [[ "$typed" == "Z" || "$typed" == "z" ]]; then
  question1
elif [[ "$typed" == "A" || "$typed" == "a" ]]; then
  deletekeys
  keymenu
else
  badinput
  keymenu; fi
}

badmenu () {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Welcome to PG Blitz                 📓 Reference: pgblitz.plexguide.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Basic Information

Utilizes Team Drives for Data Storage and Excceds Daily 750GB Cap

$message
NOTE2: For Key Restore, only setup the 'gdrive' in the rclone config

1 - Configure RClone
Z - Exit
A - Key Restore

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

goodmenu () {
  #if [[ "$gdstatus" == "good" && "$tdstatus" == "bad" ]]; then message="4 - Deploy PG Blitz: TDrive" && message2="Z - Exit" dstatus="1";
  if [[ "$gdstatus" == "good" && "$tdstatus" == "good" ]]; then message="4 - Deploy PG Blitz: TDrive" && message2="Z - Exit" && dstatus="2";
  else message="Z - Exit" message2="" && dstatus="0"; fi

keysprocessed
keys=$(cat /var/plexguide/project.keycount)
  # Menu Interface
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Welcome to PG Blitz                  📓 Reference: pgblitz.plexguide.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Basic Information

Utilizes Team Drives and the deployment is semi-complicated. If uploading
less than 750GB per day, utilize PG Move! Good luck!

1 - Configure RClone
2 - Key Management [$keys Keys Exist]
3 - EMail Share Generator
$message
$message2
A - Key Restore
B - Key Backup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

question1 () {
readrcloneconfig

if [ "$gdstatus" == "bad" ]; then badmenu; fi
if [ "$tdstatus" == "bad" ]; then
message="NOTE1: tdrive is not setup! Required for PGBlitz's upload configuration!"
badmenu
fi

# Reminder you'll need one for gcrypt and tcrypt
if [[ "$tdstatus" == "good" && "$gdstatus" == "good" ]]; then dstatus=1 && goodmenu; fi

# Standby
read -p '🌍 Type Choice | Press [ENTER]: ' typed < /dev/tty

  if [ "$typed" == "1" ]; then
  echo
  readrcloneconfig
  rcloneconfig
  question1
elif [ "$typed" == "2" ]; then keymenu && question1;
elif [ "$typed" == "3" ]; then
bash /opt/plexguide/menu/pgblitz/emails.sh && echo
read -p '🌍 Confirm Info | Press [ENTER]: ' typed < /dev/tty
elif [ "$typed" == "4" ]; then
    rchecker
    removemounts
    #if [ "$dstatus" == "1" ]; then
    ufsbuilder
    echo "tdrive" > /var/plexguide/rclone/deploy.version
    ansible-playbook /opt/plexguide/menu/pgblitz/gdrive.yml
    ansible-playbook /opt/plexguide/menu/pgblitz/tdrive.yml
    ansible-playbook /opt/plexguide/menu/pgblitz/unionfs.yml
    ansible-playbook /opt/plexguide/menu/pgblitz/pgblitz.yml
    pgbdeploy
    question1
  #elif [ "$dstatus" == "2" ]; then
    #rchecker
    #ufsbuilder
    #echo "tcrypt" > /var/plexguide/rclone/deploy.version
    #ansible-playbook /opt/plexguide/menu/pgblitz/gdrive.yml
    #ansible-playbook /opt/plexguide/menu/pgblitz/tdrive.yml
    #ansible-playbook /opt/plexguide/menu/pgblitz/tcrypt.yml
    #ansible-playbook /opt/plexguide/menu/pgblitz/unionfs.yml
    #ansible-playbook /opt/plexguide/menu/pgblitz/pgblitz.yml
    #pgbdeploy
    #question1
  #else question1; fi
elif [[ "$typed" == "b" || "$typed" == "B" ]]; then
    keybackup
    question1
  elif [[ "$typed" == "a" || "$typed" == "A" ]]; then
    keyrestore
    question1
elif [[ "$typed" == "z" || "$typed" == "Z" ]]; then exit;
fi
}
keysprocessed
gcloud info | grep Account: | cut -c 10- > /var/plexguide/project.account
variable /var/plexguide/project.final "[NOT-SET]"
variable /var/plexguide/project.keycount "0"
variable /var/plexguide/project.deployed "no"
question1
