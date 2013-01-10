use 5.006;
use strict;
use warnings;

package Brinstar::HTML::Extra::Tag;

no warnings 'redefine';

use Brinstar::HTML ':all';
use Carp;

use base 'Exporter';
our(@EXPORT_OK) = @Brinstar::HTML::EXPORT_OK;
our(%EXPORT_TAGS) = (
        'all' => \@EXPORT_OK,
    );

sub html
{ 
    Brinstar::HTML::Tag->new({
        _tag => 'html',
        lang => $ENV{LANGUAGE} || $ENV{LANG},
        'xml:lang' => $ENV{LANGUAGE} || $ENV{LANG},
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

sub uid() { our $uid; 'id'.++$uid }

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
            value => @_ ? join(' ', @_) : undef,
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
    my %params = map {%$_} grep {ref $_ eq 'HASH'} @_;
    my $text = join('', grep {not ref $_} @_);
    $text =~ s(\]\]>)(]]]]><![CDATA[>)g;
    $text = "<![CDATA[$text]]>" if $text;
    Brinstar::HTML::Tag->new({
            _tag => 'textarea',
            _neveralone => 1,
            %params,
        }, $text);
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

1;
