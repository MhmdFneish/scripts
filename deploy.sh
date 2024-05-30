#!/bin/bash

# $FORGE_SITE_PATH
site_path=$1
# $FORGE_SITE_BRANCH
site_branch=$2
# project-api
repo=$3
# api - cms - shop
project_type=$4
# $FORGE_PHP_FPM - project.service
service_name=$5

release_folder=$(date +%Y%m%d%H%M%S)
release_path=$site_path/releases/$release_folder

echo "============ Start ================"

echo "Create the release folder $release_folder"
mkdir -p $release_path

cd $release_path

echo "Clone the repository from branch $site_branch"
git clone -b $site_branch git@github.com:mohammadfneish/$repo.git ./

if [ -e "$release_path/.env" ]; then
    rm $release_path/.env
    echo "env file has been removed"
fi

echo "Add the env file to the deploy folder"
ln -nfs --relative $site_path/.env $release_path/.env

if [ "$project_type" = "api" ]; then
    if [ -e "$release_path/storage" ]; then
        rm -rf $release_path/storage
        echo "Storage folder has been removed"
    fi

    echo "Add the storage folder to the deploy folder"
    ln -nfs --relative $site_path/storage $release_path/

    echo "Install the dependencies libraries"
    composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

    ( flock -w 10 9 || exit 1
        echo 'Restarting FPM...'; sudo -S service php8.2-fpm reload ) 9>/tmp/fpmlock

    if [ -f artisan ]; then
        php artisan migrate --force
    fi
else
    echo "Install the dependencies libraries"
    npm install --legacy-peer-deps

    echo "Build the project"
    npm run build
fi

echo "Remove the current folder if exists"
if [ -e "$site_path/current" ]; then
    unlink $site_path/current
    echo "Current folder has been removed"
fi

echo "Create the symbolic current folder"
ln -nfs --relative $release_path $site_path/current

if [ "$project_type" = "api" ]; then
    echo "Clear cache"
    php artisan optimize:clear

    echo "Restart Queue"
    php artisan queue:restart
fi

if [ "$project_type" = "shop" ]; then
    echo "Restart the service"
    sudo systemctl restart $service_name
fi

echo "Clean up old released folders"
/home/forge/cleanup_releases.sh $site_path/releases

echo "============ DONE ================"
