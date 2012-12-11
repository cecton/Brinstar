Brinstar::HTML
==============

Name
----

CGI/HTML library to easily create HTML trees, manipulate them, manage sessions, cookies, and retrieve GET and POST values.


Synopsis
---------

    use Brinstar::HTML ':all';

    my $head = head(link => [qw(/file/a /file/b)]);

    my $body = body(p("It works!"));

    my $html = html($head, $body);

    my $document = document($html);
    print $document;
    print http_header(), $document;

    use Data::Dumper;
    warn Dumper($html);


Features
--------

### Current Features
* HTML tree creation
* Base cookie management
* Retrieve POST and GET values


### Coming Features
* HTML tree search for children/ancestors
* Session management


Purpose
-------

1. Make HTML5-compliant markup
2. Make HTML creation easier than with Perl CGI
