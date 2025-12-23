## 1.6.1 / 2024-12-02

This is a performance and security release which addresses several possible XSS vulnerabilities.

* The dependency on Nokogiri is updated to v1.15.7 or >=1.16.8.

  This change addresses CVE-2024-53985 (GHSA-w8gc-x259-rc7x).

  *Mike Dalessio*

* Disallowed tags will be pruned when they appear in foreign content (i.e. SVG or MathML content),
  regardless of the `prune:` option value. Previously, disallowed tags were "stripped" unless the
  gem was configured with the `prune: true` option.

  The CVEs addressed by this change are:

  - CVE-2024-53986 (GHSA-638j-pmjw-jq48)
  - CVE-2024-53987 (GHSA-2x5m-9ch4-qgrr)

  *Mike Dalessio*

* The tags "noscript", "mglyph", and "malignmark" will not be allowed, even if explicitly added to
  the allowlist. If applications try to allow any of these tags, a warning is emitted and the tags
  are removed from the allow-list.

  The CVEs addressed by this change are:

  - CVE-2024-53988 (GHSA-cfjx-w229-hgx5)
  - CVE-2024-53989 (GHSA-rxv5-gxqc-xx8g)

  Please note that we _may_ restore support for allowing "noscript" in a future release. We do not
  expect to ever allow "mglyph" or "malignmark", though, especially since browser support is minimal
  for these tags.

  *Mike Dalessio*

* Improve performance by eliminating needless operations on attributes that are being removed. #188

  *Mike Dalessio*


## 1.6.0 / 2023-05-26

* Dependencies have been updated:

  - Loofah `~>2.21` and Nokogiri `~>1.14` for HTML5 parser support
  - As a result, required Ruby version is now `>= 2.7.0`

  Security updates will continue to be made on the `1.5.x` release branch as long as Rails 6.1
  (which supports Ruby 2.5) is still in security support.

  *Mike Dalessio*

* HTML5 standards-compliant sanitizers are now available on platforms supported by
  Nokogiri::HTML5. These are available as:

  - `Rails::HTML5::FullSanitizer`
  - `Rails::HTML5::LinkSanitizer`
  - `Rails::HTML5::SafeListSanitizer`

  And a new "vendor" is provided at `Rails::HTML5::Sanitizer` that can be used in a future version
  of Rails.

  Note that for symmetry `Rails::HTML4::Sanitizer` is also added, though its behavior is identical
  to the vendor class methods on `Rails::HTML::Sanitizer`.

  Users may call `Rails::HTML::Sanitizer.best_supported_vendor` to get back the HTML5 vendor if it's
  supported, else the legacy HTML4 vendor.

  *Mike Dalessio*

* Module namespaces have changed, but backwards compatibility is provided by aliases.

  The library defines three additional modules:

  - `Rails::HTML` for general functionality (replacing `Rails::Html`)
  - `Rails::HTML4` containing sanitizers that parse content as HTML4
  - `Rails::HTML5` containing sanitizers that parse content as HTML5

  The following aliases are maintained for backwards compatibility:

  - `Rails::Html` points to `Rails::HTML`
  - `Rails::HTML::FullSanitizer` points to `Rails::HTML4::FullSanitizer`
  - `Rails::HTML::LinkSanitizer` points to `Rails::HTML4::LinkSanitizer`
  - `Rails::HTML::SafeListSanitizer` points to `Rails::HTML4::SafeListSanitizer`

  *Mike Dalessio*

* `LinkSanitizer` always returns UTF-8 encoded strings. `SafeListSanitizer` and `FullSanitizer`
  already ensured this encoding.

  *Mike Dalessio*

* `SafeListSanitizer` allows `time` tag and `lang` attribute by default.

  *Mike Dalessio*

* The constant `Rails::Html::XPATHS_TO_REMOVE` has been removed. It's not necessary with the
  existing sanitizers, and should have been a private constant all along anyway.

  *Mike Dalessio*


## 1.5.0 / 2023-01-20

* `SafeListSanitizer`, `PermitScrubber`, and `TargetScrubber` now all support pruning of unsafe tags.

  By default, unsafe tags are still stripped, but this behavior can be changed to prune the element
  and its children from the document by passing `prune: true` to any of these classes' constructors.

  *seyerian*


## 1.4.4 / 2022-12-13

* Address inefficient regular expression complexity with certain configurations of Rails::Html::Sanitizer.

  Fixes CVE-2022-23517. See
  [GHSA-5x79-w82f-gw8w](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-5x79-w82f-gw8w)
  for more information.

  *Mike Dalessio*

* Address improper sanitization of data URIs.

  Fixes CVE-2022-23518 and #135. See
  [GHSA-mcvf-2q2m-x72m](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-mcvf-2q2m-x72m)
  for more information.

  *Mike Dalessio*

* Address possible XSS vulnerability with certain configurations of Rails::Html::Sanitizer.

  Fixes CVE-2022-23520. See
  [GHSA-rrfc-7g8p-99q8](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-rrfc-7g8p-99q8)
  for more information.

  *Mike Dalessio*

* Address possible XSS vulnerability with certain configurations of Rails::Html::Sanitizer.

  Fixes CVE-2022-23519. See
  [GHSA-9h9g-93gc-623h](https://github.com/rails/rails-html-sanitizer/security/advisories/GHSA-9h9g-93gc-623h)
  for more information.

  *Mike Dalessio*


## 1.4.3 / 2022-06-09

* Address a possible XSS vulnerability with certain configurations of Rails::Html::Sanitizer.

  Prevent the combination of `select` and `style` as allowed tags in SafeListSanitizer.

  Fixes CVE-2022-32209

  *Mike Dalessio*


## 1.4.2 / 2021-08-23

* Slightly improve performance.

  Assuming elements are more common than comments, make one less method call per node.

  *Mike Dalessio*


## 1.4.1 / 2021-08-18

* Fix regression in v1.4.0 that did not pass comment nodes to the scrubber.

  Some scrubbers will want to override the default behavior and allow comments, but v1.4.0 only
  passed through elements to the scrubber's `keep_node?` method.

  This change once again allows the scrubber to make the decision on comment nodes, but still skips
  other non-elements like processing instructions (see #115).

  *Mike Dalessio*


## 1.4.0 / 2021-08-18

* Processing Instructions are no longer allowed by Rails::Html::PermitScrubber

  Previously, a PI with a name (or "target") matching an allowed tag name was not scrubbed. There
  are no known security issues associated with these PIs, but similar to comments it's preferred to
  omit these nodes when possible from sanitized output.

  Fixes #115.

  *Mike Dalessio*


## 1.3.0

* Address deprecations in Loofah 2.3.0.

  *Josh Goodall*


## 1.2.0

* Remove needless `white_list_sanitizer` deprecation.

  By deprecating this, we were forcing Rails 5.2 to be updated or spew
  deprecations that users could do nothing about.

  That's pointless and I'm sorry for adding that!

  Now there's no deprecation warning and Rails 5.2 works out of the box, while
  Rails 6 can use the updated naming.

  *Kasper Timm Hansen*


## 1.1.0

* Add `safe_list_sanitizer` and deprecate `white_list_sanitizer` to be removed
  in 1.2.0. https://github.com/rails/rails-html-sanitizer/pull/87

  *Juanito Fatas*

* Remove `href` from LinkScrubber's `tags` as it's not an element.
  https://github.com/rails/rails-html-sanitizer/pull/92

  *Juanito Fatas*

* Explain that we don't need to bump Loofah here if there's CVEs.
  https://github.com/rails/rails-html-sanitizer/commit/d4d823c617fdd0064956047f7fbf23fff305a69b

  *Kasper Timm Hansen*


## 1.0.1

* Added support for Rails 4.2.0.beta2 and above


## 1.0.0

* First release.
