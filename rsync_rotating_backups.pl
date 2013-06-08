#!/usr/bin/perl

###################################################################################
# License: GPU General Public License. 
# License details here: http://www.gnu.org/licenses/gpl.html
#
# More info and background here: 
# http://www.catchmecode.com/blog/2013/06/01/rotating-backups-with-rsync/
###################################################################################
use warnings;
use strict;

my $rsyncCmd = `which rsync`;
my $ssh = `which ssh`;
chomp $rsyncCmd; chomp $ssh;

my $hostnameCmd = `which hostname`;
my $hostname = `$hostnameCmd`;
chomp $hostname;

###################################################################################
# Config part - edit these
###################################################################################

# SSH user@host
my $login = 'user@server';

# How many backups to keep. If you run the script once a day, 7 = 7 days of backups
my $backupsPerCycle = 7;

# Full base path on the backup host where the backups are kept - defaults to
my $backupRootDir = "/home/user/backup/".$hostname."/backup_";

# Where the list of folders to back up are kept - defaults to ~/.backup_targets
my $backupFolderList = "$ENV{HOME}/.backup_targets";

###################################################################################
# End config part
###################################################################################

open my $file, $backupFolderList or die "Cannot read folder list for backup, tried path is $backupFolderList";
my @backupFolderListContents = <$file>;
close $file;

moveOldBackups();

for my $backupFolder (@backupFolderListContents) {
    chomp $backupFolder;
    next unless $backupFolder;
    backupDir( $backupFolder );    
}

sub moveOldBackups {
    my @commands;

    print "rotating old dirs\n";

    my $removeOldestDirIfExists = "if [ -d $backupRootDir$backupsPerCycle ]; then rm -rf $backupRootDir$backupsPerCycle; fi";
    push @commands, $removeOldestDirIfExists;

    foreach my $i (reverse (1..$backupsPerCycle-1)) {
        my $p = $i + 1;

        my $moveDirsOneLevelUpIfExists = "if [ -d $backupRootDir$i ]; then mv $backupRootDir$i $backupRootDir$p; fi";
        push @commands, $moveDirsOneLevelUpIfExists;
    }
    push @commands, "mkdir -p ${backupRootDir}1";

    my $cmd = join(';',@commands);

    system("$ssh $login \"$cmd\" 2>&1");
}

#  Copies the local dir and preserves the folder structure onto the mirroring host
sub backupDir {
    my $path = shift;
    my @commands;

    print "running rsync on $path\n";

    my $current_dir = "${backupRootDir}2";
    my $newest_dir = "${backupRootDir}1";

    # Remove any first slash on the destination
    (my $dest_path = $path) =~ s/^\///;

    my $rsyncCmdLine = "$ssh $login \"[ -d $current_dir ]\" && $rsyncCmd -e ssh -avHzrR --delete --link-dest=\"$current_dir\" $path $login:$newest_dir ||";
    $rsyncCmdLine .= " $rsyncCmd -e ssh -avHzrR --delete $path $login:$newest_dir";

    system($rsyncCmdLine)
}
