#!/bin/usr/perl
package VCS::Prompt;
use strict;
use warnings;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ButtonToString Prompt);

use Switch;
use File::Temp qw(tempfile);
use enum qw(
	:Button_=0 OK Cancel Yes No
	:Buttons_=20 OK OKCancel YesNo YesNoCancel
);
# NOTE: Prep should run "cpan -i Switch enum" or integrated equivalent


sub ButtonToString
{
	my $button = shift;

	switch ($button)
	{
		case Button_OK { return "OK"; }
		case Button_Cancel { return "Cancel"; }
		case Button_Yes { return "Yes"; }
		case Button_No { return "No"; }
		else { die ("Unknown button: $button") }
	}
}


sub Prompt
{
	switch ($^O)
	{
		case "MSWin32" { return PromptWindows (@_); }
		case "darwin" { return PromptOSX (@_); }
		else { die ("Unsupported OS: $^O") }
	}
}


sub PromptOSX
{
	my $title = shift;
	my $message = shift;
	my $buttons = shift;

	# Build AppleScript
	my $buttonsConfig = "";
	switch ($buttons)
	{
		case Buttons_OK { $buttonsConfig = "\"OK\""; }
		case Buttons_OKCancel { $buttonsConfig = "\"OK\", \"Cancel\""; }
		case Buttons_YesNo { $buttonsConfig = "\"Yes\", \"No\""; }
		case Buttons_YesNoCancel { $buttonsConfig = "\"Yes\", \"No\", \"Cancel\""; }
		else { die ("Unknown buttons type: $buttons"); }
	}

	my $applescript = <<"END_SCRIPT";
try
	display dialog \"$message\" with title \"$title\" buttons {$buttonsConfig} default button 1
on error number -128
	return \"button returned:Cancel\"
end try
END_SCRIPT

	# Run and read output from stdout
	$_ = `osascript -e '$applescript'`;

	# Parse output
	my $result = "Unknown";
	if ($_ eq "")
	{
		$result = "Cancel";
	}
	else
	{
		while (/\:(.*)/g)
		{
			$result = $1;
		}
	}

	# Parse output and return
	switch ($result)
	{
		case "OK" { return Button_OK }
		case "Cancel" { return Button_Cancel }
		case "Yes" { return Button_Yes }
		case "No" { return Button_No }
		else { die ("Unknown dialog result: $result"); }
	}
}


sub PromptWindows
{
	my $title = shift;
	my $message = shift;
	my $buttons = shift;

	# Build VBScript
	my $buttonsConfig = "";
	switch ($buttons)
	{
		case Buttons_OK { $buttonsConfig = "vbOKOnly"; }
		case Buttons_OKCancel { $buttonsConfig = "vbOKCancel"; }
		case Buttons_YesNo { $buttonsConfig = "vbYesNo"; }
		case Buttons_YesNoCancel { $buttonsConfig = "vbYesNoCancel"; }
		else { die ("Unknown buttons type: $buttons"); }
	}

	my $vbscript = "WScript.StdOut.Write (MsgBox (\"$message\", $buttonsConfig, \"$title\"))";

	# Write VBScript to temp file
	my $fileHandle;
	my $fileName;
	($fileHandle, $fileName) = tempfile ("XXXXXXXXXX", SUFFIX => ".vbs");

	print $fileHandle $vbscript;
	close ($fileHandle);

	# Run and read result from stdout
	my $output = (grep /^\d+/, `cscript $fileName`)[0];

	# Clean up script file
	unlink ($fileName);

	# Parse output and return
	switch ($output)
	{
		case 1 { return Button_OK }
		case 2 { return Button_Cancel }
		case 6 { return Button_Yes }
		case 7 { return Button_No }
		else { die ("Unknown messagebox result: $output"); }
	}
}
