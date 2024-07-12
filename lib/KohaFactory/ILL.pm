package KohaFactory::ILL;

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

use Koha::ILL::Request;
use Koha::ILL::Requests;
use Koha::ILL::Request::Attributes;
use Koha::ILL::Comment;
use Koha::ILL::Comments;
use Koha::Libraries;
use Koha::Patrons;
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
        Koha::ILL::Requests->search()->delete;
        Koha::ILL::Request::Attributes->search()->delete;
        Koha::ILL::Comments->search()->delete;
    }

    my $sth       = C4::Context->dbh;
    my $faker     = Data::Faker->new();
    my $fake_text = Text::Lorem->new();

    my @branchcodes = Koha::Libraries->search( { branchcode => { '!=', undef } } )->get_column('branchcode');
    my @borrowers   = Koha::Patrons->search( { borrowernumber => { '!=', undef } } )->get_column('borrowernumber');
    my @biblios     = Koha::Biblios->search( { biblionumber   => { '!=', undef } } )->get_column('biblionumber');

    my @backends = $self->backends;

    # Create ILL requests
    for ( my $i = 0 ; $i < $this_many ; $i++ ) {

        # Progress indication
        my $percent = $i * 100 / $this_many;
        system 'printf "#####  ' . $i . '/' . $this_many . ' (' . $percent . '%%)\r"';

        # Prepare some random data
        my $random_backend      = $backends[ rand @backends ];
        my $random_backend_name = $random_backend->{name};

        my $statuses      = $random_backend->{statuses};
        my $random_status = $statuses->[ int( rand( scalar @$statuses ) ) ];

        my $random_branchcode =
            $branchcodes[ int( rand( scalar @branchcodes ) ) ];
        my $random_borrowernumber =
            $borrowers[ int( rand( scalar @borrowers ) ) ];
        my $random_biblionumber = $biblios[ int( rand( scalar @biblios ) ) ];

        my $args = {
            borrowernumber => $random_borrowernumber,
            rand >= 0.5 ? ( biblio_id => $random_biblionumber ) : (),

            # due_date =>
            branchcode => $random_branchcode,
            status     => $random_status,

            # status_alias =>
            placed => $faker->sqldate,
            rand >= 0.5 ? ( replied => $faker->sqldate ) : (),

            # updated => //auto-generated
            rand >= 0.5 ? ( completed => $faker->sqldate ) : (),

            # medium =>  //is this even being used
            rand >= 0.5 ? ( accessurl => $faker->domain_name )          : (),
            rand >= 0.5 ? ( cost      => sprintf( "%.2f", rand(100) ) ) : (),
            rand >= 0.5
            ? ( price_paid => sprintf( "%.2f", rand(100) ) )
            : (),
            rand >= 0.5 ? ( notesopac  => $fake_text->sentences(1) ) : (),
            rand >= 0.5 ? ( notesstaff => $fake_text->sentences(1) ) : (),
            rand >= 0.5 ? ( orderid    => $faker->phone_number )     : (),
            backend => $random_backend_name
        };

        ## TODO: IF BACKEND ALLOWS FOR CREATE_API, USE THAT TO CREATE REQUEST INSTEAD

        # my $request_load = Koha::Illrequest->new->load_backend($random_backend_name);
        # my $create_api = $request_load->_backend->capabilities('create_api');

        # my $new_id = undef;
        # if ( !$create_api ) {
        #     warn $random_backend_name.' does not allow for request creation through REST API';
        #     warn 'using standard method';
        #     my $new_obj = Koha::Illrequest->new($args)->store();
        #     $new_id = $new_obj->illrequest_id;
        # }else {
        #     my $create_result = &{$create_api}( $args, $request_load );
        #     $new_id        = $create_result->illrequest_id;
        # }

        # Create fake ILL request
        my $new_obj = Koha::ILL::Request->new($args)->store();
        my $new_id  = $new_obj->illrequest_id;

        # Create related illrequestattributes
        my @illrequestattributes = $self->illrequestattributes($faker);
        foreach my $attribute (@illrequestattributes) {
            my $random_type;
            if ( $attribute->{type} eq "type" ) {
                my $types = $attribute->{value};
                $random_type = $types->[ int( rand( scalar @$types ) ) ];
            }

            if ( rand >= 0.5 ) {
                Koha::ILL::Request::Attribute->new(
                    {
                        illrequest_id => $new_id,
                        type          => $attribute->{type},
                        backend       => $random_backend_name,
                        $attribute->{type} eq "type"
                        ? ( value => $random_type )
                        : ( value => $attribute->{value} )
                    }
                )->store();
            }
        }
    }

    # Create related illcomments
    my @requests =
      Koha::ILL::Requests->search( { illrequest_id => { '!=', undef } } )
      ->get_column('illrequest_id');
    for ( my $i = 0 ; $i < $this_many ; $i++ ) {
        my $random_ill_request_id =
            $requests[ int( rand( scalar @requests ) ) ];
        my $random_borrowernumber =
            $borrowers[ int( rand( scalar @borrowers ) ) ];

        if ( rand >= 0.5 ) {
            Koha::ILL::Comment->new(
                {
                    illrequest_id  => $random_ill_request_id,
                    borrowernumber => $random_borrowernumber,
                    comment        => $fake_text->paragraphs(1),
                    timestamp      => $faker->sqldate
                }
            )->store();
        }
    }
}

=head3 illrequestattributes

Get a set of fixed illrequestattributes types with random values
    
=cut

sub illrequestattributes {
    my ( $self, $faker ) = @_;

    return (
        {
            type  => "type",
            value => [ "article", "journal", "book", "thesis", "conference", "other" ]
        },
        {
            type  => "author",
            value => $faker->name
        },
        {
            type  => "article_title",
            value => $faker->company
        },
        {
            type  => "title",
            value => $faker->company
        },
        {
            type  => "pages",
            value => int( 60 + rand( 600 - 60 ) )
        },
        {
            type  => "issue",
            value => int( rand(10000) )
        },
        {
            type  => "volume",
            value => int( rand(100) )
        },
        {
            type  => "year",
            value => int( 1877 + rand( 2023 - 1877 ) )
        },
    );
}

=head3 backends

Get installed backends and their respective status_graph graphs
    
=cut

sub backends {
    my ($self) = @_;

    my @backends_array = ();

    # Get backend_dir
    my $backend_dir = Koha::ILL::Request->new->_config->backend_dir;
    # Iterate on installed backends
    opendir( my $DIR, $backend_dir );
    while ( my $entry = readdir $DIR ) {
        next unless -d $backend_dir . '/' . $entry;
        next if $entry eq '.' or $entry eq '..';

        #Load the backend
        my $backend_obj = Koha::ILL::Request->new->load_backend($entry);

        #Get the status_graph_reunion
        my $status_graph = $backend_obj->capabilities;
        my @statuses     = keys %{$status_graph};

        push( @backends_array, { name => $entry, statuses => \@statuses } );
    }

    return @backends_array;
}

=head2 Internal methods

=head3 _type

=cut

sub _type {
    return 'ILL';
}

1;
