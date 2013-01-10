use 5.006;
use strict;
use warnings;

package Brinstar::HTML;

use Brinstar::HTML::Tag qw/all/;
use Carp;

my @known_tags = qw(
        html head img script form hidden checkbox
        submit button Select textarea input password
        body a p h1 h2 h3 div span pre ul li dl dt dd label
    );

use base 'Exporter';
our(@EXPORT_OK) = (qw/all Document br/, @known_tags);
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
    );

sub Document { join('', "<!DOCTYPE html>\n", @_) }

sub br() { "<br />" }

my %specificities = (
        input => {
                _booleans => {
                    'disabled' => 1,
                },
            },
        map {$_ => {_neveralone => 1}} qw(
                div span
                dl dt dd
            )
    );

foreach my $tag (@known_tags)
{   no strict 'refs';
    *{$tag} = sub
        {
            Brinstar::HTML::Tag->new(
                {_tag => $tag, %{$specificities{$tag} or {}}},
                @_)
        }
}

1;
