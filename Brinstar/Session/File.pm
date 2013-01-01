use 5.006;
use strict;
use warnings;

package Brinstar::Session::File;

use Data::Dumper;
use File::Path qw/make_path/;

use Brinstar::Session qw/uuid/;

$Brinstar::Session::create_func = \&create;
$Brinstar::Session::get_func = \&get;
$Brinstar::Session::write_func = \&write;
$Brinstar::Session::clean_func = \&clean;
$Brinstar::Session::delete_func = \&delete;

our $tmpdir = "temp";

our %sessions;

sub create
{
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    my($session,$id) = @_;
    make_path($tmpdir, {mode => 0700});
    my $file;
    if( $id ) { $file = join('/', $tmpdir, $id) }
    else { $file = join('/', $tmpdir, $id = uuid) while not $file or -f $file }
    open SESSION, '>', $file
        and do
        {
            print SESSION Dumper($session);
            close SESSION
        }
        or warn "Cannot write session into `$file': $!\n";
    $sessions{"$session"} = $file;
    $id;
}

sub get
{
    my $id = shift;
    my $file = join('/', $tmpdir, $id);
    return undef unless -f $file;
    open SESSION, '<', $file
        and do
        {   
            {   no strict 'vars';
                local $/;
                $_ = eval <SESSION>;
            }
            unless( defined $_ ) {
                warn "Cannot eval session from `$file': $!\n";
            } else {
                $sessions{"$_"} = $file;
                return $_;
            }
        }
        or do
        {
            warn "Cannot read session from `$file': $!\n";
        };
}

sub write
{
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    my $session = shift;
    my $file = $sessions{"$session"};

    unless( $file ) {
        warn "Cannot find session for $session!\n";
        return;
    }

    open SESSION, '>', $file
        and do
        {
            print SESSION Dumper($session);
        }
        or do
        {
            warn "Cannot write session into `$file': $!\n";
        };
}

sub clean
{
    my $session = shift;
    delete $sessions{"$session"};
}

sub delete
{
    my $session = shift;
    unlink ($_ = delete $sessions{"$session"})
        or warn "Can not remove session file `$_': $!\n";
}

1;
