#!/usr/bin/perl
#
# Copyright 2023 PTFS-Europe
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use Data::Faker qw(Company DateTime Internet Name PhoneNumber StreetAddress);
use Text::Lorem;
use POSIX qw(strftime);
use Getopt::Long qw( GetOptions );

use C4::Context;

use Koha::Illrequest;
use Koha::Illrequests;
use Koha::Illrequestattributes;
use Koha::Illcomment;
use Koha::Libraries;
use Koha::Patrons;
use Koha::Biblios;

my $sth = C4::Context->dbh;
our $faker = Data::Faker->new();
my $fake_text = Text::Lorem->new();

# Command line option values
my $reset_data = 0;
my $number_of_requests = 10;
my $number_of_comments = 10;

my $options = GetOptions(
    # 'h|help'          => \$get_help,
    'reset-data'        => \$reset_data,
    'requests=s'        => \$number_of_requests,
    'comments=s'        => \$number_of_comments,
);

=Arguments
reset_data - erase current data before creating new fake data
number_of_requests - number of fake requests to create
number_of_comments - number of fake comments to create
TODO: Get these from the command line
=cut

if ( $reset_data ) {
    Koha::Illrequests->search()->delete;
    Koha::Illrequestattributes->search()->delete;
}

=Datasets
TODO: Get these from the database (ideally?) 
=cut

my @backends = (
    {
        name => "BLDSS",
        statuses => ["RET", "CHK", "COMP", "CANCREQ", "QUEUED", "REQREV", "GENREQ", "REQ", "NEW", "EDITITEM", "STAT", "MIG"]
    },
    {
        name => "FreeForm",
        statuses => ["RET", "CHK", "COMP", "CANCREQ", "QUEUED", "REQREV", "GENREQ", "REQ", "NEW", "EDITITEM", "MIG"]
    },
    {
        name => "ReprintsDesk",
        statuses => ["RET", "CHK", "COMP", "CANCREQ", "QUEUED", "REQREV", "GENREQ", "REQ", "NEW", "SOURCE", "CIT", "ERROR", "READY"]
    },
    {
        name => "RapidILL",
        statuses => ["RET", "CHK", "COMP", "CANCREQ", "QUEUED", "REQREV", "GENREQ", "REQ", "NEW", "EDITITEM", "MIG"]
    }
);

sub illrequestattributes {
    return (
        {
            type => "type",
            value => ["article", "journal", "book", "thesis", "conference", "other"]
        },
        {
            type => "author",
            value => $faker->name
        },
        {
            type => "article_title",
            value => $faker->company
        },
        {
            type => "title",
            value => $faker->company
        },
        {
            type => "pages",
            value => int(60+rand(600-60))
        },
        {
            type => "issue",
            value => int(rand(10000))
        },
        {
            type => "volume",
            value => int(rand(100))
        },
        {
            type => "year",
            value => int(1877+rand(2023-1877))
        },
    )
}

=Fake data creation
Get some data from the database
Prepare some random data (random branchcode, random biblio, random borrower)
Create $number_of_requests requests

=cut

my @branchcodes = Koha::Libraries->search({branchcode => { '!=', undef }})->get_column('branchcode');
my @borrowers = Koha::Patrons->search({borrowernumber => { '!=', undef }})->get_column('borrowernumber');
my @biblios = Koha::Biblios->search({biblionumber => { '!=', undef }})->get_column('biblionumber');

for( my $i = 0; $i < $number_of_requests; $i++ ) {

    # Prepare some random data
    my $random_backend = $backends[rand @backends];
    my $random_backend_name = $random_backend->{name};

    my $statuses = $random_backend->{statuses};
    my $random_status = $statuses->[int(rand(scalar @$statuses))];

    my $random_branchcode = $branchcodes[int(rand(scalar @branchcodes))];
    my $random_borrowernumber = $borrowers[int(rand(scalar @borrowers))];
    my $random_biblionumber = $biblios[int(rand(scalar @biblios))];

    # Create fake data
    my $request_id = Koha::Illrequest->new(
        {
            borrowernumber => $random_borrowernumber,
            rand >= 0.5 ? (biblio_id => $random_biblionumber):(),
            # due_date =>
            branchcode => $random_branchcode,
            status => $random_status,
            # status_alias =>
            placed => $faker->sqldate,
            rand >= 0.5 ? (replied => $faker->sqldate):(),
            # updated => //auto-generated
            rand >= 0.5 ? (completed => $faker->sqldate):(),
            # medium =>  //is this even being used
            rand >= 0.5 ? (accessurl => $faker->domain_name):(),
            rand >= 0.5 ? (cost => sprintf("%.2f", rand(100))):(),
            rand >= 0.5 ? (price_paid => sprintf("%.2f", rand(100))):(),
            rand >= 0.5 ? (notesopac => $fake_text->sentences(1)):(),
            rand >= 0.5 ? (notesstaff => $fake_text->sentences(1)):(),
            rand >= 0.5 ? (orderid => $faker->phone_number):(),
            backend => $random_backend_name
        }
    )->store();

    # Create related illrequestattributes
    my @illrequestattributes = illrequestattributes;
    foreach my $attribute ( @illrequestattributes ) {
        my $random_type;
        if ( $attribute->{type} eq "type"  ) {
            my $types = $attribute->{value};
            $random_type = $types->[int(rand(scalar @$types))];
        }

        if ( rand >= 0.5 ) {
            Koha::Illrequestattribute->new(
            {
                illrequest_id => $request_id->illrequest_id,
                type => $attribute->{type},
                $attribute->{type} eq "type" 
                    ? (
                        value => $random_type
                    )
                    : 
                    (
                        value => $attribute->{value}
                    )
            }
            )->store();
        }
	}
}

# # Create related illcomments
my @requests = Koha::Illrequests->search({illrequest_id => { '!=', undef }})->get_column('illrequest_id');
for( my $i = 0; $i < $number_of_comments; $i++ ) {
    my $random_ill_request_id = $requests[int(rand(scalar @requests))];
    my $random_borrowernumber = $borrowers[int(rand(scalar @borrowers))];

    if ( rand >= 0.5 ) {
        Koha::Illcomment->new(
        {
            illrequest_id => $random_ill_request_id,
            borrowernumber => $random_borrowernumber,
            comment => $fake_text->paragraphs(1),
            timestamp => $faker->sqldate
        }
        )->store();
    }
}
