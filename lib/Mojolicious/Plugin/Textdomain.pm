package Mojolicious::Plugin::Textdomain;

use warnings;
use strict;

use base 'Mojolicious::Plugin';

use Locale::Messages qw (:libintl_h nl_putenv);
use POSIX qw (setlocale);
use File::Spec;
use Encode;
use I18N::LangTags qw(implicate_supers);
use List::Util qw(first);

our $VERSION = '0.01';

sub register {
	my ($self, $app, $conf) = @_;

	# Config
	$conf ||= {};

	# Default values
	$conf->{codeset}        ||= 'utf-8';
	$conf->{search_dirs}    ||= [ File::Spec->join($app->home, 'i18n') ];

	#Locale::Messages->select_package('gettext_pp');
	#Locale::Messages::textdomain($conf{domain});
	#Locale::Messages::bindtextdomain($conf{domain} => $conf{path});
	#Locale::Messages::bind_textdomain_codeset($conf{domain} => $conf{codeset});
	
	require Locale::TextDomain;

	Locale::TextDomain->import($conf->{domain}, @{ $conf->{search_dirs} });

	{
		no strict 'refs';
		for my $method ( qw( __ __x __n __nx __xn __p __px __np __npx) ) {
			$app->renderer->add_helper(
				$method => sub {
						my $self = shift;

						# return perl-strings
						decode($conf->{codeset}, &$method(@_));
					});
		}
	}

	$app->renderer->add_helper(
		set_language => sub {
				my ($self, $locale) = @_;
				nl_putenv('LANGUAGE='.$locale);
				#nl_putenv('LANG='.$lang);
				#nl_putenv('LC_MESSAGES='.$lang);
			});

	$app->renderer->add_helper(
		detect_language => sub {
			my ($self, $available_languages, $default_language) = @_;

			$available_languages ||= $conf->{'available_languages'};
			$default_language    ||= $conf->{'default_language'};
			my $accept_language = $self->req->headers->accept_language;

			my @langtags = 
				map { $_->[0] } #keep just lang tag
				sort { $b->[1] <=> $a->[1] } # sort by priority desc
				map { /([a-zA-Z]{1,8}(?:-[a-zA-Z]{1,8})?)\s*(?:;\s*q\s*=\s*(1|0\.[0-9]+))?/ ; [$1, $2||1] } #parse lang + priority
				split /\s*,\s*/, $accept_language; # split be comma
			@langtags = implicate_supers(@langtags);

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
