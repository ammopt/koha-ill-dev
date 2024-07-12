package KohaFactory::PatronAttributes;

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

use C4::Context;

use base qw(Koha::Object);

use Try::Tiny qw( catch try );

use C4::Context;

use Koha::ILL::Request;
use Koha::ILL::Requests;
use Koha::ILL::Request::Attribute;
use Koha::ILL::Comment;
use Koha::ILL::Comments;
use Koha::Libraries;
use Koha::Patrons;
use Koha::Patron;
use Koha::Biblios;

=head1 NAME

KohaFactory::ILL

=head1 API

=head2 Class Methods

=cut

=head3 new

TODO: do 'new' later
    
=cut

# sub new {
#     my ( $class ) = @_;
#     my $self = {};
#     $self->{faker}   = Data::Faker->new();
#     bless $self, $class;
#     return $self;
# }

=head3 create

Get some data from the database Prepare some random data( random branchcode,
    random biblio, random borrower ) Create $this_many requests
    
=cut

sub create {
    my ( $self, $this_many, $reset_data ) = @_;

    if ($reset_data) {
        Koha::Patron::Attribute::Types->search()->delete;
        Koha::Patron::Attributes->search()->delete;
    }
    my $sth       = C4::Context->dbh;
    my $faker     = Data::Faker->new();
    my $fake_text = Text::Lorem->new();

    $this_many = 100 if $this_many < 100;

    my @branchcodes       = Koha::Libraries->search( { branchcode => { '!=', undef } } )->get_column('branchcode');
    my $random_branchcode = $branchcodes[ int( rand( scalar @branchcodes ) ) ];

    my @categorycodes =
        Koha::Patron::Categories->search( { categorycode => { '!=', undef } } )->get_column('categorycode');
    my $random_categorycode = $categorycodes[ int( rand( scalar @categorycodes ) ) ];

    my $new_patron_attribute_types_count = $this_many / 100;
    my $rand                             = rand;

    # Create patron attributes
    for ( my $i = 0 ; $i < $this_many ; $i++ ) {

        my $dbh = C4::Context->dbh;
        try {
            my $query =
                q|INSERT INTO borrowers ( cardnumber, userid, password, surname, categorycode, branchcode, dateexpiry, flags ) VALUES ( ?, ?, ?, 'surname patron', ?, ?, '2099-12-31', 0 )|;
            my $res = $dbh->prepare($query) or die("cannot prepeare");
            $res->execute(
                'cardnu' . $rand . $i, 'usaaaa' . $rand . $i, 'password', $random_categorycode,
                $random_branchcode
            );
        };

        # Below is trash performance wise
        # Koha::Patron->new(
        #     {
        #         cardnumber   => "$rand$i",
        #         branchcode   => $random_branchcode,
        #         categorycode => $random_categorycode,
        #     }
        # )->store;
        system 'printf "Adding patrons #####  ' . $i . '/' . $this_many . ' (' . $i * 100 / $this_many . '%%)\r"';

    }

    for ( my $i = 0 ; $i < $new_patron_attribute_types_count ; $i++ ) {
        Koha::Patron::Attribute::Type->new(
            {
                code                => "code$i",
                description         => $faker->name,
                searched_by_default => 1,
                staff_searchable    => 1
            }
        )->store();
        system 'printf "Adding patron attribute types #####  '
            . $i . '/'
            . $new_patron_attribute_types_count . ' ('
            . $i * 100 / $new_patron_attribute_types_count
            . '%%)\r"';
    }

    my @borrowers = Koha::Patrons->search( { borrowernumber => { '!=', undef } } );

    for ( my $i = 0 ; $i < $this_many ; $i++ ) {

        my @borrowers = Koha::Patrons->search( { borrowernumber => { '!=', undef } } )->get_column('borrowernumber');
        my $random_borrowernumber =
            $borrowers[ int( rand( scalar @borrowers ) ) ];

        my @attribute_types =
            Koha::Patron::Attribute::Types->search( { code => { '!=', undef } } )->get_column('code');
        my $random_attribute_type_code =
            $attribute_types[ int( rand( scalar @attribute_types ) ) ];

        try {
            Koha::Patron::Attribute->new(
                {
                    borrowernumber => $random_borrowernumber,
                    code           => $random_attribute_type_code,
                    attribute      => 'Foo'
                }
            )->store;
        };

        # Progress indication
        my $percent = $i * 100 / $this_many;
        system 'printf "Adding patron attributes #####  ' . $i . '/' . $this_many . ' (' . $percent . '%%)\r"';
    }
}

=head2 Internal methods

=head3 _type

=cut

sub _type {
    return 'PatronAttributes';
}

1;
