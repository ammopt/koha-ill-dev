package KohaFactory::Circulation;

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
use Koha::DateUtils qw( dt_from_string );

use C4::Context;

use base qw(Koha::Object);

use Koha::Checkout;
use Koha::Checkouts;
use Koha::Libraries;
use Koha::Patrons;
use Koha::Items;
use C4::Circulation qw( _GetCircControlBranch GetLoanLength );

=head1 NAME

KohaFactory::Circulation

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
        Koha::Checkouts->search()->delete;
    }

    my $sth   = C4::Context->dbh;
    my $faker = Data::Faker->new();

    my @items = Koha::Items->search( { itemnumber => { '!=', undef } } )
      ->get_column('itemnumber');

    my $borrowernumber = 51; # make this an option later

    # Create issues
    for ( my $i = 0 ; $i < $this_many ; $i++ ) {

        # Progress indication
        my $percent = $i * 100 / $this_many;
        system 'printf "#####  '
          . $i . '/'
          . $this_many . ' ('
          . $percent
          . '%%)\r"';

        # Get current issues for this user
        my @issues_itemnumbers =
          Koha::Checkouts->search( { borrowernumber => 51 } )
            ->get_column('itemnumber');

        # Prepare some random data
        my $random_itemnumber = $items[ int( rand( scalar @items ) ) ];

        # Check if this new itemnumber has already been checked out to this user
        while( grep( /^$random_itemnumber$/, @issues_itemnumbers ) ){
            $random_itemnumber = $items[ int( rand( scalar @items ) ) ];
        }

        # Get circulation control branch
        my $patron = Koha::Patrons->find(51);
        my $item = Koha::Items->find($random_itemnumber);
        my $branchcode = _GetCircControlBranch( $item->unblessed, $patron->unblessed);

        # Set loan length
        my $loan_length = GetLoanLength( $patron->{'categorycode'},
            $item->effective_itemtype, $branchcode );

        my $date_due =
          dt_from_string()->add( days => $loan_length->{renewalperiod} );
        $date_due->set_hour(23);
        $date_due->set_minute(59);
        my $datedue = $date_due;
        $datedue->truncate( to => 'minute' );

        my $args = {
            borrowernumber => $borrowernumber,
            itemnumber => $random_itemnumber,
            issuedate  => dt_from_string(),
            date_due   => $datedue,
            branchcode => $branchcode,
            auto_renew => ( rand >= 0.5 ? 1 : 0 ),
        };

        # Create fake issue
        my $new_obj = Koha::Checkout->new($args)->store();
    }
}

=head2 Internal methods

=head3 _type

=cut

sub _type {
    return 'Circulation';
}

1;
