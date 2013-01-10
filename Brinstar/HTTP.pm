use 5.006;
use strict;
use warnings;

package Brinstar::HTTP;

use Brinstar::HTTP::Serializer qw(query_string serialize unserialize);
use Brinstar::HTTP::Params qw(params params_get params_post);
use Brinstar::HTTP::Cookies qw(set_cookies get_cookies);
use Carp;

use base 'Exporter';
our(@EXPORT_OK) = qw(
        query_string serialize unserialize
        set_cookies get_cookies
        params params_get params_post
        http_header
    );
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
        'serializer' => [qw(query_string serialize unserialize)],
        'params' => [qw(params_get params_post)],
        'cookies' => [qw(set_cookies get_cookies)],
    );

my %HEADER_TAGS = (
        type => 'Content-Type',
        lang => 'Content-Language',
        cookies => 'Set-Cookie',
        nocookie => '_nocookie',
    );

sub http_header
{
    my %o = (type => 'text/html; charset=UTF-8');
    if( @_ == 1 ) { $o{type} = shift }
    elsif( @_ == 2 and $_[0] =~ /\// and $_[1] =~ /^\d+/ ) {
        %o = (%o, type => $_[0], status => $_[1]);
    } else { %o = (%o, @_) }
    # Redirection
    if( $_ = delete $o{redirect} ) {
        $o{Status} = "302 Found";
        $o{Location} = $_;
    }
    # Clean up parameters
    while( my($k,$v) = each %o ) { next if $k =~ /^_/;
        if( ref $v eq 'ARRAY' ) {
            @$v = grep {$_} @$v;
            unless( @$v ) { delete $o{$k}; next }
        } elsif( ref $v eq 'HASH' ) {
            unless( %$v ) { delete $o{$k}; next }
        } else {
            unless( defined $v and $k ) { delete $o{$k}; next }
        }
        local $_ = $HEADER_TAGS{$k};
        s/\b[a-z]/uc $&/ge if not $_ and $_ = $k;
        $o{$_} = delete $o{$k} if $_ ne $k;
    }
    # Special behavior for content type and charset
    $o{'Content-Type'} =~ s/(;\s*)?charset=[^;]+|$/; charset=$o{Charset}/
        if $o{Charset} and $o{'Content-Type'} =~ /text/;
    delete $o{Charset};
    # Cookies
    if( $o{_nocookie} ) { delete $o{'Set-Cookie'} }
    else {
        my %cookies;
        %cookies = get_cookies()
            if not defined $o{'Set-Cookie'} or ref $o{'Set-Cookie'} ne 'HASH';
        %cookies = (%cookies, %{$o{'Set-Cookie'}})
            if ref $o{'Set-Cookie'} eq 'HASH';
        $o{'Set-Cookie'} = join('; ',
            (map {"$_=$cookies{$_}"} keys %cookies),
            'path=/') if %cookies;
    }
    # Special behavior for content language
    $o{'Content-Language'} ||= $ENV{LANGUAGE} || $ENV{LANG} if $ENV{LANGUAGE};
    #TODO dont know how language show multiple languages...
    #if( ref $o{'Content-Language'} eq 'ARRAY' ) {
    #    $o{'Content-Language'} = join(', ', @{$o{'Content-Language'}});
    #}
    ## Build header
    my $r = '';
    values %o;
    while( my($k,$v) = each %o ) { next if $k =~ /^_/;
        if( ref($v) =~ m/^[A-Z_]+$/ ) {
            carp "Can't handle HTTP header parameter $k (ref type is "
                 .ref($v).")!";
            next;
        }
        $r .= "$k: $v\n";
    }
    "$r\n"
}

1;
