use 5.006;
use strict;
use warnings;

package Brinstar::Session::Test::Default;

use Test::More tests => 14;
use Data::Dumper;

my $cookie_name = "Toto";

BEGIN
{
    use_ok('Brinstar::Session');
    use_ok('Brinstar::Session::File');
}

$Brinstar::Session::File::tmpdir = "/tmp/Brinstar-Sessions";

# Force session creation
my $session = Brinstar::Session->create(name => $cookie_name);
my $session_key = "$session";
my $session_file = $Brinstar::Session::File::sessions{$session_key};
isa_ok($session, 'Brinstar::Session');
ok(-f $session_file, "existence of session file");

# Unmap $session var to force unload of session and trigger write method
undef $session;
ok(not (exists $Brinstar::Session::File::sessions{$session_key}),
    "inexistence of session in memory");
ok(-f $session_file, "existence of session file");

# Re-load the same session
isa_ok($session = Brinstar::Session->get(name => $cookie_name),
    'Brinstar::Session');
ok(exists $Brinstar::Session::File::sessions{"$session"},
    "existence of re-loaded session in memory");

# Force session delete and trigger file deletion
$session_file = $Brinstar::Session::File::sessions{"$session"};
$session->delete;
ok(not (exists $Brinstar::Session::File::sessions{"$session"}),
    "inexistence of session in memory");
ok(not (-f $session_file), "inexistence of session file");

# Get a whole new session but disable autosave
$session = new_ok('Brinstar::Session',
                  [name => $cookie_name, autosave => 0]);
$session->{test} = 1;

# Unload it, session shoult not be saved
undef $session;
$session = new_ok('Brinstar::Session',
                  [name => $cookie_name]);
ok(not (exists $session->{test}), "inexistence of session file");

# Create a session with specified id
my $session1 = Brinstar::Session->create(name => $cookie_name, id => "TEST_ID");
my $session2 = Brinstar::Session->get(name => $cookie_name, id => "TEST_ID");
ok((defined $session2 and $session1 eq $session2), 'Second session created with same id should match first one');

1;
