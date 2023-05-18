package Koha::Factory::ERM;

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

use Koha::ERM::Agreement;
use Koha::ERM::Agreements;
use Koha::Acquisition::Bookseller;
use Koha::Acquisition::Booksellers;

=head1 NAME

Koha::Factory::ERM

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
        Koha::ERM::Agreements->search()->delete;
    }

    my $sth       = C4::Context->dbh;
    my $faker     = Data::Faker->new();
    my $fake_text = Text::Lorem->new();

    my @vendors =
        Koha::Acquisition::Booksellers->search( { id => { '!=', undef } } )
      ->get_column('id');

    # Create agreements
    for ( my $i = 0 ; $i < $this_many ; $i++ ) {

        # Prepare some random data
        my $random_vendor =
        $vendors[ int( rand( scalar @vendors ) ) ];

        my $args = {
            vendor_id => $random_vendor,
            name => $faker->name,
            #TODO: Have a random number of sentences?
            description => $fake_text->sentences(1),
# TODO: Get values from ERM_AGREEMENT_STATUS AV
            status => 'active'
        };

        # Create agreement
        my $new_obj = Koha::ERM::Agreement->new($args)->store();
        my $new_id  = $new_obj->agreement_id;

    }
}

=head2 Internal methods

=head3 _type

=cut

sub _type {
    return 'ERM';
}

1;
