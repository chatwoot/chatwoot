Sidekiq
==============

[![Gem Version](https://badge.fury.io/rb/sidekiq.svg)](https://rubygems.org/gems/sidekiq)
![Build](https://github.com/sidekiq/sidekiq/workflows/CI/badge.svg)

Simple, efficient background processing for Ruby.

Sidekiq uses threads to handle many jobs at the same time in the
same process.  It does not require Rails but will integrate tightly with
Rails to make background processing dead simple.


Requirements
-----------------

- Redis: Redis 6.2+ or Dragonfly 1.13+
- Ruby: MRI 2.7+ or JRuby 9.3+.

Sidekiq 7.0 supports Rails 6.0+ but does not require it.
As of 7.2, Sidekiq supports Dragonfly as an alternative to Redis for data storage.

Installation
-----------------

    bundle add sidekiq


Getting Started
-----------------

See the [Getting Started wiki page](https://github.com/sidekiq/sidekiq/wiki/Getting-Started) and follow the simple setup process.
You can watch [this YouTube playlist](https://www.youtube.com/playlist?list=PLjeHh2LSCFrWGT5uVjUuFKAcrcj5kSai1) to learn all about
Sidekiq and see its features in action.  Here's the Web UI:

![Web UI](https://github.com/sidekiq/sidekiq/raw/main/examples/web-ui.png)

Performance
---------------

The benchmark in `bin/sidekiqload` creates 500,000 no-op jobs and drains them as fast as possible, assuming a fixed Redis network latency of 1ms.
This requires a lot of Redis network I/O and JSON parsing.
This benchmark is IO-bound so we increase the concurrency to 25.
If your application is sending lots of emails or performing other network-intensive work, you could see a similar benefit but be careful not to saturate the CPU.

Version | Time to process 500k jobs | Throughput (jobs/sec) | Ruby | Concurrency | Job Type
-----------------|------|---------|---------|------------------------|---
Sidekiq 7.0.3 | 21.3 sec| 23,500 | 3.2.0+yjit | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 33.8 sec| 14,700 | 3.2.0+yjit | 30 | ActiveJob 7.0.4
Sidekiq 7.0.3 | 23.5 sec| 21,300 | 3.2.0 | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 46.5 sec| 10,700 | 3.2.0 | 30 | ActiveJob 7.0.4
Sidekiq 7.0.3 | 23.0 sec| 21,700 | 2.7.5 | 30 | Sidekiq::Job
Sidekiq 7.0.3 | 46.5 sec| 10,850 | 2.7.5 | 30 | ActiveJob 7.0.4

Most of Sidekiq's overhead is Redis network I/O.
ActiveJob adds a notable amount of CPU overhead due to argument deserialization and callbacks.
Concurrency of 30 was determined experimentally to maximize one CPU without saturating it.

Want to Upgrade?
-------------------

Use `bundle up sidekiq` to upgrade Sidekiq and all its dependencies.
Upgrade notes between each major version can be found in the `docs/` directory.

I also sell Sidekiq Pro and Sidekiq Enterprise, extensions to Sidekiq which provide more
features, a commercial-friendly license and allow you to support high
quality open source development all at the same time.  Please see the
[Sidekiq](https://sidekiq.org/) homepage for more detail.


Problems?
-----------------

**Please do not directly email any Sidekiq committers with questions or problems.**
A community is best served when discussions are held in public.

If you have a problem, please review the [FAQ](https://github.com/sidekiq/sidekiq/wiki/FAQ) and [Troubleshooting](https://github.com/sidekiq/sidekiq/wiki/Problems-and-Troubleshooting) wiki pages.
Searching the [issues](https://github.com/sidekiq/sidekiq/issues) for your problem is also a good idea.

Sidekiq Pro and Sidekiq Enterprise customers get private email support.
You can purchase at https://sidekiq.org; email support@contribsys.com for help.

Useful resources:

* Product documentation is in the [wiki](https://github.com/sidekiq/sidekiq/wiki).
* Occasional announcements are made to the [@sidekiq](https://ruby.social/@sidekiq) Mastodon account.
* The [Sidekiq tag](https://stackoverflow.com/questions/tagged/sidekiq) on Stack Overflow has lots of useful Q &amp; A.

Every Thursday morning is Sidekiq office hour: I video chat and answer questions.
See the [Sidekiq support page](https://sidekiq.org/support.html) for details.

Contributing
-----------------

Please see [the contributing guidelines](https://github.com/sidekiq/sidekiq/blob/main/.github/contributing.md).

License
-----------------

Please see [LICENSE.txt](https://github.com/sidekiq/sidekiq/blob/main/LICENSE.txt) for licensing details.
The license for Sidekiq Pro and Sidekiq Enterprise can be found in [COMM-LICENSE.txt](https://github.com/sidekiq/sidekiq/blob/main/COMM-LICENSE.txt).

Author
-----------------

Mike Perham, [@getajobmike](https://ruby.social/@getajobmike) / [@sidekiq](https://ruby.social/@sidekiq), [https://www.mikeperham.com](https://www.mikeperham.com) / [https://www.contribsys.com](https://www.contribsys.com)
