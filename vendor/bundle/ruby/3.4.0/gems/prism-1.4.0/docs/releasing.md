# Releasing

To release a new version of Prism, perform the following steps:

## Preparation

* Update the `CHANGELOG.md` file.
  * Add a new section for the new version at the top of the file.
  * Fill in the relevant changes — it may be easiest to click the link for the `Unreleased` heading to find the commits.
  * Update the links at the bottom of the file.
* Update the version numbers in the various files that reference them:

```sh
export PRISM_MAJOR="x"
export PRISM_MINOR="y"
export PRISM_PATCH="z"
export PRISM_VERSION="$PRISM_MAJOR.$PRISM_MINOR.$PRISM_PATCH"
ruby -pi -e 'gsub(/spec\.version = ".+?"/, %Q{spec.version = "#{ENV["PRISM_VERSION"]}"})' prism.gemspec
ruby -pi -e 'gsub(/EXPECTED_PRISM_VERSION ".+?"/, %Q{EXPECTED_PRISM_VERSION "#{ENV["PRISM_VERSION"]}"})' ext/prism/extension.h
ruby -pi -e 'gsub(/PRISM_VERSION_MAJOR \d+/, %Q{PRISM_VERSION_MAJOR #{ENV["PRISM_MAJOR"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION_MINOR \d+/, %Q{PRISM_VERSION_MINOR #{ENV["PRISM_MINOR"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION_PATCH \d+/, %Q{PRISM_VERSION_PATCH #{ENV["PRISM_PATCH"]}})' include/prism/version.h
ruby -pi -e 'gsub(/PRISM_VERSION ".+?"/, %Q{PRISM_VERSION "#{ENV["PRISM_VERSION"]}"})' include/prism/version.h
ruby -pi -e 'gsub(/"version": ".+?"/, %Q{"version": "#{ENV["PRISM_VERSION"]}"})' javascript/package.json
ruby -pi -e 'gsub(/lossy\(\), ".+?"/, %Q{lossy(), "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism-sys/tests/utils_tests.rs
ruby -pi -e 'gsub(/\d+, "prism major/, %Q{#{ENV["PRISM_MAJOR"]}, "prism major})' templates/java/org/prism/Loader.java.erb
ruby -pi -e 'gsub(/\d+, "prism minor/, %Q{#{ENV["PRISM_MINOR"]}, "prism minor})' templates/java/org/prism/Loader.java.erb
ruby -pi -e 'gsub(/\d+, "prism patch/, %Q{#{ENV["PRISM_PATCH"]}, "prism patch})' templates/java/org/prism/Loader.java.erb
ruby -pi -e 'gsub(/MAJOR_VERSION = \d+/, %Q{MAJOR_VERSION = #{ENV["PRISM_MAJOR"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/MINOR_VERSION = \d+/, %Q{MINOR_VERSION = #{ENV["PRISM_MINOR"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/PATCH_VERSION = \d+/, %Q{PATCH_VERSION = #{ENV["PRISM_PATCH"]}})' templates/javascript/src/deserialize.js.erb
ruby -pi -e 'gsub(/MAJOR_VERSION = \d+/, %Q{MAJOR_VERSION = #{ENV["PRISM_MAJOR"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/MINOR_VERSION = \d+/, %Q{MINOR_VERSION = #{ENV["PRISM_MINOR"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/PATCH_VERSION = \d+/, %Q{PATCH_VERSION = #{ENV["PRISM_PATCH"]}})' templates/lib/prism/serialize.rb.erb
ruby -pi -e 'gsub(/^version = ".+?"/, %Q{version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism-sys/Cargo.toml
ruby -pi -e 'gsub(/^version = ".+?"/, %Q{version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism/Cargo.toml
ruby -pi -e 'gsub(/^ruby-prism-sys = \{ version = ".+?"/, %Q{ruby-prism-sys = \{ version = "#{ENV["PRISM_VERSION"]}"})' rust/ruby-prism/Cargo.toml
```

* Update the `Gemfile.lock` file:

```sh
chruby ruby-3.5.0-dev
bundle install
```

* Update the version-specific lockfiles:

```sh
bin/prism bundle install
```

* Update the cargo lockfiles:

```sh
bundle exec rake cargo:build
```

* Commit all of the updated files:

```sh
git commit -am "Bump to v$PRISM_VERSION"
```

* Push up the changes:

```sh
git push
```

## Publishing

* Update the GitHub release page with a copy of the latest entry in the `CHANGELOG.md` file.
* Publish the gem to [rubygems.org](rubygems.org). Note that you must have access to the `prism` gem to do this.

```sh
bundle exec rake release
```

* Generate the `wasm` artifact (or download it from GitHub actions and put it in `javascript/src/prism.wasm`).

```sh
make wasm
```

* Publish the JavaScript package to [npmjs.com](npmjs.com). Note that you must have access to the `@ruby/prism` package to do this.

```sh
npm publish
```

* Publish the rust crate to [crates.io](crates.io). Note that you must have access to the `ruby-prism-sys` and `ruby-prism` crates to do this.

```sh
bundle exec rake cargo:publish:real
```
