#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use C4::Context;
use XML::Simple;
use LWP::Simple;
use C4::Biblio;
use MARC::File::USMARC;
use utf8;
use YAML;
use open qw/ :std :utf8 /;

my $url = 'http://www.reseau-mirabel.info/devel/rest.php?suppr';

my $docs = get $url;
my $xmlsimple = XML::Simple->new();
my $data = $xmlsimple->XMLin($docs);

#print Data::Dumper::Dumper( $data );

# Delete non-existent services from biblio
print "Supprime les services qui n'existent plus\n";
my $biblios = get_biblios();
my @to_del;
push @to_del, $_ for keys %{ $data->{service} };
print Data::Dumper::Dumper( \@to_del );

foreach my $biblio ( @$biblios ) {
    my $biblionumber = $biblio->{biblionumber};
    my $record = GetMarcBiblio( $biblionumber );

    my $countfield = 0;
    foreach my $field ( $record->field(qw/857 388 389 398/) ) {
	my $id = $field->subfield('3');
	if ( $id && in_array( \@to_del, $id) ) {
	    $countfield++;
	    $record->delete_field( $field );
	}
    }
    if ( $countfield ) {
	my $fmk = GetFrameworkCode( $biblionumber );
	ModBiblioMarc( $record, $biblionumber, $fmk );
    }
    print "$biblionumber: $countfield deleted\n";
}
print "Terminé\n";

sub get_biblios {
    my $dbh = C4::Context->dbh;
    my $query = "SELECT biblionumber from biblio";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $result = $sth->fetchall_arrayref({});
    return $result;
}

sub in_array {
    my ($arr,$search_for) = @_;
    my %items = map {$_ => 1} @$arr;
    return (exists($items{$search_for}))?1:0;
}

