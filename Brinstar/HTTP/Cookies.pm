use 5.006;
use strict;
use warnings;

package Brinstar::HTTP::Cookies;

use base 'Exporter';
our(@EXPORT_OK) = qw(get_cookies set_cookies);
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
    );

our %cookies;
my $read;

sub read()
{
    for my $http_cookie ($ENV{HTTP_COOKIE}) {
        next unless $http_cookie;
        for( split /\s*;\s*/, $http_cookie ) {
            if( /^([^=]+)=(.+)$/ ) { $cookies{$1} ||= $2 }
            else { warn "Unable to read cookie in HTTP header: $_\n" }
        }
    }
    $read = 1;
    \%cookies;
}

sub get_cookies
{
    &read unless $read;
    @_ ? @cookies{@_} : %cookies;
}

sub set_cookies
{
    &read unless $read;
    return unless @_;
    %cookies = (%cookies, @_);
}

1;
