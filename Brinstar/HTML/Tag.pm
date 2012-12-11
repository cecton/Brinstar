package Brinstar::HTML::Tag;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(all);

use Scalar::Util 'blessed';

use overload
    '""' => \&str,
    '@{}' => sub {$_[0]->{_children}},
    'nomethod' => sub {$_[0]};

sub all { map {ref $_ eq 'ARRAY' ? @$_ : $_} @_ } 

sub new {
    my $class = shift;
    my $self = {
            _parent => undef,
            _children => [],
            _booleans => {},
            _flags => {},
            _neveralone => 0,
        };
    for(@_) {
        if( ref $_ eq 'HASH' ) {
            while( my($k,$v) = each %$_ ) {
                if( exists $self->{$k} and $k eq 'class' ) {
                    $self->{$k} = [(ref $self->{$k} eq 'ARRAY' ? @{$self->{$k}} : $self->{$k}), $v];
                } else { $self->{$k} = $v }
            }
        } else {
            if ( (my $a = blessed($_) || '') eq $class ) {
                $_->{_parent} = $self;
            }
            push @{$self->{_children}}, $_;
        }
    }
    bless $self, $class;
}

## Get all values of ref if its a ref, remove not defined, get strings and remove empty strings
sub _compute { defined $_[1] ? grep {$_} map {"$_"} grep {defined $_} all $_[1] : () }

sub str {
    my $self = shift;
    my $tag = $self->{_tag};
    my $attributes = '';
    for my $attr (grep {defined $self->{$_} and not /^_/} keys %$self ) {
        if( $attr eq 'style' and ref $self->{$attr} eq 'HASH' ) {
            my $style = '';
            for my $k ( sort keys %{$self->{$attr}} ) {
                local $_ = $k;
                s/[A-Z]/'-'.lc $&/ge;
                $style .= " $_: $self->{$attr}->{$k};";
            }
            $self->{$attr} = substr($style,1) if $style;
        }
        if( $self->{_booleans}->{$attr} ) {
            $attributes .= " $attr=\"".($self->{$attr} ? 'on' : 'off').'"';
        } elsif( $self->{_flags}->{$attr} ) {
            $attributes .= " $attr" if $self->{$attr};
        } else {
            $attributes .= " $attr=\"".join(' ', grep {$_} all($self->{$attr})).'"';
        }
    }
    my $r = '<'.$tag.$attributes;
    my @children = $self->_compute($self->{_children});
    if( @children or $self->{_neveralone} ) {
        $r .= '>';
        $r .= $_ for @children;
        $r .= "</$tag>";
    } else {
        $r .= '/>';
    }
}

1;
