## Updating bookstack
These notes are from the process followed when upgrading from version 23.05 to Version 23.08.3

## Take backups
Backup the db and recommended files before attempting the upgrade

### Backup the database
Dump the db to a backup file

```shell
mysqldump -u $DB_USER -p $DB_DATABASE > bookstack_backup.sql
```

### Backup recommended files
Store copies of the site config and uploads in a tar archive

```shell
tar -czvf bookstack-files-backup.tar.gz .env public/uploads storage/uploads
```

## Run update commands
Run the update commands from the root directory to pull the latest version from their git repo

```shell
git pull origin release
composer install --no-dev
php artisan migrate
```

## Clear system caches
Clear caches as recommended

```shell
php artisan cache:clear
php artisan config:clear
php artisan view:clear 
```
