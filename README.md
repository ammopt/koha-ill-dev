# koha-fake-data
Tool to create fake data in [Koha](https://koha-community.org/).

Currently requires pre-existing libraries, patrons and biblio records. Use in [koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)

Currently only creates fake data for ILL requests.

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
