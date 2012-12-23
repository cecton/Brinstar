use 5.006;
use strict;
use warnings;

package Brinstar::HTML;

use Brinstar::HTML::Tag 'all';
use Brinstar::Cookies;
use Carp;

use base 'Exporter';

my(@tags_magic) = qw(document html head br img script form hidden checkbox
                     submit button Select textarea input password);
my(@tags_mortal) = qw(body a p h1 h2 h3 div span pre ul li dl dt dd label);
my(@tags_all) = (@tags_magic, @tags_mortal);

my(@http_subs) = qw(http_header query_string serialize);

our(@EXPORT_OK) = (qw(all uid), @tags_all, @http_subs);
our(%EXPORT_TAGS) = (
        all => \@EXPORT_OK,
        magicals => \@tags_magic,
        mortals => \@tags_mortal,
        http => \@http_subs,
    );

sub uid() { our $uid; 'id'.++$uid }

sub serialize
{
    my %data = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    for(values %data) {
        s/[^a-z0-9_ ]/sprintf('%%%x', ord($&))/gie;
        s/ /+/g;
    }
    join('&', map {"$_=$data{$_}"} grep {m/=/
        ? do {carp "Cannot serialize key `$_' and value `$data{$_}'!"; 0}
        : $_} keys %data);
}

sub query_string()
{
    $ENV{QUERY_STRING} || serialize(map {m/^([^=]+)=(.+)$/
        ? ($1 => $2)
        : die "Cannot convert argument $_ to key=value parameter!\n"} @ARGV)
}



################################################################################
##
##  HTTP Header stuffs
##
########################

my %HEADER_TAGS = (
        type => 'Content-Type',
        lang => 'Content-Language',
        cookies => 'Set-Cookie',
        nocookie => '_nocookie',
    );

sub http_header
{
    my %o = (type => 'text/html; charset=UTF-8');
    if( @_ == 1 ) { $o{type} = shift }
    elsif( @_ == 2 and $_[0] =~ /\// and $_[1] =~ /^\d+/ ) {
        %o = (%o, type => $_[0], status => $_[1]);
    } else { %o = (%o, @_) }
    ## Cleaning up parameters
    while( my($k,$v) = each %o ) { next if $k =~ /^_/;
        if( ref $v eq 'ARRAY' ) {
            @$v = grep {$_} @$v;
            unless( @$v ) { delete $o{$k}; next }
        } elsif( ref $v eq 'HASH' ) {
            unless( %$v ) { delete $o{$k}; next }
        } else {
            unless( defined $v and $k ) { delete $o{$k}; next }
        }
        local $_ = $HEADER_TAGS{$k};
        s/\b[a-z]/uc $&/ge if not $_ and $_ = $k;
        $o{$_} = delete $o{$k} if $_ ne $k;
    }
    ## Special behaviors
    # Content type and charset
    $o{'Content-Type'} =~ s/(;\s*)?charset=[^;]+|$/; charset=$o{Charset}/
        if $o{Charset} and $o{'Content-Type'} =~ /text/;
    delete $o{Charset};
    # Cookies
    if( $o{_nocookie} ) { delete $o{'Set-Cookie'} }
    else {
        my %cookies;
        %cookies = Brinstar::Cookies->get
            if not defined $o{'Set-Cookie'} or ref $o{'Set-Cookie'} ne 'HASH';
        %cookies = (%cookies, %{$o{'Set-Cookie'}})
            if ref $o{'Set-Cookie'} eq 'HASH';
        $o{'Set-Cookie'} = join('; ',
            (map {"$_=$cookies{$_}"} keys %cookies),
            'path=/') if %cookies;
    }
    # Languages
    $o{'Content-Language'} ||= $ENV{LANGUAGE} if $ENV{LANGUAGE};
    #TODO dont know how language show multiple languages...
    #if( ref $o{'Content-Language'} eq 'ARRAY' ) {
    #    $o{'Content-Language'} = join(', ', @{$o{'Content-Language'}});
    #}
    ## Build header
    my $r = '';
    values %o;
    while( my($k,$v) = each %o ) { next if $k =~ /^_/;
        if( ref($v) =~ m/^[A-Z_]+$/ ) {
            carp "Can't handle HTTP header parameter $k (ref type is "
                 .ref($v).")!";
            next;
        }
        $r .= "$k: $v\n";
    }
    "$r\n";
}



###############################################################################
##
##  Special and Magical Tags
##
##############################

sub document { join('', "<!DOCTYPE html>\n", @_) }

sub html
{ 
    Brinstar::HTML::Tag->new({
        _tag => 'html',
        lang => $ENV{LANGUAGE},
        'xml:lang' => $ENV{LANGUAGE},
    }, @_)
}

sub head
{
    my %self = (@_);
    my @head;
    if( exists $self{meta} ) {
        for( all $self{meta} ) {
            my %meta = ref $_ eq 'HASH' ? %$_ : (href => $_);
            if( exists $meta{content} or exists $meta{charset} ) {
                $meta{'http-equiv'} ||= 'Content-Type';
                $meta{content} ||= 'text/html';
            }
            unless( $meta{content} =~ m/\bcharset=/ ) {
                $meta{content} .= '; charset='
                                  .(delete($meta{charset}) || 'utf-8');
            }
            push @head, Brinstar::HTML::Tag->new({_tag => 'meta', %meta});
        }
    } else {
        push @head, Brinstar::HTML::Tag->new({
                _tag => 'meta',
                content => 'text/html; charset=utf-8',
                'http-equiv' => 'Content-Type'
            });
    }
    if( exists $self{script} ) {
        for( all $self{script} ) {
            my %script = ref $_ eq 'HASH' ? %$_ : (src => $_);
            $script{type} ||= 'text/javascript';
            push @head, Brinstar::HTML::Tag->new({
                    _tag => 'script',
                    _neveralone => 1,
                    %script,
                });
        }
    }
    if( exists $self{link} ) {
        for( all $self{link} ) {
            my %link = ref $_ eq 'HASH' ? %$_ : (href => $_);
            if( $link{href} =~ m/\.css(\?.*)?$/ ) {
                $link{type} ||= 'text/css';
                $link{rel} ||= 'stylesheet';
            }
            push @head, Brinstar::HTML::Tag->new({_tag => 'link', %link});
        }
    }
    if( exists $self{style} ) {
        for( all $self{style} ) {
            s/^\s+|\s+$//g;
            next unless $_;
            push @head, Brinstar::HTML::Tag->new({
                    _tag => 'style',
                    type => 'text/css',
                }, $_);
        }
    }
    push @head, Brinstar::HTML::Tag->new({_tag => 'title'},
        exists $self{title} ? $self{title} : $0);
    Brinstar::HTML::Tag->new({_tag => 'head'}, @head);
}

sub br() { "<br />" }

sub img
{
    my %p = (@_);
    $p{alt} = $p{src} =~ m(([^./]+)(\.[^./]+)*$) ? $1 : 'pic'
        unless exists $p{alt};
    Brinstar::HTML::Tag->new({
            _tag => 'img',
            %p,
        })
}

sub script
{
    Brinstar::HTML::Tag->new({
            _tag => 'script',
            type => 'text/javascript',
        }, m/[<>&]/ ? ("//<![CDATA[\n", @_, "\n//]]>") : @_);
}

sub form
{
    Brinstar::HTML::Tag->new({
            _tag => 'form',
            method => 'post',
            enctype => 'multpart/form-data',
        }, @_);
}

sub hidden
{
    my %table = @_;
    map {Brinstar::HTML::Tag->new({
            _tag => 'input',
            type => 'hidden',
            name => $_,
            value => $table{$_},
        })} keys %table;
}

sub checkbox
{
    my %checkbox = (type => 'checkbox', _tag => 'input', @_);
    $checkbox{id} = uid unless exists $checkbox{id};
    ($checkbox{label} and Brinstar::HTML::Tag->new({
            _tag => 'label',
            for => $checkbox{id},
        }, delete $checkbox{label})),
    Brinstar::HTML::Tag->new(\%checkbox);
}

sub submit
{
    Brinstar::HTML::Tag->new({
            _tag => 'input',
            type => 'submit',
            value => join(' ', @_),
        });
}

sub button
{
    Brinstar::HTML::Tag->new({
            _tag => 'input',
            type => 'button',
            value => join(' ', @_),
        });
}

sub Select
{
    my %select = (
            _tag => 'select',
            _default => '',
            values => undef,
            @_,
        );
    my $values = delete $select{values};
    Brinstar::HTML::Tag->new(\%select, do {
            if( $values ) {
                my %flags = (selected => 1);
                if( ref $values eq 'HASH' ) {
                    map {Brinstar::HTML::Tag->new({
                            _tag => 'option',
                            _flags => \%flags,
                            value => $_,
                            selected => $select{_default} eq $_,
                        }, $values->{$_})} keys %$values;
                } elsif( ref $values eq 'ARRAY' ) {
                    map {Brinstar::HTML::Tag->new({
                            _tag => 'option',
                            _flags => \%flags,
                            selected => $select{_default} eq $_,
                        }, $_)} @$values;
                } else {
                    carp "Invalid values type for tag HTML <select>: ".
                         (ref($values) or "not a reference");
                    ();
                }
            } else { () }
        });
}

sub textarea {
    local $_ = join('', @_);
    s(\]\]>)(]]]]><![CDATA[>)g;
    Brinstar::HTML::Tag->new({
            _tag => 'textarea',
            _neveralone => 1,
        }, "<![CDATA[$_]]>");
}

sub input {
    Brinstar::HTML::Tag->new({
            _tag => 'input',
            type => 'text',
            @_,
        });
}

sub password {
    Brinstar::HTML::Tag->new({
            _tag => 'input',
            _neveralone => 1,
            type => 'password',
            @_,
        });
}



###############################################################################
##
##  Tags That Acts Like Usual
##
###############################

my %specificities = (
        input => {
                _booleans => {
                    'disabled' => 1,
                },
            },
        map {$_ => {_neveralone => 1}} qw(
                div span
                dl dt dd
            )
    );

foreach my $tag (@tags_mortal)
{   no strict 'refs';
    *{$tag} = sub
        {
            Brinstar::HTML::Tag->new(
                {_tag => $tag, %{$specificities{$tag} or {}}},
                @_)
        }
}

1;

# vim:ts=4:softtabstop=4:sw=4:expandtab:
