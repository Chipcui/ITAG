package CXGN::ITAG::Pipeline::Analysis::tomato_bacs;
use strict;
use warnings;

use autodie ':all';

use base qw/CXGN::ITAG::Pipeline::Analysis::blat_base/;

use List::MoreUtils 'uniq';

use CXGN::Tools::Wget qw/ wget_filter /;

sub gff3_source {
    'ITAG_tomato_bacs'
}

sub query_file {
    my $class = shift;
    return wget_filter(
        'ftp://ftp.solgenomics.net/genomes/Solanum_lycopersicum/bacs/curr/bacs.seq',
            => $class->cluster_temp('tomato_bacs.fasta'),
       );
}

# munge gff3 to add aliases to the attrs
sub munge_gff3 {
    my ( $class, $args, $gff3, $attrs ) = @_;
    my $aliases = $class->_get_aliases( $attrs{Name} );
    if( @$aliases ) {
        $attrs{Name} = shift @$aliases;
        $attrs{Alias} = join ',', @$aliases;
    }
}

sub _accessions_file {
    my ( $class ) = @_;
    return wget_filter(
        'ftp://ftp.solgenomics.net/genomes/Solanum_lycopersicum/bacs/curr/bacs_accessions.txt'
            => $class->local_temp('accession_list.txt'),
       );
}

my %deflines;
sub _load_deflines {
    my ( $class, $seqfile ) = @_;
    open my $s, '<', $seqfile;
    while( my $l = <$s> ) {
        my ( $bac, $defline ) = $l =~ /^>(\S+)\s*(.+)/
            or next;
        chomp $defline;
    }
}
sub _get_defline {
    my ( $class, $bac ) = @_;
    return $deflines{$bac};
}

my %aliases;
sub _load_aliases {
    my ( $class ) = @_;
    my $accessions = $class->_accessions_file;

    open my $accs, '<', $accessions;
    while( my $l = <$accs> ) {
        chomp $l;
        my ( $bac, $acc ) = split /\s+/, $l;
        ( my $unv_bac = $bac ) =~ s/(\.\d+)+$//;
        ( my $unv_acc = $acc ) =~ s/(\.\d+)+$//;
        my @aliases = uniq $bac, $unv_bac,  $acc, $unv_acc;
        $aliases{$bac} = \@aliases;
    }
}
sub _get_aliases {
    my ( $class, $bacname ) = @_;
    return $aliases{$bacname} || [];
}

1;
