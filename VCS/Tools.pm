#!/usr/bin/perl
package VCS::Tools;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(RequireSystemSuccess LoadConfiguration LoadUserConfiguration SaveConfiguration SVNVersion SVNStatus SVNUnversioned SVNCommit SVNUpdate SVNCheckout SVNAdd GitBaseRevision);

use File::Slurp;
use JSON;


our $configurationFile = "VCS/Configuration.txt";
our $userConfigurationFile = "VCS/LocalUserConfiguration.txt";


sub LoadConfiguration
{
	our $configurationFile;

	my $json = read_file ($configurationFile);

	return %{decode_json ($json)};
}


sub LoadUserConfiguration
{
	our $userConfigurationFile;

	if (-e $userConfigurationFile)
	{
		print ("Local user configuration found.\n");

		my $json = read_file ($userConfigurationFile);
		return %{decode_json ($json)};
	}

	return ();
}


sub SaveConfiguration
{
	our $configurationFile;
	my (%configuration) = @_;

	my $gitCommandStageVersionFile = "git add $configurationFile";

	my $json = to_json (\%configuration, {pretty => 1, canonical => 1});
	write_file ($configurationFile, $json);

	system ($gitCommandStageVersionFile);
	RequireSystemSuccess ("Failed to stage the configuration");
}


sub SVNVersion
{
	my $workingCopy = shift;

	my @versionParts = split /:/, `svnversion $workingCopy`;
	my $version = $versionParts[-1];
	$version =~ s/^\s+|\s+$//g;

	return $version;
}


sub SVNStatus
{
	my $workingCopy = shift;

	my @status = `svn status $workingCopy`;

	return @status;
}


sub SVNUnversioned
{
	my $workingCopy = shift;

	my @unversioned = grep /^\?/, SVNStatus ($workingCopy);

	return @unversioned;
}


sub SVNCommit
{
	my $workingCopy = shift;
	my $message = shift;

	system ("svn", "commit", $workingCopy, "-m", "\"$message\"");
	RequireSystemSuccess ("SVN commit failed");
}


sub SVNUpdate
{
	my $workingCopy = shift;
	my $version = shift;

	system ("svn", "update", $workingCopy, "-r", $version);
	RequireSystemSuccess ("SVN update failed");
}


sub SVNCheckout
{
	my $workingCopy = shift;
	my $repository = shift;
	my $revision = shift;
	my $username = shift;

	my $command = "svn co $repository $workingCopy -r $revision";
	if ($username ne "")
	{
		$command = "$command --username $username";
	}

	system ($command);
	RequireSystemSuccess ("SVN checkout failed");
}


sub SVNAdd
{
	my $target = shift;

	system ("svn", "add", $target);
	RequireSystemSuccess ("SVN add failed");
}


sub GitBaseRevision
{
	return `git rev-parse HEAD`;
}


sub RequireSystemSuccess
{
	my $message = shift;

	if ($? != 0)
	{
		die ($message);
	}
}

1;
