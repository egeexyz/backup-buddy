# Backup-Buddy

Backup (or restore) your things with Rsync and Ruby!

Backup-Buddy is a dumb harness around rsync. It parses a YAML manifest, spawns lightweight rsync tasks, and runs them through a thread pool. The Ruby GIL releases during I/O, so all rsync processes genuinely run in parallel!

## What It Does

Backup-buddy reads in a YAML manifest and feeds the paths into a worker thread pool. If you got 10 folders and a concurrency of 3, it runs 3 rsyncs at a time until all 10 are done.

Since rsync is symmetric, you can also use Backup-buddy as a **restore tool** — just swap the source and destination in your manifest.

## What It Doesn't

Backup-Buddy is designed specifically to be a dumb harness that spawns rsync workers using a yaml manifest and a cli as the entry point.

It does **not** manage SSH connections, users, or permissions - it simply invokes rsync and gets out of the way. Configure your remote hosts in `~/.ssh/config` and rsync will pick them up automatically.

It also does not compress or otherwise archive files - it simply copies them from one place to another. The previous version had a compression feature but it was complicated and I never used it so I removed it.

## How It Started

Every once in a while, I back up all my files. I got tired of doing it manually so I started using rsync. Then, I got tired of typing rsync so I write it into a script. Then, I got tired of typing the script so I wrote a program to do it for me.

The first version was written in NodeJS so I got async for free. However, I learned without concurrency limits, rsync will happily take your system down. I like Ruby a bit better than JavaScript so I rewrote it and added some cool features like a thread pool.

## Requirements

- **Ruby** >= 3.1
- **rsync** available to your system

## SSH Configuration

Backup-Buddy delegates all connection handling to rsync, which reads your `~/.ssh/config`. Set up your hosts there and then reference the host in your manifest paths.

## Installation

```bash
gem install backup-buddy
```

## Usage

```bash
backup-buddy manifests/my_backup.yaml
```

## License

MIT
