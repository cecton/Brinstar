use 5.006;
use strict;
use warnings;

package Brinstar::Session::Test::Default;

use Test::More tests => 11;
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
isa_ok($session, 'Brinstar::Session');

# Unmap $session var to force unload of session and trigger write method
my $session_key = "$session";
my $session_file = $Brinstar::Session::File::sessions{$session_key};
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

# Unload it, session shoult not be saved
$session_file = $Brinstar::Session::File::sessions{"$session"};
undef $session;
ok(not (-f $session_file), "inexistence of session file");

1;
