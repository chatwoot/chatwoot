**Master**

Get upgrade notes from Sprockets 3.x to 4.x at https://github.com/rails/sprockets/blob/master/UPGRADING.md

## 4.2.1

- Fix for precompile issues when multiple extensions map to the same MIME type (eg. `.jpeg` / `.jpg`). [#781](https://github.com/rails/sprockets/pull/781)
- Fix `application/css-sourcemap+json` charset [#764](https://github.com/rails/sprockets/pull/764)
- Fix compatibility with Rack 2 applications. [#790](https://github.com/rails/sprockets/pull/790)

## 4.2.0

- Rack 3 compatibility. [#758](https://github.com/rails/sprockets/pull/758)
- Fix thread safety of `Sprockets::CachedEnvironment` and `Sprockets::Cache::MemoryStore`. [#771](https://github.com/rails/sprockets/pull/771)
- Add support for Rack 3.0. Headers set by sprockets will now be lower case. [#758](https://github.com/rails/sprockets/pull/758)
- Make `Sprockets::Utils.module_include` thread safe on JRuby. [#759](https://github.com/rails/sprockets/pull/759)
- Fix typo in `asset.rb` file. [#768](https://github.com/rails/sprockets/pull/768)

## 4.1.1

- Fix `Sprockets::Server` to return response headers to be compatible with Rack::Lint 2.0.

## 4.1.0

- Allow age to be altered in asset:clean rake task.
- Fix `Sprockets::Server` to return lower-cased response headers to comply with Rack::Lint 3.0. [#744](https://github.com/rails/sprockets/pull/744)
- Adding new directive `depend_on_directory` [#668](https://github.com/rails/sprockets/pull/668)
- Fix `application/js-sourcemap+json` charset [#669](https://github.com/rails/sprockets/pull/669)
- Fix `CachedEnvironment` caching nil values [#723](https://github.com/rails/sprockets/pull/723)
- Process `*.jst.ejs.erb` files with ERBProcessor [#674](https://github.com/rails/sprockets/pull/674)
- Fix cache key for coffee script processor to be dependent on the filename [#670](https://github.com/rails/sprockets/pull/670)

## 4.0.3

- Fix `Manifest#find` yielding from a Promise causing issue on Ruby 3.1.0-dev. [#720](https://github.com/rails/sprockets/pull/720)
- Better detect the ERB version to avoid deprecation warnings. [#719](https://github.com/rails/sprockets/pull/719)
- Allow assets already fingerprinted to be served through `Sprockets::Server`
- Do not fingerprint files that already contain a valid digest in their name
- Remove remaining support for Ruby < 2.4.[#672](https://github.com/rails/sprockets/pull/672)

## 4.0.2

- Fix `etag` and digest path compilation that were generating string with invalid digest since 4.0.1.

## 4.0.1

- Fix for Ruby 2.7 keyword arguments warning in `base.rb`. [#660](https://github.com/rails/sprockets/pull/660)
- Fix for when `x_sprockets_linecount` is missing from a source map.
- Fix subresource integrity to match the digest of the asset.

## 4.0.0

- Fixes for Ruby 2.7 keyword arguments warnings [#625](https://github.com/rails/sprockets/pull/625)
- Manifest files are sorted alphabetically [#626](https://github.com/rails/sprockets/pull/626)

## 4.0.0.beta10

- Fix YACB (Yet Another Caching Bug) [Fix broken expansion of asset link paths](https://github.com/rails/sprockets/pull/614)

## 4.0.0.beta9

- Minimum Ruby version for Sprockets 4 is now 2.5+ which matches minimum ruby version of Rails [#604]
- Fix threading bug introduced in Sprockets 4 [#603]
- Warn when two potential manifest files exist. [#560]

## 4.0.0.beta8

- Security release for [CVE-2018-3760](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2018-3760)

## 4.0.0.beta7

- Fix a year long bug that caused `Sprockets::FileNotFound` errors when the asset was present [#547]
- Raise an error when two assets such as foo.js and foo.js.erb would produce the same output artifact (foo.js) [#549 #530]
- Process `*.jst.eco.erb` files with ERBProcessor

## 4.0.0.beta6

- Fix source map line offsets [#515]
- Return a `400 Bad Request` when the path encoding is invalid. [#514]

## 4.0.0.beta5

- Reduce string allocations
- Source map metadata uses compressed form specified by the [source map v3 spec](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k). [#402] **[BREAKING]**
- Generate [index maps](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit#heading=h.535es3xeprgt) when decoding source maps isn't necessary. [#402]
- Remove fingerprints from source map files. [#402]

## 4.0.0.beta4

- Changing the version now busts the digest of all assets [#404]
- Exporter interface added [#386]
- Using ENV vars in templates will recompile templates when the env vars change. [#365]
- Source maps for imported sass files with sassc is now fixed [#391]
- Load paths now in error messages [#322]
- Cache key added to babel processor [#387]
- `Environment#find_asset!` can now be used to raise an exception when asset could not be found [#379]

## 4.0.0.beta3

- Source Map fixes [#255] [#367]
- Performance improvements

## 4.0.0.beta2

- Fix load_paths on Sass processors [#223]


## 4.0.0.beta1

- Initial release of Sprockets 4

Please upgrade to the latest Sprockets 3 version before upgrading to Sprockets 4. Check the 3.x branch for previous changes https://github.com/rails/sprockets/blob/3.x/CHANGELOG.md.
