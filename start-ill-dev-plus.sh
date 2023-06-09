#!/bin/bash

FFDIR=/kohadevbox/koha/Koha/Illbackends/FreeForm
if [ -d "$FFDIR" ];
then
    echo "$FFDIR directory already exists. Skipping installation of FreeForm backend"
else
    echo "Installing $FFDIR"
    git clone https://github.com/PTFS-Europe/koha-ill-freeform /kohadevbox/koha/Koha/Illbackends/FreeForm
fi

BLDIR=/kohadevbox/koha/Koha/Illbackends/BLDSS
if [ -d "$BLDIR" ];
then
    echo "$BLDIR directory already exists. Skipping installation of BLDSS backend"
else
    echo "Installing $BLDIR"
    git clone https://github.com/PTFS-Europe/koha-ill-bldss /kohadevbox/koha/Koha/Illbackends/BLDSS

    echo "Installing BLDSS dependency Locale::Country"
    sudo cpanm Locale::Country
fi


echo "Updating backend_directory in koha-conf.xml"
sed -i 's/<backend_directory>\/usr\/share\/koha\/lib\/Koha\/Illbackends<\/backend_directory>/<backend_directory>\/kohadevbox\/koha\/Koha\/Illbackends<\/backend_directory> /g' /etc/koha/sites/kohadev/koha-conf.xml

echo "Enabling ILLModule systempreference"
echo "update systempreferences set value = 1 where variable = \"ILLModule\";" | koha-mysql kohadev

koha-plack --restart kohadev
flush_memcached
