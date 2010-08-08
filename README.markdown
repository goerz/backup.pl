# backup.pl

[http://github.com/goerz/backup.pl](http://github.com/goerz/backup.pl)

Author: [Michael Goerz](http://michaelgoerz.net)

INTRO

This code is licensed under the [GPL](http://www.gnu.org/licenses/gpl.html)


## Install ##

Store the `backup.pl` script anywhere in your `$PATH`.

## Usage ##

You have to write a backup profile, and then call `backup.pl` as
    
    backup.pl profile.bkp

An example profile is

    # INCLUDE
    find /home/goerz/ -newer /home/goerz/.backup.pl/dailybackup_timestamp
        
    # EXCLUDE
    find /home/goerz/Mail/
    find /home/goerz/mbox
    find /home/goerz/Sent
    find /home/goerz/.vmware
    find /home/goerz/.backup.pl
    
    # VARIABLES
    splitsize = 0
    excludepattern = '\.svn'
    excludepattern = '^/home/goerz/\.thunderbird/'
    excludepattern = '^/home/goerz/\.kde/'
    excludepattern = '\.svn'
    excludepattern = '^/home/goerz/\.beagle/'
    excludepattern = '^/home/goerz/mp3/'
    excludepattern = '^/home/goerz/.google/desktop'
    excludepattern = '^/home/goerz/\.googleearth\/Cache/'
    excludepattern = '^/home/goerz/\.googleearth\/Registry'
    excludepattern = '^/home/goerz/Music/'
    excludepattern = '^/home/goerz/.thumbnails/'
    excludepattern = '^/home/goerz/Trash'
    excludepattern = '^/home/goerz/Download/'
    excludepattern = 'backup\.spool'
    excludepattern = '^/home/goerz/backup/'
    excludepattern = '^/home/goerz/\.mozilla'
    gzip = 1
    outfile = /home/goerz/backup/daily
    postcommand = touch /home/goerz/.backup.pl/dailybackup_timestamp

This call will backup a number of folders defined in the profile into one or
more archive files.

Generally, a profile consists of three sections, #INCLUDE, #EXCLUDE, 
and #VARIABLES. The #INCLUDE section lists all directories that should be
included in the backup (either directly or as a command yielding the desired
directories as output), whereas the #EXCLUDE section defines exceptions, in the
same way.

The #VARIABLES section defines options for the backup script. The possible
options in this section are `splitsize`, `excludepattern`, `gzip`, `outfile`,
`precommand`, `postcommand`:

    splitsize         Max. size of one output archive. The backup will be split
                      into one or more archives, each at most with a size of 
                      splitsize
    excludepattern    Any file matching this pattern is excluded from the
                      backup
    outfile           Base name for the output. The actual output archive will
                      have the name outfile.TIME.NO.tgz, where TIME is a
                      timestamp, and NO is the number of the output file (in
                      case of split files)
    precommand        A command to run before the actual backup
    postcommand       A command to run after the actual backup
