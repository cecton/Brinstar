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
    my $class = shift;
    make_path($tmpdir, mode => 0700);
    my($file,$uuid);
    $file = join('/', $tmpdir, $uuid = uuid) while not $file or -f $file;
    my $session = bless {}, $class;
    $sessions{"$session"} = $file;
    $uuid, $session;
}

sub get
{
    my($class,$uuid) = @_;
    my $file = join('/', $tmpdir, $uuid);
    return undef unless -f $file;
    open SESSION, '<', $file
        and do
        {   
            {   no strict 'vars';
                local $/;
                $_ = eval <SESSION>;
            }
            $sessions{"$_"} = $file;
            return $_;
        }
        or do
        {
            warn "Cannot read session from `$file': $!\n";
        };
}

sub write
{
    local $Data::Dumper::Purity = 1;
    my($class,$session) = @_;
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
    my($class,$session) = @_;
    delete $sessions{"$session"};
}

sub delete
{
    my($class,$session) = @_;
    unlink ($_ = delete $sessions{"$session"})
        or warn "Can not remove session file `$_': $!\n";
}

1;
