echo "Installing koha-ill-dev"
git clone https://github.com/ammopt/koha-ill-dev.git /kohadevbox/koha/koha-ill-dev

echo "Installing fake data dependencies"
sudo cpan Data:Faker
sudo cpan Text:Lorem

koha-plack --restart kohadev
flush_memcached

echo "Generating Patron attributes. This may take a couple minutes"
cd /kohadevbox/koha/koha-ill-dev && PERL5LIB=$PERL5LIB:lib perl fake_data.pl -e pattributes --how-many $1 --reset-data

koha-plack --restart kohadev
flush_memcached