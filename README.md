# Short description
Its a script that does rotational backups on your folders of choice. No compression involved - the files are mirrored onto the backup machine and hard links keeps redundancy down between snapshots. Done in perl via ssh and rsync (sshd  needs to be installed on the backup machine, ssh keys are optional but very handy if you automate it with cron / anacron).

For more background and running it via anacron - check the accompanying longer blog post [http://www.catchmecode.com/blog/2013/06/01/rotating-backups-with-rsync/](http://www.catchmecode.com/blog/2013/06/01/rotating-backups-with-rsync/)

# Script config
There are a couple of variables you should change - they're marked with a huge # Config part - edit these header at the top of the script.
```perl
# SSH user@host
my $login = 'user@server';
```
SSH user and remote backup host (as you would specify it in an ssh command line).

```perl
# How many backups to keep. If you run the script once a day, 7 = 7 days of backups
my $backupsPerCycle = 7;
```
Number of backups in a cycle. Will create 7 folders / snapshots - a weeks worth of backups if you run it once every day.

```perl
# Full base path on the backup host where the backups are kept - defaults to
my $backupRootDir = "/home/user/backup/".$hostname."/backup_";
```
I've configured the backups to use the hostname of the backed up machine as the root folder. This way its easy to see where from what machine it came and then navigate from there as if it were on the local machine.

```perl
# Where the list of folders to back up are kept - defaults to ~/.backup_targets
my $backupFolderList = "$ENV{HOME}/.backup_targets";
```
The folders to back up are configured via a file called `.backup_targets` in your home folder. The file contains folders you want backed up, separated by newline. Whitespace is ignored in the file. Example:
```
/home/user/Desktop
/home/user/Pictures/
```
Will back up all files recursively in the home Desktop and Pictures folder. The reason the full path is given is that its mirrored with its full path on the backup machine. So these folders above are found under:
```
/home/storage/backup/user/client/backup_1/home/user/Desktop
/home/storage/backup/user/client/backup_1/home/user/Pictures
```
#Optional config
You might have to change these, they'll try to find the executable by themselves (via [which](http://linux.die.net/man/1/which)) but if they don't succeed - feed them the location of the binary:
```perl
my $rsyncCmd = `which rsync`;
my $ssh = `which ssh`;
```