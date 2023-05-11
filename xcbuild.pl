#!/usr/bin/perl

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
	print "    $0 -s [ alterBTSDK | kairosBTSDK | ethosBTSDK | livotalBTSDK | universalBTSDK | pods ] [-k]\n";
	print "\n\n";
	
	print "The scheme (-s or --scheme) is the scheme in that workspace\n";
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
	print "$0:    ";  print BRIGHT_GREEN, "Completed Building iPhone Simulator Framework in '$elapsed' seconds\n", RESET;
	print "\n";	
}

GetOptions ('s|scheme=s' => \$scheme,
			'k|keep-frameworks' => \$keep);

if ($scheme eq "") {
	&Usage;
	exit (0);
}

$workspace				= "biostrapDeviceSDK";

if ($scheme eq "pods") {
	$scheme = "iOSDFULibrary";	# Will also build ZIPFoundation
}
else {
	$opt_command			="xcodebuild -workspace $workspace.xcworkspace -scheme $scheme -showBuildSettings";

	print "\n";
	print "$0: Getting '$scheme' Version...\n\n";

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

	print BOLD, BRIGHT_YELLOW, "$0: '$scheme' Version is '$version'\n", RESET;
}

$output					= "./Builds/$scheme";
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

print "\n";
print "$0: Commands that will be run:\n";
print "$0:     Simulator Build: "; print BRIGHT_GREEN, "$sim_command\n", RESET;
print "$0:     OS Build:        "; print BRIGHT_GREEN, "$ios_command\n", RESET;
print "$0:     XC Assembler:    "; print BRIGHT_GREEN, "$xc1_command\n", RESET;

if ($xc2_command ne "") {
	print "$0:     XC Assembler:    "; print BRIGHT_GREEN, "$xc2_command\n", RESET;	
}

if ($keep == 1) {
	print "\n";
	print "$0: "; print BOLD, BRIGHT_YELLOW, "Keeping the frameworks after assembling\n", RESET;
	print "\n";
}


print "\n";
print "$0: Building to: "; print BOLD, "$output\n", RESET;

$processStartTime	= time();

if (!(-d "$output")) {
	print "$0: No Output Directory.  Creating...\n\n";
	make_path ($output);
}

system("rm -rf $output/*");
print "\n";

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

print "\n";
print "$0: XCFramework located: "; print BOLD, "$output", RESET;
print "\n";
print "\n";

$totalTime = $endTime - $processStartTime;

print "$0:  Complete.  Elapsed time '$totalTime' seconds\n";
print "\n\n";

#system ("open $output");

