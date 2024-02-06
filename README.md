# Backup-Buddy
Backup your things with Rsync and NodeJS!

Backup-Buddy is a convenience wrapper written in Node that uses Rsync to asynchronously back up your files and folders in parallel. It's super quick!

## How It Works

Backup-buddy is a program written in NodeJS that parses a yaml file, constructs a list of arguments for rsync to run, and executes rsync processes for each backup path listed. This means if you have 10 folders to back up, Backup-buddy will invoke 10 rsync processes _at the same time_. Use with care!

Backup-buddy's uses yaml definition files to build commands that rsync will use. An example of a job file can be found [here](https://github.com/egeexyz/backup-buddy/blob/main/jobs/example.yaml).

## How To Use

From the terminal, first install it:

`npm install -g backup-buddy`

`backup-buddy my_backup_file.yml`

Backup-buddy's behavior should be identical to rsync's.

For example, adding `/etc/` or `/etc/*` will back up all files (including folders & sub-folders) but not the etc folder itself. Adding `/etc` (without the trailing `/` or `*`) will backup the folder **and** everything inside it.
