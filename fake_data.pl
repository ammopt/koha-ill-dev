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

use Getopt::Long qw( GetOptions );

use KohaFactory::ILL;
use KohaFactory::ERM;
use KohaFactory::Circulation;

my $sth = C4::Context->dbh;
our $faker = Data::Faker->new();
my $fake_text = Text::Lorem->new();

# Command line option values
my $reset_data         = 0;
my $how_many = 10;

my $options = GetOptions(

    # 'h|help'          => \$get_help,
    'reset-data' => \$reset_data,
    'how-many=s' => \$how_many,
);

=Arguments
reset_data - erase current data before creating new fake data
how_many - number of fake entity instances to create
=cut

KohaFactory::ILL->new->create( $how_many, $reset_data );
# KohaFactory::ERM->new->create( $how_many, $reset_data );

