# synology-photos-auto-sort
A script to rename, move and sort images and videos files from a source folder to a target folder.

## How it works?
To work this script need **exiftool** installed on your NAS. The best way to install this tool is to add a new package sources from http://www.cphub.net then you will have exiftool available as a package.

* Create in your NAS a folder which would be the source folder of the script
* Add images and videos inside this folder
* run the script like **./synology-photos-auto-sort.sh /path_of_source_folder /path_of_destination_folder**
  Full exemple : ./synology-photos-auto-sort.sh /volume1/Download/images_temp/ /volume1/photo
* The script will move and rename photos and videos in taget folder like this structure :
  **/Target_folder/YEAR/Year.Month/yearmonthday_hourminutesseconds.jpg**
* If a file with the same name already exist, th script will create an error folder inside the source folder and move images and videos inside this error folder

## How to automatise this script?
Access to your NAS with ssh, then clone this repository.

* `ssh user@nas_ip`
* `git clone https://github.com/Gulivertx/synology-photos-auto-sort.git`

Add a new cron job to run periodically the script
* `sudo vi /etc/crontab`
* `* * * * * root /var/services/homes/gulivert/synology-photos-auto-sort/synology-photos-auto-sort.sh /volume1/Download/images_temp /volume1/photo`
* `sudo synoservice -restart crond`

Replace **gulivert** by your username.

This rule will launch the script every minute using as source folder /volume1/Download/images_temp and /volume1/photo as target.
