#!/bin/bash

# TODOs:
# Add RapidILL?
# Put the below code inside a foreach

FFDIR=/kohadevbox/koha/Koha/Illbackends/FreeForm
if [ -d "$FFDIR" ];
then
    echo "$FFDIR directory already exists. Skipping installation of FreeForm backend"
else
    echo "Installing $FFDIR"
    git clone https://github.com/PTFS-Europe/koha-ill-freeform $FFDIR
fi

BLDIR=/kohadevbox/koha/Koha/Illbackends/BLDSS
if [ -d "$BLDIR" ];
then
    echo "$BLDIR directory already exists. Skipping installation of BLDSS backend"
else
    echo "Installing $BLDIR"
    git clone https://github.com/PTFS-Europe/koha-ill-bldss $BLDIR

    echo "Installing BLDSS dependency Locale::Country"
    sudo cpanm Locale::Country
fi

RPDDIR=/kohadevbox/koha/Koha/Illbackends/ReprintsDesk
if [ -d "$RPDDIR" ];
then
    echo "$RPDDIR directory already exists. Skipping installation of ReprintsDesk backend"
else
    echo "Installing $RPDDIR"
    git clone https://github.com/PTFS-Europe/koha-ill-reprintsdesk $RPDDIR
fi

echo "Updating backend_directory in koha-conf.xml"
sed -i 's/<backend_directory>\/usr\/share\/koha\/lib\/Koha\/Illbackends<\/backend_directory>/<backend_directory>\/kohadevbox\/koha\/Koha\/Illbackends<\/backend_directory> /g' /etc/koha/sites/kohadev/koha-conf.xml

echo "Enabling ILLModule systempreference"
echo "update systempreferences set value = 1 where variable = \"ILLModule\";" | koha-mysql kohadev

echo "Installing koha-ill-dev"
git clone https://github.com/ammopt/koha-ill-dev.git /kohadevbox/koha/koha-ill-dev

echo "Installing fake data dependencies"
sudo cpan Data:Faker
sudo cpan Text:Lorem

echo "Generating 10k ILL requests. This may take a couple minutes"
PERL5LIB=$PERL5LIB:lib perl fake_data.pl --how-many 10000 --reset-data

koha-plack --restart kohadev
flush_memcached