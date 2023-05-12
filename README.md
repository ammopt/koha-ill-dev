# koha-ill-dev
Tools to help [Koha](https://koha-community.org/) ILL development using [koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)

## Start ILL in k-t-d
Copy **start-ill-dev.sh** inside the docker container and run.

```sh
sh start-ill-dev.sh
```

This will:
* Install the [FreeForm](https://github.com/PTFS-Europe/koha-ill-freeform) backend if that doesn't exist. 
* Update backend_directory config in koha-conf.xml
* Enable the ILLModule system preference

# Creating fake data
Currently requires pre-existing libraries, patrons and biblio records, these should all exist out of the box using [k-t-d](https://gitlab.com/koha-community/koha-testing-docker)

## Dependencies
* Data::Faker
* Text::Lorem

## ill_data.pl options
* **reset_data** - erase current data before creating new fake data (recommended)
* **requests** - number of fake ILL requests to create
* **comments** - number of fake ILL comments to create (these are get related to the fake requests randomly)

## Usage (_dev only_)

Generate 100 fake ILL requests and 100 fake comments:

```sh
perl ill_data.pl --requests 100 --comments 100 --reset-data
```
