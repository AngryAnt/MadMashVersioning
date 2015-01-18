#!/usr/bin/perl
use strict;
use warnings;
use VCS::Tools;
use VCS::Prompt;
use enum qw(
	:Button_=0 OK Cancel Yes No
	:Buttons_=20 OK OKCancel YesNo YesNoCancel
);

my %coreConfiguration = LoadConfiguration ();
my %userConfiguration = LoadUserConfiguration ();
my %configuration = (%coreConfiguration, %userConfiguration);

# TODO: Need to figure out how to read the git commit message - so we can re-use it here
my $gitCommitMessage = "Files for git commit based on " . GitBaseRevision ();

# If SVN holds unversioned files, then add them if 'add' is 'yes' / prompt if 'prompt' - otherwise bail

my $choice;
my @unversioned = grep s/^.\s+|\s+$//g, SVNUnversioned ($configuration{"workingCopy"});
my $unversionedString = "\t" . join ("\n\t", @unversioned);

if (scalar (@unversioned) > 0)
{
	if ($configuration{"add"} eq "yes")
	{
		$choice = Button_Yes;
	}
	elsif ($configuration{"add"} eq "prompt")
	{
		print ("Unversioned files:\n$unversionedString\n\nPrompting.\n");

		$choice = Prompt (
			"Add files?",
			"Would you like to add the following unversioned files to SVN?\n\n$unversionedString",
			Buttons_YesNoCancel
		);
	}
	else
	{
		print ("Unversioned files:\n$unversionedString\n\n");

		die ("These files must be versioned / removed or ignored before performing a git commit.");
	}

	if ($choice == Button_Yes)
	{
		print ("Adding:\n$unversionedString\n\n");

		foreach (@unversioned)
		{
			SVNAdd ($_);
		}
	}
	elsif ($choice == Button_No)
	{
		print ("Skipping:\n$unversionedString\n\n");
	}
	else
	{
		die ("Commit canceled by user");
	}
}

# If SVN holds uncommitted files, then commit them if 'commit' is 'yes' / prompt if 'prompt' - otherwise bail

my @status = grep s/^.\s+|\s+$//g, SVNChanged ($configuration{"workingCopy"});
if (scalar (@status) > 0)
{
	my $statusString = "\t" . join ("\n\t", @status);

	if ($configuration{"commit"} eq "yes")
	{
		$choice = Button_Yes;
	}
	elsif ($configuration{"commit"} eq "prompt")
	{
		print ("SVN status:\n$statusString\n\n");

		$choice = Prompt (
			"Commit changes?",
			"The following files have been changed in SVN. Would you like to commit them as well?\n\n$statusString",
			Buttons_YesNoCancel
		);
	}
	else
	{
		print ("SVN status:\n$statusString\n\n");

		die ("SVN must be committed and cleaned before performing a git commit.");
	}

	if ($choice == Button_Yes)
	{
		print ("Committing:\n$statusString\n\n");

		SVNCommit ($configuration{"workingCopy"}, $gitCommitMessage);
	}
	elsif ($choice == Button_No)
	{
		print ("Skipping:\n$statusString\n\n");
	}
	else
	{
		die ("Commit canceled by user");
	}
}

# Update the core configuration with the possibly updated SVN version

$coreConfiguration{"revision"} = SVNVersion ($configuration{"workingCopy"});

# Save the core configuration

SaveConfiguration (%coreConfiguration);

# Log out the potentially updated revision

print ("SVN version is " . $coreConfiguration{"revision"} . "\n");
