#!/usr/bin/env perl
#
#  Session example using File driver
#

use lib '..';

use strict;
use warnings;
use Data::Dumper;
use POSIX qw/strftime/;

use Brinstar::HTTP ':all';
use Brinstar::HTML::Extra::Tag ':all';
use Brinstar::Session;
use Brinstar::Session::File;

$Brinstar::Session::DEBUG = 1 unless exists $ENV{HTTP_HOST};

my @body;
my $session = Brinstar::Session->get;

unless( $session ) {
    $session = Brinstar::Session->create;
    push @body, "No session\n";
} else {
    push @body, "Already have a session\n";
}

push @body, "Session ", $session->id," content: ", Dumper($session);

# Update last_visit after display
my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
$session->{last_visit} = $now;
push @body, "Current time: $now\n";

print STDOUT http_header, Document(html(head(), body(pre(@body))));
