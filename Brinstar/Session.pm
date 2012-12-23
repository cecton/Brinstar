use 5.006;
use strict;
use warnings;

package Brinstar::Session;

use Data::Dumper;
use Data::UUID::MT;
use base 'Exporter';

use Brinstar::Cookies;

our @EXPORT_OK = qw/uuid/;

our $default_cookie_name = 'Brinstar::Session';
our $create_func = sub {
        die shift()." error: No create function defined, can not continue.\n"
    };
our $write_func = sub {
        die shift()." error: No write function defined, can not continue.\n"
    };
our $get_func = sub {
        die shift()." error: No get function defined, can not continue.\n"
    };
our $clean_func;
our $delete_func;
my %autosave;

my $ug = Data::UUID::MT->new(version => 4);

sub uuid() { $ug->create_string() }

sub new
{
    my $class = shift;
    $class->get(@_) or $class->create(@_);
}

sub create
{
    my $class = shift;
    my %o = (name => $default_cookie_name, autosave => 1, @_);
    my($uuid,$session) = &$create_func($class);
    $autosave{"$session"} = 1 if $o{autosave};
    Brinstar::Cookies->set($o{name} => $uuid);
    $session;
}

sub get
{
    my $class = shift;
    my %o = (name => $default_cookie_name, autosave => 1, @_);
    my $uuid = Brinstar::Cookies->get($o{name});
    return undef unless $uuid;
    my $session = &$get_func($class, $uuid);
    $autosave{"$session"} = 1 if $o{autosave} and $session;
    $session;
}

sub write
{
    my $self = shift;
    &$write_func(ref($self), $self);
}

sub DESTROY
{
    my $self = shift;
    $self->write if delete $autosave{"$self"};
    &$clean_func(ref($self), $self) if $clean_func;
}

sub delete
{
    my $self = shift;
    delete $autosave{"$self"};
    &$delete_func(ref($self), $self) if $delete_func;
}

1;
