# koha-ill-dev
Tools to help [Koha](https://koha-community.org/) ILL development using [koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)

## Start ILL in k-t-d
Inside the docker container, run.

#### [FreeForm](https://github.com/PTFS-Europe/koha-ill-freeform) only

```sh
bash <(curl -s https://raw.githubusercontent.com/ammopt/koha-ill-dev/master/start-ill-dev.sh)
```

#### [FreeForm](https://github.com/PTFS-Europe/koha-ill-freeform) + [BLDSS](https://github.com/PTFS-Europe/koha-ill-bldss)

```sh
bash <(curl -s https://raw.githubusercontent.com/ammopt/koha-ill-dev/master/start-ill-dev-plus.sh)
```

This will:
* Install the backend(s) if that doesn't exist. 
* Update backend_directory config in koha-conf.xml
* Enable the ILLModule system preference

# Creating fake data
Currently requires pre-existing libraries, patrons and biblio records, these should all exist out of the box using [k-t-d](https://gitlab.com/koha-community/koha-testing-docker)

## Dependencies
* Data::Faker
* Text::Lorem

## fake_data.pl options
* **reset_data** - erase current data before creating new fake data (recommended)
* **how-many** - number of fake entity instances to create

## Usage (_dev only_)

Generate 100 fake ILL requests and 100 fake comments:

```sh
PERL5LIB=$PERL5LIB:lib perl fake_data.pl --how-many 100 --reset-data
```
