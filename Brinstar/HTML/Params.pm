package Brinstar::HTML::Params;

use strict;
use warnings;

use Brinstar::HTML 'query_string';

our $read;
our %gets;
our %posts;

sub new { bless {}, $_[0] }

sub read {
    #warn "read=".($read || 'no');
    ## Read parameters
    for( split /&/, query_string ) {
        s/%([0-9a-f][0-9a-f])/chr(hex($1))/gei;
        if( /^([^=]+)=(.+)$/ ) {
            my($k,$v) = ($1,$2);
            $gets{$k} = $v;
        }
        else { $gets{$_} = 1 }
    }
    ## Read posted values
    if( $ENV{CONTENT_TYPE} and $ENV{CONTENT_TYPE} =~ m/(\S+)\s*;\s*boundary=(\S+)/ ) {
        #my $content_type = $1; ##NOT USED
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

sub get {
    &read unless $read;
    @_ > 1 ? map {$posts{$_} || $gets{$_}} @_ : @_ == 1 ? $posts{$_[0]} || $gets{$_[0]} : (%gets, %posts)
}

sub gets {
    &read unless $read;
    @_ > 1 ? map {$gets{$_}} @_ : @_ == 1 ? $gets{$_[0]} : %gets
}

sub posts {
    &read unless $read;
    @_ > 1 ? map {$posts{$_}} @_ : @_ == 1 ? $posts{$_[0]} : %posts
}

1;
