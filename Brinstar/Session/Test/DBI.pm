use 5.006;
use strict;
use warnings;

package Brinstar::Session::Test::DBI;

use Test::More tests => 17;
use Data::Dumper;

my $cookie_name = "Toto";
my $database = "brinstar_test";
my $data_source = "dbi:Pg:db=$database";
my $username = $ENV{USER};
my $auth;
my %attr;

BEGIN
{
    use_ok('Brinstar::Session');
    use_ok('Brinstar::Session::DBI');
}

$Brinstar::Session::DBI::data_source = $data_source;
$Brinstar::Session::DBI::username = $username;
$Brinstar::Session::DBI::auth = $auth;
%Brinstar::Session::DBI::attr = %attr;
my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
$dbh->do("DROP TABLE $Brinstar::Session::DBI::table")
    or die "Cannot drop table $Brinstar::Session::DBI::table"
           ." of database $database!\n";

# Force session creation
my $session = Brinstar::Session->create(name => $cookie_name);
isa_ok($session, 'Brinstar::Session');
my $session_key = "$session";
ok(my $session_id = $Brinstar::Session::DBI::ids{$session_key},
    "finding id for session");
my $exists_row = $dbh->prepare(<<EOF);
SELECT id FROM $Brinstar::Session::DBI::table
          WHERE id = ?
EOF
ok($exists_row->execute($session_id) && $exists_row->fetchrow_arrayref,
    "existence of session row");

# Unmap $session var to force unload of session and trigger write method
undef $session;
ok(not (exists $Brinstar::Session::DBI::ids{$session_key}),
    "inexistence of session in memory");
ok($exists_row->execute($session_id) && $exists_row->fetchrow_arrayref,
    "existence of session row");

# Re-load the same session
isa_ok($session = Brinstar::Session->get(name => $cookie_name),
    'Brinstar::Session');
ok(exists $Brinstar::Session::DBI::ids{"$session"},
    "existence of re-loaded session in memory");

# Force session delete and trigger file deletion
$session_id = $Brinstar::Session::DBI::ids{"$session"};
$session->delete;
ok(not (exists $Brinstar::Session::DBI::ids{"$session"}),
    "inexistence of session in memory");
ok($exists_row->execute($session_id) && not($exists_row->fetchrow_arrayref),
    "inexistence of session row");

# Get a whole new session but disable autosave
$session = new_ok('Brinstar::Session',
                  [name => $cookie_name, autosave => 0]);
$session->{test} = 1;

# Unload it, session shoult not be saved
undef $session;
$session = new_ok('Brinstar::Session',
                  [name => $cookie_name]);
ok(not (exists $session->{test}), "inexistence of session value");

# Create a session with specified id
my $session1 = Brinstar::Session->create(name => $cookie_name, id => "TEST_ID");
my $session2 = Brinstar::Session->get(name => $cookie_name, id => "TEST_ID");
ok($session1->id eq 'TEST_ID', "Session id match (1)");
ok($session2->id eq 'TEST_ID', "Session id match (2)");
ok(defined $session2 && $session1 eq $session2,
    'Second session created with same id should match first one');

1;
