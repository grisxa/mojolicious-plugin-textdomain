#!/usr/bin/env perl
use lib qw(lib ../../lib);
use strict;
use warnings;
#use utf8;

# Test application
use Mojolicious::Lite;

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
	$self->render( text => $self->detect_language( scalar $self->req->headers->accept_language, \@available, $self->stash('default')) );
};


# Tests
use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new();

my $data = $t->get_ok('/template/en')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
like $data, qr{<p>Test</p>};

$data = $t->get_ok('/template/ru')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
like $data, qr{<p>Проверка</p>};

$data = $t->get_ok('/text/en')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
is $data, 'Test';

$data = $t->get_ok('/text/ru')
	->status_is(200)
	->tx->res->body;
is defined $data, 1;
is $data, 'Проверка';

eval {
	require "II18N::AcceptLanguage";
};
if ($@) {
};

warn $t->get_ok('/detect/en/en,ru', {'Accept-Language' => 'ru'})->tx->res->body;

__DATA__

@@ t.html.ep
<p><%= __('test') %></p>
