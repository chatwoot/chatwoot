# Next Release

## 1.17.0 (05/07/2025)

* Introduce opentelemetry notifier

## 1.16.0 (03/24/2022)

* Drop Growl support
* Move CI from travis to github actions

## 1.15.0 (03/21/2022)

* Fix bugsnag notifications
* Improve appsignal message

## 1.14.2 (03/24/2021)

* Fix `capture_exception` signature

## 1.14.1 (02/28/2021)

* Fix uninitialized constant ``UniformNotifier::SentryNotifier::Raven`` error

## 1.14.0 (02/26/2021)

* Add AppSignal integration
* Fix `UniformNotifier::Raise.active?` when `.rails=` receives a false value

## 1.13.0 (10/05/2019)

* Add Honeybadger class dependecy injection.
* Allow configuration of Rollbar level.

## 1.12.1 (10/30/2018)

* Require Ruby 2.3+

## 1.12.0 (08/17/2018)

* Add [terminal-notifier](https://github.com/julienXX/terminal-notifier) support
* Lots of refactors from Awesome Code

## 1.11.0 (11/13/2017)

* Add Sentry notifier

## 1.10.0 (01/06/2016)

* Add honeybadger notifier
* Eliminate ruby warnings

## 1.9.0 (04/19/2015)

* Add `UniformNotifier::AVAILABLE_NOTIFIERS` constant

## 1.8.0 (03/17/2015)

* Add rollbar notifier

## 1.7.0 (02/08/2015)

* Add slack notifier

## 1.6.0 (04/30/2014)

* Support detail notify data
* Add options for airbrake and bugsnag notifiers

## 1.5.0 (04/26/2014)

* Add bugsnag notifier
* Use custom excaption

## 1.4.0 (11/03/2013)

* Raise should implement `out_of_channel_notify` instead of `inline_notify`

## 1.3.0 (08/28/2012)

* Add raise notifier

## 1.2.0 (03/03/2013)

* Compatible with ruby-growl 4.0 gem

## 1.1.0 (09/28/2012)

* Add growl gntp support
* Add airbrake notifier

## 1.0.0 (11/19/2010)

* First release
