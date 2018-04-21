#!/bin/bash
#source settings.conf
# functions:
# cat_Art() - init msg
# upload_Json() - configure with new jsons
# configure_json() - load jsons into rclone config
# init_DB() - validates gdsa's & init least usage DB

cat_Secret_Art(){
touch /opt/appdata/plexguide/.rclone
cat <<ART
[32m
                         __                    ___
  ___ __ _____  ___ ____/ /________ ____  ___ / _/__ ____ [35m2[32m
 (_-</ // / _ \/ -_) __/ __/ __/ _ \`/ _ \(_-</ _/ -_) __/
/___/\_,_/ .__/\__/_/  \__/_/  \_,_/_//_/___/_/ \__/_/
        /_/    [1;39;2mLoad Balanced Multi-SA Gdrive Uploader
[0m
┌────────────────────────────────────────────────────────┐
│ Version               :   Beta 2.1 Secret Edition      │
│ Author                :   Flicker-Rate                 │
│ Special Thanks        :   ddurdle                      │
│ —————————————————————————————————————————————————————— │
│ Bypass the 750GB/day limit on a single Gsuite account. │
│ [5;31m           ⚠ Loose Lips Might Sink Ships! ⚠[0m            │
│      Do your part and keep publicity to a minimum.     │
│     Don't talk about this method on public forums.     │
└────────────────────────────────────────────────────────┘
ART
}

cat_Art(){
cat <<ART
[0m
                         __                    ___
  ___ __ _____  ___ ____/ /________ ____  ___ / _/__ ____
 (_-</ // / _ \/ -_) __/ __/ __/ _ \`/ _ \(_-</ _/ -_) __/
/___/\_,_/ .__/\__/_/  \__/_/  \_,_/_//_/___/_/ \__/_/
        /_/                      [1;39;2mFast Gdrive Uploader
[0m
┌────────────────────────────────────────────────────────┐
│ Version               :   Beta 2.1                     │
│ Author                :   Flicker-Rate                 │
└────────────────────────────────────────────────────────┘

ART
}

cat_Help(){
cat <<HELP
Usage: supertransfer [OPTION]

##############################
ATTN: Commands not ready yet!
##############################

  -s, --status           bring up status menu (not ready)
  -l, --logs             show program logs
  -r, --restart          restart daemon
      --stop             stop daemon
      --start            start daemon

  -c, --config           start configuration wizard
      --config-json      configure SA's used
      --config-email     configure gdrive account impersonation

      --pw=PASSWORD      unlocks secret multi-SA mode $(rev <<<eldrud)
  -v  --validate         validates json account(s)
  -V  --version          outputs version
  -h, --help             what you're currently looking at

Please report any bugs to @flicker-rate#3637 on discord, or at plexguide.com
HELP
}

cat_Troubleshoot(){
cat <<EOF
####### Troubleshooting steps: ###########################

1. Make sure you have enabled gdrive api access in
   both the dev console and admin security settings.

2. Check if the json keys have "domain wide delegation"

3. Check if the this email is correct: $gdsaImpersonate
      - if it is incorrect, configure it again with:
        supertransfer --config

##########################################################
EOF
}

upload_Json(){
[[ ! -e $jsonPath ]] && mkdir $jsonPath && log 'Json Path Not Found. Creating.' INFO
[[ ! -e $jsonPath ]] && log 'Json Path Could Not Be Created.' FAIL
[[ ! -e $settings ]] && cp settings.conf $jsonPath && log 'Configuration File Not Found. Creating.' INFO
[[ ! -e $settings ]] && log "Config at $settings Could Not Be Created." FAIL

localIP=$(curl -s icanhazip.com)
[[ -z $localIP ]] && localIP=$(wget -qO- http://ipecho.net/plain ; echo)
cd $jsonPath
python3 /opt/plexguide/scripts/supertransfer/jsonUpload.py &>/dev/null &
jobpid=$!
trap "kill $jobpid" SIGTERM

cat <<MSG

############ CONFIGURATION ################################

1. Go to [32mhttp://${localIP}:8000[0m
2. Follow the instructions to generate the json keys
2. Upload 9-99 Gsuite service account json keys
          - each key == +750gb max daily upload
3. Enter your gsuite email in the next step

Make sure you allow api access in the security settings
and check "enable domain wide delegation"

Want to upload keys securely? SCP json keys directly into
$jsonPath

###########################################################

MSG
read -rep $'\e[032m   -- Press any key when you are done uploading --\e[0m'
trap "exit 1" SIGTERM
echo
start_spinner "Terminating Web Server."
sleep 3.5
{ kill $jobpid && wait $jobpid; } &>/dev/null
stop_spinner $(( ! $? ))

if [[ $(ps -ef | grep "jsonUpload.py" | grep -v grep) ]]; then
  start_spinner "Web Server Still Running. Attempting to kill again."
	jobpid=$(ps -ef | grep "jsonUpload.py" | grep -v grep | awk '{print $2}')
	sleep 5
  { kill $jobpid && wait $jobpid; } &>/dev/null
  stop_spinner $(( ! $? ))
fi

numKeys=$(ls $jsonPath | egrep -c .json$)
if [[ $numKeys > 0 ]];then
   log "Found $numKeys Service Account Keys" INFO
    read -p 'Please Enter your Gsuite email: ' email
    sed -i '/'^$gdsaImpersonate'=/ s/=.*/='$email'/' $usersettings
    source $usersettings
    [[ $gdsaImpersonate == $email ]] && log "SA Accounts Configured To Impersonate $gdsaImpersonate" INFO || log "Failed To Update Settings" FAIL
else
   log "No Service Keys Found. Try Again." FAIL
   exit 1
fi
return 0
}


configure_Json(){
rclonePath=$(rclone -h | grep 'Config file. (default' | cut -f2 -d'"')
[[ ! $(ls $jsonPath | egrep .json$) ]] && log "No Service Accounts Json Found." FAIL && exit 1
# add rclone config for new keys if not already existing
for json in ${jsonPath}/*.json; do
  if [[ ! $(egrep  '\[GDSA[0-9]+\]' -A7 $rclonePath | grep $json) ]]; then
    oldMaxGdsa=$(egrep  '\[GDSA[0-9]+\]' $rclonePath | sed 's/\[GDSA//g;s/\]//' | sort -g | tail -1)
    newMaxGdsa=$(( $oldMaxGdsa++ ))
cat <<-CFG >> $rclonePath
[GDSA${newMaxGdsa}]
type = drive
client_id =
client_secret =
scope = drive
root_folder_id = $rootFolderId
service_account_file = $json
team_drive = $teamDrive
CFG
    (($newGdsaCount++))
  fi
done
[[ -n $newGdsaCount ]] && log "$newGdsaCount New Gdrive Service Account Added." INFO
return 0
}


init_DB(){
[[ $gdsaImpersonate == 'your@email.com' ]] \
  && echo -e "[$(date +%m/%d\ %H:%M)] [FAIL]\tNo Email Configured. Please edit $usersettings" \
  && exit 1

# get list of avail gdsa accounts
gdsaList=$(rclone listremotes | sed 's/://' | egrep '^GDSA[0-9]+$')
if [[ -n $gdsaList ]]; then
    numGdsa=$(echo $gdsaList | wc -w)
    maxDailyUpload=$(python3 -c "round($numGdsa * 750 / 1000, 3")
    echo -e "[$(date +%m/%d\ %H:%M)] [INFO]\tInitializing $numGdsa Service Accounts:\t${maxDailyUpload}TB Max Daily Upload"
    echo -e "[$(date +%m/%d\ %H:%M)] [INFO]\tValidating Domain Wide Impersonation:\t$gdsaImpersonate"
else
    echo -e "[$(date +%m/%d\ %H:%M)] [FAIL]\tNo Valid SA accounts found! Is Rclone Configured With GDSA## remotes?"
    exit 1 1
fi

# validate gdsaList, purge broken gdsa's & init db
echo '' > $gdsaDB
for gdsa in $gdsaList; do
  if [[ $(rclone touch --drive-impersonate $gdsaImpersonate ${gdsa}:/.SAtest ) ]]; then
    echo "${gdsa}=0" >> $gdsaDB
    echo -e "[$(date +%m/%d\ %H:%M)] [INFO]\tGDSA Impersonation Success:\t ${gdsa}.json"
  else
    gdsaList=$(echo $gdsaList | sed 's/'$gdsa'//')
    ((++gdsaFail))
    echo -e "[$(date +%m/%d\ %H:%M)] [WARN]\tGDSA Impersonation Failure:\t ${gdsa}.json"
  fi
sleep 0.5
done

[[ -n $gdsaFail ]] \
  && echo -e "[$(date +%m/%d\ %H:%M)] [WARN]\t$gdsaFail Failure(s). Did you enable Domain Wide Impersonation In your Google Security Settings?"

[[ -e $upoadHistory ]] || touch $uploadHistory
}
