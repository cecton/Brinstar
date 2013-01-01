use 5.006;
use strict;
use warnings;

package Brinstar::Session::DBI;

use Data::Dumper;
use DBI;

use Brinstar::Session qw/uuid/;

$Brinstar::Session::create_func = \&create;
$Brinstar::Session::get_func = \&get;
$Brinstar::Session::write_func = \&write;
$Brinstar::Session::clean_func = \&clean;
$Brinstar::Session::delete_func = \&delete;

our $data_source;
our $username = $ENV{USER};
our $auth;
our %attr;
our $table = 'sessions';

my $dbh;
our %ids;

sub connect
{
    return if $dbh;
    die __PACKAGE__." error: data source not defined!\n" unless $data_source;
    $dbh = DBI->connect($data_source, $username, $auth, \%attr);
    my $sth = $dbh->table_info(undef, undef, $table, 'TABLE');
    if( @{$sth->fetchall_arrayref} == 0 )
    {
        die "Cannot create table $table to store sessions!\n"
            unless $dbh->do(<<EOF);
CREATE TABLE $table (
    id character(36) PRIMARY KEY,
    data text,
    last_access timestamp DEFAULT CURRENT_TIMESTAMP,
    creation timestamp DEFAULT CURRENT_TIMESTAMP
)
EOF
    }
}

sub create
{
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    my($session,$id) = @_;
    &connect;

    my $sth = $dbh->prepare_cached("SELECT id FROM $table WHERE id = ?");
    my $insert_must_succeed = 1;
    if( $id ) {
        $insert_must_succeed = 0;
    } else {
        $_ = 1;
        my $tries = 5;
        while( $tries-- and $_ )
        {
            $id = uuid;
            $sth->execute($id);
            $_ = $sth->fetchrow_arrayref;
            $sth->finish;
        }
        return undef if $tries == -1;
    }

    $sth = $dbh->prepare_cached("INSERT INTO $table (id, data) VALUES (?, ?)");
    unless( $sth->execute($id, Dumper($session)) or not $insert_must_succeed )
    {
        warn "Bug: cannot insert new session row id $id\n";
        return undef;
    }

    $ids{"$session"} = $id;
}

sub get
{
    my $id = shift;
    &connect;

    my $sth = $dbh->prepare_cached("SELECT data FROM $table WHERE id = ?");
    $sth->execute($id);
    my $res = $sth->fetchrow_arrayref;
    $sth->finish;
    return undef unless $res;

    my $session = eval $res->[0]
        or do
        {
            warn "Cannot eval session id $id:\n$res->[0]\n";
            return undef;
        };
    $ids{"$session"} = $id;
    $session;
}

sub write
{
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;

    my $session = shift;
    my $id = $ids{"$session"}
        or do
        {
            warn "Bug: cannot find id for session $session!";
            return;
        };
    &connect;

    my $sth = $dbh->prepare_cached(<<EOF);
UPDATE $table
       SET data = ?, last_access = CURRENT_TIMESTAMP
       WHERE id = ?
EOF
    warn "Bug: cannot update session id $id in the database."
        unless $sth->execute(Dumper($session), $id) == 1;
}

sub clean
{
    my $session = shift;
    delete $ids{"$session"};
}

sub delete
{
    my $session = shift;
    my $id = delete $ids{"$session"}
        or do
        {
            warn "Bug: cannot find id for session $session!";
            return;
        };
    &connect;

    my $sth = $dbh->prepare_cached(<<EOF);
DELETE FROM $table WHERE id = ?
EOF
    $sth->execute($id);
}

1;
