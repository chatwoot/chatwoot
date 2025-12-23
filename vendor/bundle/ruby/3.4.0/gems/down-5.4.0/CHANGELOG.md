## 5.4.0 (2022-12-26)

* Add new HTTPX backend, which supports HTTP/2 protocol among other features (@HoneyryderChuck)

## 5.3.1 (2022-03-25)

* Correctly split cookie headers on `;` instead of `,` when forwarding them on redirects (@ermolaev)

## 5.3.0 (2022-02-20)

* Add `:extension` argument to `Down.download` for overriding tempfile extension (@razum2um)

* Normalize response header names for http.rb and wget backends (@zarqman)

## 5.2.4 (2021-09-12)

* Keep original cookies between redirections (@antprt)

## 5.2.3 (2021-08-03)

* Bump addressable version requirement to 2.8+ to remediate vulnerability (@aldodelgado)

## 5.2.2 (2021-05-27)

* Add info about received content length in `Down::TooLarge` error (@evheny0)

* Relax http.rb constraint to allow versions 5.x (@mgrunberg)

## 5.2.1 (2021-04-26)

* Raise `Down::NotModified` on 304 response status in `Down::NetHttp#open` (@ellafeldmann)

## 5.2.0 (2020-09-20)

* Add `:uri_normalizer` option to `Down::NetHttp` (@janko)

* Add `:http_basic_authentication` option to `Down::NetHttp#open` (@janko)

* Fix uninitialized instance variables warnings in `Down::ChunkedIO` (@janko)

* Handle unknown HTTP error codes in `Down::NetHttp` (@darndt)

## 5.1.1 (2020-02-04)

* Fix keyword arguments warnings on Ruby 2.7 in `Down.download` and `Down.open` (@janko)

## 5.1.0 (2020-01-09)

* Fix keyword arguments warnings on Ruby 2.7 (@janko)

* Fix `FrozenError` exception in `Down::ChunkedIO#readpartial` (@janko)

* Deprecate passing headers as top-level options in `Down::NetHttp` (@janko)

## 5.0.1 (2019-12-20)

* In `Down::NetHttp` only use Addressable normalization if `URI.parse` fails (@coding-chimp)

## 5.0.0 (2019-09-26)

* Change `ChunkedIO#each_chunk` to return chunks in original encoding (@janko)

* Always return binary strings in `ChunkedIO#readpartial` (@janko)

* Handle frozen chunks in `Down::ChunkedIO` (@janko)

* Change `ChunkedIO#gets` to return lines in specified encoding (@janko)

* Halve memory allocation for `ChunkedIO#gets` (@janko)

* Halve memory allocation for `ChunkedIO#read` without arguments (@janko)

* Drop support for `HTTP::Client` argument in `Down::HTTP.new` (@janko)

* Repurpose `Down::NotFound` to be raised on `404 Not Found` response (@janko)

## 4.8.1 (2019-05-01)

* Make `ChunkedIO#read`/`#readpartial` with length always return strings in binary encoding (@janko)

* In `ChunkedIO#gets` respect the limit argument when separator is nil (@edlebert)

## 4.8.0 (2018-12-19)

* Prefer UTF-8 filenames in `Content-Disposition` header for `Tempfile#original_filename` (@janko)

* Make the internal Tempfile of `Down::ChunkedIO` inaccessible to outside programs (@janko)

## 4.7.0 (2018-11-18)

* Allow request headers to be passed via `:headers` to `Down::NetHttp#download` and `#open` (@janko)

## 4.6.1 (2018-10-24)

* Release HTTP.rb version constraint to allow HTTP.rb 4.x (@janko)

## 4.6.0 (2018-09-29)

* Ensure URLs are properly encoded in `NetHttp#download` and `#open` using Addressable (@linyaoli)

* Raise `ResponseError` with clear message when redirect URI was invalid in Down::NetHttp (@janko)

## 4.5.0 (2018-05-11)

* Deprecate passing an `HTTP::Client` object to `Down::Http#initialize` (@janko)

* Add ability to pass a block to `Down::Http#initialize` for extending default options (@janko)

* Return empty string when length is zero in `ChunkedIO#read` and `ChunkedIO#readpartial` (@janko)

* Make `posix-spawn` optional (@janko)

## 4.4.0 (2018-04-12)

* Add `:method` option to `Down::Http` for specifying the request method (@janko)

* Set default timeout of 30 for each operation to all backends (@janko)

## 4.3.0 (2018-03-11)

* Accept CLI arguments as a list of symbols in `Down::Wget#download` (@janko)

* Avoid potential URL parsing errors in `Down::Http::DownloadedFile#filename_from_url` (@janko)

* Make memory usage of `Down::Wget#download` constant (@janko)

* Add `:destination` option to `Down.download` for specifying download destination (@janko)

## 4.2.1 (2018-01-29)

* Reduce memory allocation in `Down::ChunkedIO` by 10x when buffer string is used (@janko)

* Reduce memory allocation in `Down::Http.download` by 10x.

## 4.2.0 (2017-12-22)

* Handle `:max_redirects` in `Down::NetHttp#open` and follow up to 2 redirects by default (@janko)

## 4.1.1 (2017-10-15)

* Raise all system call exceptions as `Down::ConnectionError` in `Down::NetHttp` (@janko)

* Raise `Errno::ETIMEDOUT` as `Down::TimeoutError` in `Down::NetHttp` (@janko)

* Raise `Addressable::URI::InvalidURIError` as `Down::InvalidUrl` in `Down::Http` (@janko)

## 4.1.0 (2017-08-29)

* Fix `FiberError` occurring on `Down::NetHttp.open` when response is chunked and gzipped (@janko)

* Use a default `User-Agent` in `Down::NetHttp.open` (@janko)

* Fix raw read timeout error sometimes being raised instead of `Down::TimeoutError` in `Down.open` (@janko)

* `Down::ChunkedIO` can now be parsed by the CSV Ruby standard library (@janko)

* Implement `Down::ChunkedIO#gets` (@janko)

* Implement `Down::ChunkedIO#pos` (@janko)

## 4.0.1 (2017-07-08)

* Load and assign the `NetHttp` backend immediately on `require "down"` (@janko)

* Remove undocumented `Down::ChunkedIO#backend=` that was added in 4.0.0 to avoid confusion (@janko)

## 4.0.0 (2017-06-24)

* Don't apply `Down.download` and `Down.open` overrides when loading a backend (@janko)

* Remove `Down::Http.client` attribute accessor (@janko)

* Make `Down::NetHttp`, `Down::Http`, and `Down::Wget` classes instead of modules (@janko)

* Remove `Down.copy_to_tempfile` (@janko)

* Add Wget backend (@janko)

* Add `:content_length_proc` and `:progress_proc` to the HTTP.rb backend (@janko)

* Halve string allocations in `Down::ChunkedIO#readpartial` when buffer string is not used (@janko)

## 3.2.0 (2017-06-21)

* Add `Down::ChunkedIO#readpartial` for more memory efficient reading (@janko)

* Fix `Down::ChunkedIO` not returning second part of the last chunk if it was previously partially read (@janko)

* Strip internal variables from `Down::ChunkedIO#inspect` and show only the important ones (@janko)

* Add `Down::ChunkedIO#closed?` (@janko)

* Add `Down::ChunkedIO#rewindable?` (@janko)

* In `Down::ChunkedIO` only create the Tempfile if it's going to be used (@janko)

## 3.1.0 (2017-06-16)

* Split `Down::NotFound` into explanatory exceptions (@janko)

* Add `:read_timeout` and `:open_timeout` options to `Down::NetHttp.open` (@janko)

* Return an `Integer` in `data[:status]` on a result of `Down.open` when using the HTTP.rb strategy (@janko)

## 3.0.0 (2017-05-24)

* Make `Down.open` pass encoding from content type charset to `Down::ChunkedIO` (@janko)

* Add `:encoding` option to `Down::ChunkedIO.new` for specifying the encoding of returned content (@janko)

* Add HTTP.rb backend as an alternative to Net::HTTP (@janko)

* Stop testing on MRI 2.1 (@janko)

* Forward cookies from the `Set-Cookie` response header when redirecting (@janko)

* Add `frozen-string-literal: true` comments for less string allocations on Ruby 2.3+ (@janko)

* Modify `#content_type` to return nil instead of `application/octet-stream` when `Content-Type` is blank in `Down.download` (@janko)

* `Down::ChunkedIO#read`, `#each_chunk`, `#eof?`, `rewind` now raise an `IOError` when `Down::ChunkedIO` has been closed (@janko)

* `Down::ChunkedIO` now caches only the content that has been read (@janko)

* Add `Down::ChunkedIO#size=` to allow assigning size after the `Down::ChunkedIO` has been instantiated (@janko)

* Make `:size` an optional argument in `Down::ChunkedIO` (@janko)

* Call enumerator's `ensure` block when `Down::ChunkedIO#close` is called (@janko)

* Add `:rewindable` option to `Down::ChunkedIO` and `Down.open` for disabling caching read content into a file (@janko)

* Drop support for MRI 2.0 (@janko)

* Drop support for MRI 1.9.3 (@janko)

* Remove deprecated `:progress` option (@janko)

* Remove deprecated `:timeout` option (@janko)

* Reraise only a subset of exceptions as `Down::NotFound` in `Down.download` (@janko)

* Support streaming of "Transfer-Encoding: chunked" responses in `Down.open` again (@janko)

* Remove deprecated `Down.stream` (@janko)

## 2.5.1 (2017-05-13)

* Remove URL from the error messages (@janko)

## 2.5.0 (2017-05-03)

* Support both Strings and `URI` objects in `Down.download` and `Down.open` (@olleolleolle)

* Work around a `CGI.unescape` bug in Ruby 2.4.

* Apply HTTP Basic authentication contained in URLs in `Down.open`.

* Raise `Down::NotFound` on 4xx and 5xx responses in `Down.open`.

* Write `:status` and `:headers` information to `Down::ChunkedIO#data` in `Down.open`.

* Add `#data` attribute to `Down::ChunkedIO` for saving custom result data.

* Don't save retrieved chunks into the file in `Down::ChunkedIO#each_chunk`.

* Add `:proxy` option to `Down.download` and `Down.open`.

## 2.4.3 (2017-04-06)

* Show the input URL in the `Down::Error` message.

## 2.4.2 (2017-03-28)

* Don't raise `StopIteration` in `Down::ChunkedIO` when `:chunks` is an empty
  Enumerator.

## 2.4.1 (2017-03-23)

* Correctly detect empty filename from `Content-Disposition` header, and
  in this case continue extracting filename from URL.

## 2.4.0 (2017-03-19)

* Allow `Down.open` to accept request headers as options with String keys,
  just like `Down.download` does.

* Decode URI-decoded filenames from the `Content-Disposition` header

* Parse filenames without quotes from the `Content-Disposition` header

## 2.3.8 (2016-11-07)

* Work around `Transfer-Encoding: chunked` responses by downloading whole
  response body.

## 2.3.7 (2016-11-06)

* In `Down.open` send requests using the URI *path* instead of the full URI.

## 2.3.6 (2016-07-26)

* Read #original_filename from the "Content-Disposition" header.

* Extract `Down::ChunkedIO` into a file, so that it can be required separately.

* In `Down.stream` close the IO after reading from it.

## 2.3.5 (2016-07-18)

* Prevent reading the whole response body when the IO returned by `Down.open`
  is closed.

## 2.3.4 (2016-07-14)

* Require `net/http`

## 2.3.3 (2016-06-23)

* Improve `Down::ChunkedIO` (and thus `Down.open`):

  - `#each_chunk` and `#read` now automatically call `:on_close` when all
    chunks were downloaded

  - `#eof?` had incorrect behaviour, where it would return true if
    everything was downloaded, instead only when it's also at the end of
    the file

  - `#close` can now be called multiple times, as the `:on_close` will always
    be called only once

  - end of download is now detected immediately when the last chunk was
    downloaded (as opposed to after trying to read the next one)

## 2.3.2 (2016-06-22)

* Add `Down.open` for IO-like streaming, and deprecate `Down.stream` (janko-m)

* Allow URLs with basic authentication (`http://user:password@example.com`) (janko-m)

## ~~2.3.1 (2016-06-22)~~ (yanked)

## ~~2.3.0 (2016-06-22)~~ (yanked)

## 2.2.1 (2016-06-06)

* Make Down work on Windows (martinsefcik)

* Close an internal file descriptor that was left open (martinsefcik)

## 2.2.0 (2016-05-19)

* Add ability to follow redirects, and allow maximum of 2 redirects by default (janko-m)

* Fix a potential Windows issue when extracting `#original_filename` (janko-m)

* Fix `#original_filename` being incomplete if filename contains a slash (janko-m)

## 2.1.0 (2016-04-12)

* Make `:progress_proc` and `:content_length_proc` work with `:max_size` (janko-m)

* Deprecate `:progress` in favor of open-uri's `:progress_proc` (janko-m)

* Deprecate `:timeout` in favor of open-uri's `:open_timeout` and `:read_timeout` (janko-m)

* Add `Down.stream` for streaming remote files in chunks (janko-m)

* Replace deprecated `URI.encode` with `CGI.unescape` in downloaded file's `#original_filename` (janko-m)

## 2.0.1 (2016-03-06)

* Add error message when file was to large, and use a simple error message for other generic download failures (janko-m)

## 2.0.0 (2016-02-03)

* Fix an issue where valid URLs were transformed into invalid URLs (janko-m)

  - All input URLs now have to be properly encoded, which should already be the
    case in most situations.

* Include the error class when download fails (janko-m)

## 1.1.0 (2016-01-26)

* Forward all additional options to open-uri (janko-m)

## 1.0.5 (2015-12-18)

* Move the open-uri file to the new location instead of copying it (janko-m)

## 1.0.4 (2015-11-19)

* Delete the old open-uri file after using it (janko-m)

## 1.0.3 (2015-11-16)

* Fix `#download` and `#copy_to_tempfile` not preserving the file extension (janko-m)

* Fix `#copy_to_tempfile` not working when given a nested basename (janko-m)

## 1.0.2 (2015-10-24)

* Fix Down not working with Ruby 1.9.3 (janko-m)

## 1.0.1 (2015-10-01)

* Don't allow redirects when downloading files (janko-m)
