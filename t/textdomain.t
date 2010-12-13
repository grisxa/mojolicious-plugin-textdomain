#!/usr/bin/env perl
use lib qw(lib ../../lib);
use strict;
use warnings;
use utf8;

# Test application
use Mojolicious::Lite;
use Encode;

plugin 'charset' => {charset => 'utf-8'};
plugin 'textdomain';

get '/template/:lang' => sub {
	my $self = shift;
	$self->set_language($self->stash('lang'));
	$self->render( template =>'t' );
};
get '/text/:lang' => sub {
	my $self = shift;
	$self->set_language($self->stash('lang'));
	$self->render( text => $self->__('test') );
};

get '/detect/:default/:available' => sub {
	my $self = shift;
	my @available= split(/,/, $self->stash('available'));
	$self->render( text => $self->detect_language( \@available, $self->stash('default')) );
};


# Tests
use Test::More tests => 24;
use Test::Mojo;

my $t = Test::Mojo->new();

my $data = $t->get_ok('/template/en')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
# res->body returns bytes so we have to decode it to perl-strings
$data = decode('utf-8', $data);
like $data, qr{<p>Test</p>};


$data = $t->get_ok('/template/ru')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
$data = decode('utf-8', $data);
like $data, qr{<p>Проверка</p>};


$data = $t->get_ok('/text/en')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
$data = decode('utf-8', $data);
is $data, 'Test';


$data = $t->get_ok('/text/ru')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
$data = decode('utf-8', $data);
is $data, 'Проверка';


$data = $t->get_ok('/detect/uk/en,uk,ru', {'Accept-Language' => 'ru,en-us;q=0.7'})
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
is $data, 'ru';


$data = $t->get_ok('/detect/uk/en,uk,ru', {'Accept-Language' => 'pl;q=0.7,en;q=0.3'})
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
is $data, 'en';

__DATA__

@@ t.html.ep
<p><%= __('test') %></p>
