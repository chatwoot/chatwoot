### 0.9.1 / 2022-05-19

#### CLI

* Improve the readability of the suggested gem versions to upgrade to
  (pull #331).

#### Rake Task

* Fixed a regression introduced in 0.9.0 where the `bundler:audit` rake task
  was not exiting with an error status code if vulnerabilities were found.
  Now when the `bundler-audit` command fails, the rake task will also exit with
  the `bundler-audit` command's error code.
* If the `bundler-audit` command could not be found for some reason raise the
  {Bundler::Audit::Task::CommandNotFound} exception.

### 0.9.0.1 / 2021-08-31

* Add a workaround for Psych < 3.1.0 to support running on Ruby < 2.6.
  (issue #319)
  * Although, Ruby 2.5 and prior have all reached [End-of-Life] and
  are no longer receiving security updates. It is strongly advised that you
  should upgrade to a currently supported version of Ruby.

[End-of-Life]: https://www.ruby-lang.org/en/downloads/branches/

### 0.9.0 / 2021-08-31

* Load advisory metadata using `YAML.safe_load`. (issue #302)
  * Explicitly permit the `Date` class for Psych >= 4.0.0 and Ruby >= 3.1.0.
* Added {Bundler::Audit::Advisory#to_h}. (pull #310)
* Added {Bundler::Audit::Database#commit_id}.

#### CLI

* Added the `--config` option. (pull #306)
* Added the `junit` output format (ex: `--format junit`). (pull #314)
* Add missing output for CVSSv3 criticality information. (pull #302)
  * Include criticality information in the JSON output as well. (pull #310)
* `bundle-audit stats` now prints the commit ID of the ruby-advisory-db.
* Fixed a deprecation warning from Thor. (issue #317)

#### Rake Task

* Add the `bundle:audit:update` task for updating the [ruby-advisory-db].
  (pull #296)
* Aliased `bundle:audit` to `bundle:audit:check`.
* Aliased `bundler:audit:*` to `bundle:audit:*`.
* Rake tasks now execute `bundle-audit` command as a subprocess to ensure
  isolation.

### 0.8.0 / 2021-03-10

* No longer vendor [ruby-advisory-db].
* Added {Bundler::Audit::Configuration}.
  * Supports loading YAML configuration data from a `.bundler-audit.yml` file.
* Added {Bundler::Audit::Results}.
* Added {Bundler::Audit::Report}.
* Added {Bundler::Audit::CLI::Formats}.
* Added {Bundler::Audit::CLI::Formats::Text}.
* Added {Bundler::Audit::CLI::Formats::JSON}.
* Added {Bundler::Audit::Database::DEFAULT_PATH}.
* Added {Bundler::Audit::Database.exists?}.
* Added {Bundler::Audit::Database#git?}.
* Added {Bundler::Audit::Database#update!}.
  * Will raise a {Bundler::Audit::Database::UpdateFailed UpdateFailed}
    exception, if the `git pull` command fails.
* Added {Bundler::Audit::Database#last_updated_at}.
* Added {Bundler::Audit::Scanner#report}.
* {Bundler::Audit::Database::USER_PATH} is now `Gem.user_home` aware.
  * `Gem.user_home` will try to infer `HOME`, even if it is not set.
* {Bundler::Audit::Database#download} will now raise a
  {Bundler::Audit::Database::DownloadFailed DownloadFailed} exception, if the
  `git clone` command fails.
* {Bundler::Audit::Scanner#initialize}:
  * Now accepts an additional `database` and `config_dot_file` arguments.
  * Will now raise a `Bundler::GemfileLockNotFound` exception,
    if the given `Gemfile.lock` file cannot be found.
* {Bundler::Audit::Scanner#scan_sources} will now ignore any source with a
  `127.0.0.0/8` or `::1/128` IP address.
* {Bundler::Audit::Scanner#scan_specs} will ignore any advisories listed in
  {Bundler::Audit::Configuration#ignore}, which is loaded from the
  `.bundler-audit.yml` file.
* Deprecated {Bundler::Audit::Database.update!} in favor of
  {Bundler::Audit::Database#update! #update!}.
* Removed `Bundler::Audit::Database::VENDORED_PATH`.
* Removed `Bundler::Audit::Database::VENDORED_TIMESTAMP`.

#### CLI

* Require [thor] ~> 1.0.
* Added `bundler-audit stats`.
* Added `bundler-audit download`.
* `bundler-audit check`:
  * Now accepts a optional `DIR` argument for the project directory.
    * `bundler-audit check` will now print an explicit error message and exit,
      if the given `DIR` does not exist.
  * Will now auto-download [ruby-advisory-db] to ensure the latest advisory
    information is used on first run.
  * Now supports a `--database` option for specifying a path
    to an alternative [ruby-advisory-db] copy.
  * Now supports a `--gemfile-lock` option for specifying a
    custom `Gemfile.lock` file within the project directory.
  * Now supports a `--format` option for specifying the
    desired format. `text` and `json` are supported, but other custom formats
    can be loaded. See {Bundler::Audit::CLI::Formats}.
  * Now supports a `--output` option for writing the report output to a file.
  * Prints both CVE and GHSA IDs.
* Print all error messages to stderr.
* No longer print number of advisories in `bundler-audit version`.

### 0.7.0.1 / 2020-06-12

* Forgot to populate `data/ruby-advisory-db`.

### 0.7.0 / 2020-06-12

* Require [thor] >= 0.18, < 2.
* Added {Bundler::Audit::Advisory#ghsa} (@rschultheis).
* Added {Bundler::Audit::Advisory#cvss_v3} (@ahamlin-nr).
* Added {Bundler::Audit::Advisory#identifiers} (@rschultheis).
* Updated {Bundler::Audit::Advisory#criticality} ranges (@reedloden).
* Avoid rebasing the ruby-advisory-db when updating (@nicknovitski).
* Fixed issue with Bundler 2.x where source URIs are no longer parsed as
  `URI::HTTP` objects, but as `Bundler::URI::HTTP` objects. (@milgner)
* Make it more explicit that git is required for database updates (@fatkodima)

### 0.6.1 / 2019-01-17

* Require bundler `>= 1.2.0, < 3` to support [bundler] 2.0.

### 0.6.0 / 2017-07-18

* Added `--quiet` option to `check` and `update` commands (@jaredbeck).
* Added `bin/bundler-audit` which will be executed when `bundle audit` is ran
  (@vassilevsky).

### 0.5.0 / 2016-02-28

* Added {Bundler::Audit::Task}.
* Added {Bundler::Audit::Advisory#date}.
* Added {Bundler::Audit::Advisory#cve_id}.
* Added {Bundler::Audit::Advisory#osvdb_id}.
* Allow insecure gem sources (`http://` and `git://`), if they are hosted on a
  private network.

#### CLI

* Added the `--update` option to `bundler-audit check`.
* `bundler-audit update` now returns a non-zero exit status on error.
* `bundler-audit update` only updates `~/.local/share/ruby-advisory-db`, if it is a git
  repository.

### 0.4.0 / 2015-06-30

* Require ruby >= 1.9.3 due to i18n gem deprecating < 1.9.3.
* Added {Bundler::Audit::Advisory#osvdb}.
* Resolve the IP addresses of gem sources and ignore intranet gem sources.
  (PR #90)
* Use ISO8601 date format when querying the git timestamp of ruby-advisory-db.
  (PR #92)

#### CLI

* Print the CVE or OSVDB id.
* No longer print "Unpatched versions found!" when an insecure gem source
  is detected. (PR #84)

### 0.3.1 / 2014-04-20

* Added thor ~> 0.18 as a dependency.
* No longer rely on the vendored version of thor within bundler.
* Store the timestamp of when `data/ruby-advisory-db` was last updated in
  `data/ruby-advisory-db.ts`.
* Use `data/ruby-advisory-db.ts` instead of the creation time of the
  `dataruby-advisory-db` directory, which is always the install time
  of the rubygem.

### 0.3.0 / 2013-10-31

* Added {Bundler::Audit::Database.update!} which uses `git` to download
  [ruby-advisory-db] to `~/.local/share/ruby-advisory-db`.
* {Bundler::Audit::Database.path} now returns the path to either
  `~/.local/share/ruby-advisory-db` or the vendored copy, depending on which
  is more recent.

#### CLI

* Added the `bundler-audit update` sub-command.

### 0.2.0 / 2013-03-05

* Require RubyGems >= 1.8.0. Prior versions of RubyGems could not correctly
  parse approximate version requirements (`~> 1.2.3`).
* Updated the [ruby-advisory-db].
* Added {Bundler::Audit::Advisory#unaffected_versions}.
* Added {Bundler::Audit::Advisory#unaffected?}.
* Added {Bundler::Audit::Advisory#patched?}.
* Renamed `Advisory#cve` to {Bundler::Audit::Advisory#id}.

### 0.1.2 / 2013-02-17

* Require [bundler] ~> 1.2.
* Vendor a full copy of the [ruby-advisory-db].
* Added {Bundler::Audit::Advisory#path} for debugging purposes.
* Added {Bundler::Audit::Advisory#to_s} for debugging purposes.

#### CLI

* Simply parse the `Gemfile.lock` instead of loading the bundle (@grosser).
* Exit with non-zero status on failure (@grosser).

### 0.1.1 / 2013-02-12

* Fixed a Ruby 1.8 syntax error.

### Advisories

* Imported advisories from the [Ruby Advisory DB][ruby-advisory-db].
  * [CVE-2011-0739](http://www.osvdb.org/show/osvdb/70667)
  * [CVE-2012-2139](http://www.osvdb.org/show/osvdb/81631)
  * [CVE-2012-2140](http://www.osvdb.org/show/osvdb/81632)
  * [CVE-2012-267](http://osvdb.org/83077)
  * [CVE-2012-1098](http://osvdb.org/79726)
  * [CVE-2012-1099](http://www.osvdb.org/show/osvdb/79727)
  * [CVE-2012-2660](http://www.osvdb.org/show/osvdb/82610)
  * [CVE-2012-2661](http://www.osvdb.org/show/osvdb/82403)
  * [CVE-2012-3424](http://www.osvdb.org/show/osvdb/84243)
  * [CVE-2012-3463](http://osvdb.org/84515)
  * [CVE-2012-3464](http://www.osvdb.org/show/osvdb/84516)
  * [CVE-2012-3465](http://www.osvdb.org/show/osvdb/84513)

### CLI

* If the advisory has no `patched_versions`, recommend removing or disabling
  the gem until a patch is made available.

### 0.1.0 / 2013-02-11

* Initial release:
  * Checks for vulnerable versions of gems in `Gemfile.lock`.
  * Prints advisory information.
  * Does not require a network connection.

#### Advisories

* [CVE-2013-0269](http://direct.osvdb.org/show/osvdb/90074)
* [CVE-2013-0263](http://osvdb.org/show/osvdb/89939)
* [CVE-2013-0155](http://osvdb.org/show/osvdb/89025)
* [CVE-2013-0156](http://osvdb.org/show/osvdb/89026)
* [CVE-2013-0276](http://direct.osvdb.org/show/osvdb/90072)
* [CVE-2013-0277](http://direct.osvdb.org/show/osvdb/90073)
* [CVE-2013-0333](http://osvdb.org/show/osvdb/89594)

[bundler]: http://gembundler.com/
[thor]: http://whatisthor.com/
[ruby-advisory-db]: https://github.com/rubysec/ruby-advisory-db#readme
