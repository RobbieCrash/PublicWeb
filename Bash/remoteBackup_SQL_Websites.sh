#!/bin/bash

# Use -pPASSWORD to skip interactive prompt, probably a better way than plain texting password in.
# Dump a copy of all MySQL databases to /backups

for database in $(mysql -e 'show databases' -s --skip-column-names -pPASSWORD)
    do mysqldump $database -pPASSWORD > /backups/$database.sql
done

# Tar up all the databases
tar -vzcf "/backups/Websites.Databases.$(date +%Y-%m-%d-%H)00.tgz" /backups/*.*
# Tar up all the website data
tar -vzcf "/backups/Websites.Data.$(date +%Y-%m-%d-%H)00.tgz" /var/www

# Set filename for cleanliness
filename=$(date +%Y-%m-%d-%H)00
# Tar both previous tarballs together
tar -vzcf "/backups/Websites.$filename.tgz" /backups/*.tgz

# Copy to remote host.
scp -i /HOME/USER/.SSH/ID_RSA.PUB /backups/Websites.$filename.tgz USER@REMOTEHOST:/PATH/TO/PUT/TARBALL/IN

# Clean up backup data.
# You may want to change the amount of backups you keep, this is less than 30 days
find /backups/Websites/old -type f -mtime +30 -name "*.tgz" -exec  rm -rf {} \;
# Move new files to old directory
cp /backups/Websites.$filename.tgz /backups/Websites/old/$filename.tgz
# Remove everything we just tossed in there.
rm /backups/*.*
