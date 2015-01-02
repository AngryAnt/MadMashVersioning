#!/usr/bin/perl
use strict;
use warnings;
use VCS::Tools;

my %coreConfiguration = LoadConfiguration ();
my %userConfiguration = LoadUserConfiguration ();
my %configuration = (%coreConfiguration, %userConfiguration);

# Check out the current version if set

if ($configuration{"revision"} ne "")
{
	print ("Updating SVN to version " . $configuration{"revision"} . "\n");
	SVNUpdate ($configuration{"workingCopy"}, $configuration{"revision"});
}
else
{
	print ("No SVN version configured\n");
}
