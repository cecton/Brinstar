use 5.006;
use strict;
use warnings;

package Brinstar::HTTP::Serializer;

use Carp;

use base 'Exporter';
our(@EXPORT_OK) = qw(query_string serialize unserialize);
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
    );

sub query_string()
{
    $ENV{QUERY_STRING} || serialize(map {m/^([^=]+)=(.+)$/
        ? ($1 => $2)
        : die "Cannot convert argument $_ to key=value parameter!\n"} @ARGV)
}

sub serialize
{
    my %data = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    for(values %data) {
        s/[^a-z0-9_ ]/sprintf('%%%x', ord($&))/gie;
        s/ /+/g;
    }
    join('&', map {"$_=$data{$_}"} grep {m/=/
        ? do {carp "Cannot serialize key `$_' and value `$data{$_}'!"; 0}
        : $_} keys %data)
}

sub unserialize {
    my %r;
    for( split /&/, shift() ) {
        s/\+/ /g;
        s/%([0-9a-f][0-9a-f])/chr(hex($1))/gei;
        if( /^([^=]+)=(.+)$/ ) {
            my($k,$v) = ($1,$2);
            $r{$k} = $v;
        }
        else { $r{$_} = 1 }
    }
    %r
}

1;
