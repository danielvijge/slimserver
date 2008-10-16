package Slim::Web::Settings::Server::Wizard;

# SqueezeCenter Copyright 2001-2007 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;
use base qw(Slim::Web::Settings);
use Digest::SHA1 qw(sha1_base64);
use I18N::LangTags qw(extract_language_tags);
use HTTP::Status qw(RC_MOVED_TEMPORARILY);

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Timers;
use Slim::Networking::SqueezeNetwork;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'wizard',
	'defaultLevel' => 'ERROR',
});

my $serverPrefs = preferences('server');
my @prefs = ('audiodir', 'playlistdir');

sub page {
	return 'settings/server/wizard.html';
}

sub handler {
	my ($class, $client, $paramRef, $pageSetup, $httpClient, $response) = @_;

	$paramRef->{languageoptions} = Slim::Utils::Strings::languageOptions();

	# The hostname for SqueezeNetwork
	$paramRef->{sn_server} = Slim::Networking::SqueezeNetwork->get_server("sn");

	# make sure we only enforce the wizard at the very first startup
	if ($paramRef->{saveSettings}) {

		$serverPrefs->set('wizardDone', 1);
		$paramRef->{wizardDone} = 1;
		delete $paramRef->{firstTimeRun};		

	}

	if (!$serverPrefs->get('wizardDone')) {
		$paramRef->{firstTimeRun} = 1;

		# try to guess the local language setting
		# only on non-Windows systems, as the Windows installer is setting the langugae
		if (!Slim::Utils::OSDetect::isWindows() && !$paramRef->{saveLanguage}
			&& defined $response->{_request}->{_headers}->{'accept-language'}) {

			$log->debug("Accepted-Languages: " . $response->{_request}->{_headers}->{'accept-language'});

			foreach my $language (extract_language_tags($response->{_request}->{_headers}->{'accept-language'})) {
				$language = uc($language);
				$language =~ s/-/_/;  # we're using zh_cn, the header says zh-cn
	
				$log->debug("trying language: " . $language);
				if (defined $paramRef->{languageoptions}->{$language}) {
					$serverPrefs->set('language', $language);
					$log->info("selected language: " . $language);
					last;
				}
			}

		}

		Slim::Utils::DateTime::setDefaultFormats();
	}
	
	# handle language separately, as it is in its own form
	if ($paramRef->{saveLanguage}) {
		$log->debug( 'setting language to ' . $paramRef->{language} );
		$serverPrefs->set('language', $paramRef->{language});
		Slim::Utils::DateTime::setDefaultFormats();
	}

	$paramRef->{prefs}->{language} = Slim::Utils::Strings::getLanguage();
	
	# set right-to-left orientation for Hebrew users
	$paramRef->{rtl} = 1 if ($paramRef->{prefs}->{language} eq 'HE');

	foreach my $pref (@prefs) {

		if ($paramRef->{saveSettings}) {
				
			# if a scan is running and one of the music sources has changed, abort scan
			if ($pref =~ /^(?:audiodir|playlistdir)$/ 
				&& $paramRef->{$pref} ne $serverPrefs->get($pref) 
				&& Slim::Music::Import->stillScanning) 
			{
				$log->debug('Aborting running scan, as user re-configured music source in the wizard');
				Slim::Music::Import->abortScan();
			}

			$serverPrefs->set($pref, $paramRef->{$pref});
		}

		if ($log->is_debug) {
 			$log->debug("$pref: " . $serverPrefs->get($pref));
		}
		$paramRef->{prefs}->{$pref} = $serverPrefs->get($pref);
	}

	$paramRef->{useiTunes} = preferences('plugin.itunes')->get('itunes');
	$paramRef->{useMusicIP} = preferences('plugin.musicip')->get('musicip');
	$paramRef->{serverOS} = Slim::Utils::OSDetect::OS();

	# if the wizard has been run for the first time, redirect to the main we page
	if ($paramRef->{firstTimeRunCompleted}) {

		$response->code(RC_MOVED_TEMPORARILY);
		$response->header('Location' => '/');
	}

	else {
		
		# use local path if neither iTunes nor MusicIP is available
		$paramRef->{useAudiodir} = !($paramRef->{useiTunes} || $paramRef->{useMusicIP});
	}
	
	if ( $paramRef->{saveSettings} ) {

		if (   $paramRef->{sn_email}
			&& $paramRef->{sn_password_sha}
			&& $serverPrefs->get('sn_sync')
		) {			
			Slim::Networking::SqueezeNetwork->init();
		}

		if ( defined $paramRef->{sn_disable_stats} ) {
			Slim::Utils::Timers::setTimer(
				$paramRef->{sn_disable_stats},
				time() + 30,
				\&Slim::Web::Settings::Server::SqueezeNetwork::reportStatsDisabled,
			);
		}
		
		# Disable iTunes and MusicIP plugins if they aren't being used
		if ( !$paramRef->{useiTunes} ) {
			Slim::Utils::PluginManager->disablePlugin('Slim::Plugin::iTunes::Plugin');
		}
		
		if ( !$paramRef->{useMusicIP} ) {
			Slim::Utils::PluginManager->disablePlugin('Slim::Plugin::MusicMagic::Plugin');
		}
	}

	return Slim::Web::HTTP::filltemplatefile($class->page, $paramRef);
}

1;

__END__
