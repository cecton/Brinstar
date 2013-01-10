use 5.006;
use strict;
use warnings;

package Brinstar::HTTP::Params;

use Brinstar::HTTP::Serializer ':all';

use base 'Exporter';
our(@EXPORT_OK) = qw(params params_get params_post);
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
    );

our $read;
our %gets;
our %posts;

sub read()
{
    # Read parameters
    %gets = unserialize(query_string);
    # Read posted values
    if( $ENV{CONTENT_TYPE} and
            $ENV{CONTENT_TYPE} eq 'application/x-www-form-urlencoded' ) {
        local $/;
        %posts = unserialize(<STDIN>);
    } elsif( $ENV{CONTENT_TYPE} and
            $ENV{CONTENT_TYPE} =~ m/(\S+)\s*;\s*boundary=(\S+)/ ) {
        #my $content_type = $1; # NOT USED
        local $/ = "--$2";
        while( <STDIN> ) {
                $_ = substr($_, 0, length($_) - length($/));
                my %header;
                if( s/^(.+|\v(?=[^\v]))+\v\v+//g ) {
                    for( split /\v/,$1 ) {
                        if( /^([^:]+)\s*:\s*(.+)/ ) { $header{$1} = $2 }
                        else { warn "Invalid HTTP header: $_\n" }
                    }
                }
                s/^\s+|\s+$//g;
                next unless $_;
                if( $header{'Content-Disposition'} =~ m/name="\K[^"]+/ ) {
                    $posts{$&} = $_;
                }
        }
    }
    ## Read flag
    $read = 1;
}

sub params
{
    &read unless $read;
    @_ > 1 ? map {$posts{$_} || $gets{$_}} @_ : @_ == 1
        ? $posts{$_[0]} || $gets{$_[0]}
        : (%gets, %posts)
}

sub params_get
{
    &read unless $read;
    @_ > 1 ? map {$gets{$_}} @_ : @_ == 1 ? $gets{$_[0]} : %gets
}

sub params_post
{
    &read unless $read;
    @_ > 1 ? map {$posts{$_}} @_ : @_ == 1 ? $posts{$_[0]} : %posts
}

1;
