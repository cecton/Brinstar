package Brinstar::HTML::Cookies;

use strict;
use warnings;

our %cookies;
our @saved_cookies;
our $read;

sub read {
    for my $http_cookie(@_ ? @_ : $ENV{HTTP_COOKIE}) {
        if( $http_cookie ) {
            for( split /\s*;\s*/, $http_cookie ) {
                if( /^([^=]+)=(.+)$/ ) { $cookies{$1} ||= $2 }
                else { warn "Unable to read cookie in HTTP header: $_\n" }
            }
        }
    }
    $read = 1;
    %cookies;
}

sub get {
    &read unless $read;
    @_ ? @cookies{@_} : %cookies;
}

sub set {
    my(%new) = @_;
    &read unless $read;
    return unless %new;
    %cookies = (%cookies, %new);
    push @saved_cookies, keys %new;
}

1;
