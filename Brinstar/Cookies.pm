use 5.006;
use strict;
use warnings;

package Brinstar::Cookies;

our %cookies;
our @saved_cookies;
our $read;

sub new
{
    my $class = shift;
    %cookies = ($class->read, @_);
    bless \%cookies, $class;
}

sub read
{
    my $self = shift;
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

sub get
{
    my $self = shift;
    $self->read unless $read;
    @_ ? @cookies{@_} : %cookies;
}

sub set
{
    my $self = shift;
    my(%new) = @_;
    $self->read unless $read;
    return unless %new;
    %cookies = (%cookies, %new);
    push @saved_cookies, keys %new;
}

1;
