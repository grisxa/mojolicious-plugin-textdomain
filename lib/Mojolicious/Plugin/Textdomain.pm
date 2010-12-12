package Mojolicious::Plugin::Textdomain;

use warnings;
use strict;

use base 'Mojolicious::Plugin';

use Locale::Messages qw (:libintl_h nl_putenv);
use POSIX qw (setlocale);
use File::Spec;
use Encode;

our $VERSION = '0.01';

sub register {
	my ($self, $app, $conf) = @_;

	# Config
	$conf ||= {};

	# Default values
	$conf->{codeset}        ||= 'utf-8';
	$conf->{search_dirs}    ||= [ File::Spec->join($app->home, 'i18n') ];

	Locale::Messages->select_package('gettext_pp');
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
			my ($self, $accept_language, $available_languages, $default_languages) = @_;
			require I18N::AcceptLanguage;

			my $loc_detect = I18N::AcceptLanguage->new(
				defaultLanguage => $default_languages
			);

			$loc_detect->accepts($accept_language, $available_languages);
		});
}

1;
