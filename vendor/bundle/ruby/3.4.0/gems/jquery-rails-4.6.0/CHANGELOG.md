## unreleased

## 4.6.0

- update jquery to 3.7.0

## 4.5.1

- update jquery to 3.6.1
- update jquery-ujs to 1.2.3

## 4.5.0

- update jquery to 3.6.0

## 4.4.0

- update jquery to 3.5.1 (note: [3.5.0 contains important security updates](https://github.com/advisories/GHSA-jpcq-cgw6-v4j6))
- unescape dollar signs and backticks in `assert_select_jquery` to match
  Rails updated behavior.

## 4.3.5

- update jquery to 3.4.1

## 4.3.4

- update jquery to 3.4.0

## 4.3.3

- update jquery to 3.3.1

## 4.3.2

- update jquery to 3.3.0
- Add possibility to test HTML: all, attribute prefix, attribute contains,
  attribute ends with, child, and class selectors
- Fix matching multiple calls for the same selector/function exception

## 4.3.1

- update jquery to 3.2.1

## 4.3.0

- update jquery to 3.2.0
- Add possibility to test HTML attribute selectors

## 4.2.2

- update jquery to 3.1.1

## 4.2.1

- update jquery to 3.1.0

## 4.2.0

- Support jQuery 3.x
- Update jquery-ujs to 1.2.2
- Update jQuery to 1.12.4 and 2.2.4

## 4.1.1

- Update jQuery to 1.12.1 and 2.2.1
- Update jquery-ujs to 1.2.1

## 4.1.0

- Update jQuery to 1.12.0 and 2.2.0
- Update jquery-ujs to 1.2.0

## 4.0.5

- Specify that Ruby version 1.9.3+ is required
- Test on Ruby 2.2
- Update jquery-ujs from 1.0.4 to 1.1.0

## 4.0.4

  - Fix CSP bypass vulnerability. CVE-2015-1840

## 4.0.1

  - Fix RubyGems permission problem.

## 4.0.0

  - Minimum dependency set to Rails 4.2
  - Updated to jquery-ujs 1.0.2
  - Support jQuery 1.x and 2.x

## 3.1.3 (16 June 2015)

  - Fix CSP bypass vulnerability. CVE-2015-1840

## 3.1.2 (1 September 2014)

  - Updated to jquery-ujs 1.0.1

## 3.1.1 (23 June 2014)

  - Updated to jQuery 1.11.1
  - Updated to jquery-ujs 1.0.0

## 3.1.0 (29 January 2014)

  - Updated to jQuery 1.11.0
  - Updated to latest jquery-ujs
  - Added development rake task for updating jQuery

## 3.0.4 (10 July 2013)

  - Fixed jQuery source map

## 3.0.3 (10 July 2013)

  - Updated to jQuery 1.10.2

## 3.0.2 (04 July 2013)

  - Updated to latest jquery-ujs

## 3.0.1 (07 June 2013)

  - Updated to jQuery 1.10.1
  - Removed jQuery UI from generator

## 3.0.0 (29 May 2013)

  - Removed jQuery UI

## 2.3.0 (29 May 2013)

  - Updated to jQuery 1.10.0
  - Updated to jQuery UI 1.10.3

## 2.2.2 (29 May 2013)

  - Updated to latest jquery-ujs

## 2.2.1 (08 February 2013)

  - Updated to jQuery 1.9.1
  - Updated to latest jquery-ujs

## 2.2.0 (19 January 2013)

  - Updated to jQuery 1.9.0
  - Updated to latest jquery-ujs

## 2.1.4 (26 November 2012)

  - Updated to jQuery 1.8.3
  - Updated to jQuery UI 1.9.2
  - Rails 4 compatibility
  - Rails 3.1 compatibility (without asset pipeline)
  - Rails 3.0 compatibility

## 2.1.3 (24 September 2012)

  - Updated to latest jquery-ujs
  - Updated to jQuery 1.8.2

## 2.1.2 (06 September 2012)

  - Updated to latest jquery-ujs
    - required radio bugfix
  - Updated to jQuery 1.8.1

## 2.1.1 (18 August 2012)

  - Updated to latest jquery-ujs
    - ajax:aborted:file bugfixes

## 2.1.0 (16 August 2012)

  - Updated to latest jquery-ujs
    - jQuery 1.8.0 compatibility
  - Updated to jQuery 1.8.0
  - Updated to jQuery UI 1.8.23

## 2.0.3 (16 August 2012)

  - Updated to latest jquery-ujs
    - created `rails:attachBindings` to allow for customization of $.rails object settings
    - created `ajax:send` event to provide access to jqXHR object from ajax requests
    - added support for `data-with-credentials`

## 2.0.2 (03 April 2012)

  - Updated to jQuery 1.7.2
  - Updated to jQuery UI 1.8.18
  - Updated to latest jquery-ujs
    - Override provided for obtaining `href`
    - Edit `crossDomain` and `dataType` from `ajax:before` event

## 2.0.1 (28 February 2012)

  - Fixed Rails 3.2 dependency issue

## 2.0 (20 December 2011)

  - Minimum dependency set to Rails 3.2

## 1.0.19 (26 November 2011)

  - Updated to jQuery 1.7.1
  - Updated to latest jquery-ujs
    - Fixed disabled links to re-enable when `ajax:before` or
      `ajax:beforeSend` are canceled
    - Switched from deprecated `live` to `delegate`

## 1.0.18 (18 November 2011)

  - Updated to latest jquery-ujs
    - Fixed event parameter for form submit event handlers in IE for
      jQuery 1.6.x
    - Fixed form submit event handlers for jQuery 1.7

## 1.0.17 (9 November 2011)

  - Updated to jQuery 1.7
  - Updated to latest jquery-ujs
    - Moved file comment above function so it won't be included in
      compressed version

## 1.0.16 (12 October 2011)

  - Updated to jQuery 1.6.4
  - Updated to jQuery UI 1.8.16

## 1.0.15 (12 October 2011)

  - Updated to latest jquery-ujs
    - Fixed formInputClickSelector `button[type]` for IE7
    - Copy target attribute to generated form for `a[data-method]` links
    - Return true (abort ajax) for ctrl- and meta-clicks on remote links
    - Use jQuery `.prop()` for disabling/enabling elements

## 1.0.14 (08 September 2011)

  - Updated to latest jquery-ujs
    - Added `disable-with` support for links
    - minor bug fixes
    - Added `data-remote` support for change events of all input types
  - Added install generator for Rails 3.1 with instructional message

## 1.0.13 (11 August 2011)

  - Updated to latest jquery-ujs with `novalidate` support
  - No more support for jquery older than v1.6

## 1.0.12 (23 June 2011)

  - Updated to latest jquery-ujs with 'blank form action' and
    data-remote support for select elements

## 1.0.11 (15 June 2011)

  - Updated to latest jqueyr-ujs with cross-domain support

[See jquery-ujs issue 167](https://github.com/rails/jquery-ujs/pull/167) for relevant discussion

## 1.0.10 (13 June 2011)

  - Updated to latest jqueyr-ujs with bug fixes

## 1.0.9 (25 May 2011)

  - Merged with new rails repo (3.1 fix)

## 1.0.8 (25 May 2011)

  - Updated to latest jquery-ujs with `[disabled][required]` fix

## 1.0.7 (21 May 2011)

  - Fix assert_select_jquery's bad call to unescape_rjs

## 1.0.6 (21 May 2011)

  - Updated to latest jquery-ujs with `data-params` support

## 1.0.5 (17 May 2011)

  - Updated to latest jquery-ujs
  - Remove old rails.js in Rails 3.0 generator

## 1.0.4 (17 May 2011)

  - Fix exception in Rails 3.0 generator

## 1.0.3 (17 May 2011)

  - Update to jQuery 1.6.1
  - Remove useless --version generator option

## 1.0.2 (12 May 2011)

  - Fix Rails 3.0 now that rails.js is named jquery_ujs.js

## 1.0.1 (10 May 2011)

  - Stop downloading rails.js from GitHub
  - Vendor jQuery UI for those who want it
  - Fix assert_select_jquery now that Rails 3.1 has no RJS at all
  - Fix rails dependency to just be railties

## 1.0.rc (3 May 2011)

  - Rails 3.1 asset pipeline edition
  - Removes generators and railties
  - Just provides jquery.js and jquery_ujs.js
  - Still compatible with Rails 3.0 via the old generator code

## 0.2.7 (5 February 2011)

  - Updated to use jQuery 1.5 by default

## 0.2.6 (1 December 2010)

Feature:

  - Updated to use jQuery 1.4.4 by default

## 0.2.5 (4 November 2010)

Bugfix:

  - Download JQuery Rails UJS via HTTPS since Github is now HTTPS only

## 0.2.4 (16 October 2010)

Features:

  - Updated to use the new jQuery 1.4.3 by default, with the IE .live() bug fixed
  - Always download the newest 1.x release of jQuery UI
  - Try to install unknown versions of jQuery, with fallback to the default
  - Print informative messages in the correct Generator style

## 0.2.3 (13 October 2010)

Features:

  - Support Edge Rails 3.1 by depending on Rails ~>3.0
  - Add Sam Ruby's assert_select_jquery test helper method
  - Use jquery.min only in production (and not in the test env)

## 0.2.2 (8 October 2010)

Feature:

  - Depend on Rails >=3.0 && <4.0 for edge Rails compatibility

## 0.2.1 (2 October 2010)

Bugfix:

  - Default to jQuery 1.4.1 as recommended by jQuery-ujs
    due to a bug in 1.4.2 (http://jsbin.com/uboxu3/7/)

## 0.2 (2 October 2010)

Features:

  - Allow specifying which version of jQuery to install
  - Add generator tests (thanks, Louis T.)
  - Automatically use non-minified JS in development mode

## 0.1.3 (16 September 2010)

Bugfix:

  - allow javascript :defaults tag to be overridden

## 0.1.2 (18 August 2010)

Bugfix:

  - check for jQueryUI in the right place

## 0.1.1 (16 August 2010)

Bugfix:

  - fix generator by resolving namespace conflict between Jquery::Rails and ::Rails
