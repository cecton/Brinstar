Brinstar
========

Name
----

Perl CGI/HTML library to easily create HTML trees, manipulate them, manage sessions,
cookies, and retrieve GET and POST values.


Synopsis
---------

    # HTML stuffs
    use Brinstar::HTML ':all';

    my $head = head(link => [qw(/file/a /file/b)]);

    my $body = body(p("It works!"));

    my $html = html($head, $body);

    my $document = document($html);
    print $document;
    print http_header(), $document;

    use Data::Dumper;
    warn Dumper($html);


    # Session stuffs
    use Brinstar::Session;
    use Brinstar::Session::File;

    my $session = Brinstar::Session->new;
    print "Value $_ exists!" if ($_ = $session->{those});
    $session{thing} = 1;

    my $session = Brinstar::Session->create('PHPSESSID');
    $session{that} = 0;

    my $session = Brinstar::Session->get('TOTO');
    if( $session ) {
        print "Hi $session->{display_name}";
    } else {
        print "Your are not logged on";
    }


Features
--------

### Current Features
* HTML tree creation
* Base cookie management
* Retrieve POST and GET values
* Session management (and test)
* DBI driver for sessions


### Coming Features
* HTML tree search for children/ancestors
* Tests for HTML part


Purpose
-------

1. Make HTML5-compliant markup
2. Make HTML creation easier than with Perl CGI
