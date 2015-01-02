#!/usr/bin/perl
use strict;
use warnings;
use VCS::Tools;

my %coreConfiguration = LoadConfiguration ();
my %userConfiguration = LoadUserConfiguration ();
my %configuration = (%coreConfiguration, %userConfiguration);

# TODO: Need to figure out how to read the git commit message - so we can re-use it here
my $gitCommitMessage = "Files for git commit based on " . GitBaseRevision ();

# If 'autoAdd' configuration is enabled, add any unversioned files in SVN

my @unversioned;
if ($configuration{"autoAdd"})
{
	@unversioned = SVNUnversioned ($configuration{"workingCopy"});
	foreach (@unversioned)
	{
		my $file = substr ($_, 1);
		$file =~ s/^\s+|\s+$//g;

		SVNAdd ($file);
	}
}

# Check for unversioned files in SVN - bail after listing if any are found

@unversioned = SVNUnversioned ($configuration{"workingCopy"});
if (scalar (@unversioned) > 0)
{
	print ("Unversioned files in SVN:\n");
	foreach (@unversioned)
	{
		print ("$_");
	}
	die ("These files must be versioned / ignored or removed before committing.");
}

# If 'autoCommit' configuration is enabled, commit anything not committed in SVN

if ($configuration{"autoCommit"})
{
	SVNCommit ($configuration{"workingCopy"}, $gitCommitMessage);
}

# Check that SVN is clean - bail after listing if not

my @status = SVNStatus ($configuration{"workingCopy"});
if (scalar (@status) > 0)
{
	print ("SVN status:\n");
	foreach (@status)
	{
		print ("$_");
	}
	die ("SVN must be committed and clean before performing a git commit");
}

# Update the core configuration with the possibly updated SVN version

$coreConfiguration{"revision"} = SVNVersion ($configuration{"workingCopy"});

# Save the core configuration

SaveConfiguration (%coreConfiguration);

# Log out the potentially updated revision

print ("SVN version is " . $coreConfiguration{"revision"} . "\n");
