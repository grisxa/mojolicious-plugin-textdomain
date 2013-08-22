package Mojolicious::Plugin::Textdomain;

# (C) 2010 Anatoliy Lapitskiy <nuclon@cpan.org>

use warnings;
use strict;

use base 'Mojolicious::Plugin';

use Locale::Messages qw (:libintl_h nl_putenv);
use Locale::Util qw(parse_http_accept_language);
use File::Spec;
use Encode;
use List::Util qw(first);
use List::MoreUtils qw(uniq);

our $VERSION = '0.01';

sub register {
	my ($self, $app, $conf) = @_;

	# Config
	$conf ||= {};

	# Default values
	$conf->{domain}         ||= 'messages';
	$conf->{codeset}        ||= 'utf-8';
	$conf->{search_dirs}    ||= [ File::Spec->join($app->home, 'i18n') ];

	Locale::Messages->select_package('gettext_pp');

	require Locale::TextDomain;

	# load translations from dirs for the text domain 
	Locale::TextDomain->import($conf->{domain}, @{ $conf->{search_dirs} });

	{
		no strict 'refs';
		for my $method ( qw( __ __x __n __nx __xn __p __px __np __npx N__) ) {
			$app->renderer->add_helper(
				$method => sub {
						my $self = shift;

						# return perl-strings
						decode($conf->{codeset}, &$method(@_));
					});
		}
	}

	# replace the locale
	$app->renderer->add_helper(
		set_language => sub {
				my ($self, $lang) = @_;
				nl_putenv('LANGUAGE='.$lang);
				nl_putenv('LANG='.$lang);
			});

	$app->renderer->add_helper(
		detect_language => sub {
			my ($self, $available_languages, $default_language) = @_;

			$available_languages ||= $conf->{'available_languages'};
			$default_language    ||= $conf->{'default_language'};
			my $accept_language = $self->req->headers->accept_language;

			my @langtags = parse_http_accept_language $accept_language;
			@langtags = uniq map { @_ = split /-/, $_, 2; ($_, $_[0]) } @langtags;

			my $rv;
			for my $lang (@langtags) {
				if (first { $_ eq $lang } @{ $available_languages }) {
					$rv = $lang;
					last;
				}
			}

			$rv = $default_language if !$rv;
			$rv;

		});
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Textdomain - Locale::TextDomain plugin for Mojolicious

=head1 SYNOPSYS

code:

	sub startup {
		...
		$self->plugin('textdomain', {
			'available_languages' => ['en', 'ru', 'uk'],
			'default_language'    => 'en',
		});
		...

		my $r = $self->routes;
		$r->route('/')->to(cb => sub {
				my $self = shift;
				my $lang = $self->detect_language;
				$self->redirect_to('index', lang => $lang);
			});

		my $lang_bridge = $r->bridge('/:lang')->to(cb => sub {
				my $self = shift;
				$self->set_language( $self->stash('lang') );
				1;
			});
		$lang_bridge->route('/')->name('index')->to('root#index');
		...
	}


=head1 DESCRIPTION

L<Mojolicious::Plugin::Textdomain> is L<Locale::TextDomain> plugin for Mojolicious.
You can read advantages of L<Locale::TextDomain> over <Locale::Maketext> solution used in Mojolicious::Plugin::I18n here: L<http://rassie.org/archives/247>

=head2 Options

=over 4

=item domain

=item search_dirs

=item codeset

=item available_languages

=item default_language

=back

=head2 Helpers

All __ methods from L<Locale::TextDomain>, e.g. <%= __ 'Message' %>, <%= __nx 'one apple', '{count} apples', $n, count => $n %> etc.
Plus 

=over 4

=item detect_language

=item set_language

=back


=cut
