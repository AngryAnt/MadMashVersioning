#!/usr/bin/perl
use File::Copy;
use VCS::Tools;

my %coreConfiguration = LoadConfiguration ();
my %userConfiguration = LoadUserConfiguration ();
my %configuration = (%coreConfiguration, %userConfiguration);

# Copy git hooks and set executable access

copy ($configuration{"setupVCSToolsPath"} . "/Commit.pl", $configuration{"setupGitHooksPath"} . "/pre-commit");
chmod 0755, $configuration{"setupGitHooksPath"} . "/pre-commit";
copy ($configuration{"setupVCSToolsPath"} . "/Update.pl", $configuration{"setupGitHooksPath"} . "/post-checkout");
chmod 0755, $configuration{"setupGitHooksPath"} . "/post-checkout";

# Check if a working copy of the SVN repository exists

my $noWorkingCopy = 0;

if (! -e $configuration{"workingCopy"} . "/.svn")
{
	$noWorkingCopy = 1;
}

# If no working copy, prompt for SVN username and perform checkout - otherwise update

if ($noWorkingCopy)
{
	print ("No SVN working copy found. Performing checkout.\nSVN username: ");
	my $username = <STDIN>;
	chomp $username;

	SVNCheckout ($configuration{"workingCopy"}, $configuration{"repository"}, $configuration{"revision"}, $username);
}
else
{
	print ("SVN working copy found. Performing update.\n");
	SVNUpdate ($configuration{"workingCopy"}, $configuration{"revision"});
}
