#!/usr/bin/perl

use POSIX 'strftime';
use Getopt::Long;
use Term::ANSIColor qw(:constants);
use File::Path qw(make_path remove_tree);

########################################################################################################################
#
########################################################################################################################
#
#
#
########################################################################################################################
sub Usage {
	print "Usage:\n\n";
	print "    $0 -s [ alterBTSDK | kairosBTSDK | ethosBTSDK | universalBTSDK | pods | all ] [-k]\n";
	print "\n\n";
	
	print "The scheme (-s or --scheme) is the scheme in that workspace\n";
	print "if 'all' chosen, all are made, including pods\n";
	print "the optional keep (k) is whether to keep the underlying frameworks after assembling the XCFramework\n";
	print "\n\n";
}

########################################################################################################################
#
########################################################################################################################
#
#
#
########################################################################################################################
sub SecondsToTime {
    my ($seconds) = @_;

    return(strftime('%T', gmtime $seconds));
}

########################################################################################################################
#
########################################################################################################################
#
#
#
########################################################################################################################
sub RunCommand {
	my ($title, $command, $regex) = @_;
		
	print "$0: Building $title\n";

	$startTime	= time();
	$failed		= 0;
	open (CMD, "$command 2>&1 |");
	while (<CMD>) {
		if (/$regex/) {
			print BRIGHT_RED, "        $_", RESET;
			$failed	= 1;
		}		
	}

	if ($failed) {
		print "\n";
		print "$0:    "; print BRIGHT_RED, "Error Building $title\n", RESET;
		print "\n";
		exit (1);
	}

	$endTime	= time();
	$elapsed	= $endTime - $startTime;
}

GetOptions ('s|scheme=s' => \$scheme,
			'k|keep-frameworks' => \$keep);

if ($scheme eq "") {
	&Usage;
	exit (0);
}

undef (@schemes);

if ($scheme eq "all") {
	push (@schemes, "pods");
	push (@schemes, "alterBTSDK");
	push (@schemes, "ethosBTSDK");
	push (@schemes, "kairosBTSDK");
	push (@schemes, "universalBTSDK");
}
else {
	push (@schemes, "$scheme");
}

$workspace				= "biostrapDeviceSDK";

$allStartTime	= time();

for $scheme (@schemes) {
	if ($scheme eq "pods") {
		$scheme = "iOSDFULibrary";	# Will also build ZIPFoundation
	}
	else {
		$opt_command			="xcodebuild -workspace $workspace.xcworkspace -scheme $scheme -showBuildSettings";

		print "-------------------------------------------------------\n";
		print "$0: Building '", BOLD, BRIGHT_CYAN, "$scheme", RESET, "'\n";

		open (CMD, "$opt_command 2>&1 |") || die "Can't get settings\n";
		while (<CMD>) {
			chop;
			s/^\s+//;
	
			if (/MARKETING_VERSION/) {
				($var, $equal, $value) = split (/\s+/, $_);
				$major_minor = $value;
			}
	
			if (/CURRENT_PROJECT_VERSION/) {
				($var, $equal, $value) = split (/\s+/, $_);
				$build = $value;
			}
		}

		$version = "$major_minor.$build";

		print "$0: Version is '", BOLD, BRIGHT_YELLOW, "$version", RESET, "'\n";
	}

	$output					= "./releases/$scheme";
	if ($version ne "") { $output .= "-$version"; }

	$iOSDevicePath			="$output/Release-iphoneos";
	$iOSSimulatorPath		="$output/Release-iphonesimulator";

	$sim_command			="xcodebuild -workspace $workspace.xcworkspace -scheme $scheme -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR=../$output SKIP_INSTALL=NO clean build";
	$ios_command			="xcodebuild -workspace $workspace.xcworkspace -scheme $scheme -sdk iphoneos ONLY_ACTIVE_ARCH=NO BUILD_DIR=../$output SKIP_INSTALL=NO clean build";

	if ($scheme eq "iOSDFULibrary") {
		$xc1_command			= "xcodebuild -create-xcframework -framework $iOSDevicePath/iOSDFULibrary/iOSDFULibrary.framework -framework $iOSSimulatorPath/iOSDFULibrary/iOSDFULibrary.framework -output $output/iOSDFULibrary.xcframework";
		$xc2_command			= "xcodebuild -create-xcframework -framework $iOSDevicePath/ZIPFoundation/ZIPFoundation.framework -framework $iOSSimulatorPath/ZIPFoundation/ZIPFoundation.framework -output $output/ZIPFoundation.xcframework";	
	}
	else {
		$xc1_command			= "xcodebuild -create-xcframework -framework $iOSDevicePath/$scheme.framework -framework $iOSSimulatorPath/$scheme.framework -output $output/$scheme.xcframework";
		$xc2_command			= "";
	}

	print "$0: Commands:\n";
	print "$0:     Simulator Build: ", BOLD, BRIGHT_GREEN, "$sim_command\n", RESET;
	print "$0:     OS Build:        ", BOLD, BRIGHT_GREEN, "$ios_command\n", RESET;
	print "$0:     XC Assembler:    ", BOLD, BRIGHT_GREEN, "$xc1_command\n", RESET;

	if ($xc2_command ne "") {
		print "$0:     XC Assembler:    "; print BRIGHT_GREEN, "$xc2_command\n", RESET;	
	}

	if ($keep == 1) {
		print "\n";
		print "$0: "; print BOLD, BRIGHT_YELLOW, "Keeping the frameworks after assembling\n", RESET;
		print "\n";
	}


	$processStartTime	= time();

	if (!(-d "$output")) {
		print "$0: No Output Directory.  Creating...\n";
		make_path ($output);
	}

	system("rm -rf $output/*");

	# Run build commands.  If any command fails, the application exits

	&RunCommand ("iPhone Simulator Framework", "$sim_command", "BUILD FAILED");
	&RunCommand ("iPhone Device Framework", "$ios_command", "BUILD FAILED");
	&RunCommand ("XCFramework", "$xc1_command", "error");

	if ($xc2_command ne "") {
		&RunCommand ("XCFramework", "$xc2_command", "error");
	}

	if ($keep != 1) {
		print "$0: Cleaning up (removing intermediate files)\n";
		system ("rm -rf $iOSSimulatorPath");
		system ("rm -rf $iOSDevicePath");
	}

	print "$0: XCFramework location: '"; print BOLD, BRIGHT_YELLOW, "$output", RESET, "'\n";

	print "\n";

	$totalTime = $endTime - $processStartTime;

	print "$0: Complete.  Elapsed time '", BOLD, BRIGHT_YELLOW, &SecondsToTime($totalTime), RESET, "'\n";
	print "\n\n";
}

$allTotalTime = time() - $allStartTime;

print "\n";
print "$0: ", "Total time: '", BOLD, BRIGHT_YELLOW, &SecondsToTime($allTotalTime), RESET "'\n";

print "\n\n";


