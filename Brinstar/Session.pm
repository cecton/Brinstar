use 5.006;
use strict;
use warnings;

package Brinstar::Session;

use Scalar::Util qw/weaken/;
use Data::Dumper;
use Data::UUID::MT;
use base 'Exporter';

use Brinstar::HTTP::Cookies ':all';

our @EXPORT_OK = qw/uuid/;

our $default_cookie_name = __PACKAGE__;
our $create_func = sub {
        die __PACKAGE__
            ." error: No create function defined, can not continue.\n"
    };
our $write_func = sub {
        die __PACKAGE__." error: No write function defined, can not continue.\n"
    };
our $get_func = sub {
        die __PACKAGE__." error: No get function defined, can not continue.\n"
    };
our $clean_func;
our $delete_func;
my %autosave;
my %sessions;
my %ids;

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
    my $session = bless {}, $class;
    my $id = &$create_func($session, $o{id});
    die "Didn't succeed session creation!\n"
        unless defined $id;
    $autosave{"$session"} = 1 if $o{autosave};
    weaken($sessions{$id} = $session);
    $ids{"$session"} = $id;
    set_cookies($o{name} => $id);
    $session;
}

sub get
{
    my $class = shift;
    my %o = (name => $default_cookie_name, autosave => 1, @_);
    my $id = $o{id} || get_cookies($o{name});
    return undef unless $id;
    my $session = $sessions{$id} || &$get_func($id);
    if( $session ) {
        $autosave{"$session"} = 1 if $o{autosave};
        weaken($sessions{$id} = $session);
        $ids{"$session"} = $id;
    }
    $session;
}

sub write
{
    my $self = shift;
    &$write_func($self);
}

sub id() { $ids{shift()} }

sub DESTROY
{
    my $self = shift;
    delete $sessions{$_} if $_ = delete $ids{"$self"};
    $self->write if delete $autosave{"$self"};
    &$clean_func($self) if $clean_func;
}

sub delete
{
    my $self = shift;
    $_ = delete $ids{"$self"} and delete $sessions{$_};
    delete $autosave{"$self"};
    &$delete_func($self) if $delete_func;
}

1;
