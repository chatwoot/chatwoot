# CHANGELOG

## main (unreleased)

# 4.2.1

* Support to Rails 7.1
* Support to Rack 3.0

## 4.2.0

* [#308](https://github.com/rails/web-console/pull/308) Fix web-console inline templates rendering ([@voxik])
* [#306](https://github.com/rails/web-console/pull/306) Support Ruby 3.0 and above ([@ryanwood])

## 4.1.0

* [#304](https://github.com/rails/web-console/pull/304) Add support for Rails 6.1 ([@stephannv])
* [#298](https://github.com/rails/web-console/pull/298) Prevent deprecation warnings by removing template formats ([@mikelkew])
* [#297](https://github.com/rails/web-console/pull/297) Use MutationObserver instead of Mutation Events ([@mikelkew])
* [#296](https://github.com/rails/web-console/pull/296) Add CSP nonce to injected scripts and styles ([@mikelkew])

## 4.0.4

* [fb483743](https://github.com/rails/web-console/commit/fb483743a6a2a4168cdc0b2e03f48fc393991b73) Fix a crash on webrick with Rack 2.2.3 ([@gsamokovarov])

## 4.0.3

* [#291](https://github.com/rails/web-console/pull/291) Deprecate config.web_console.whitelisted_ips ([@JuanitoFatas])
* [#290](https://github.com/rails/web-console/pull/290) Fix Content-Length for rack >= 2.1.0 ([@p8])

## 4.0.2

* [#285](https://github.com/rails/web-console/pull/285) Increase timeout on paste ([@celvro])

## 4.0.1

* [#279](https://github.com/rails/web-console/pull/279) Fix initial config.web_console.permissions value ([@patorash])

## 4.0.0

* [61ce65b5](https://github.com/rails/web-console/commit/61ce65b599f56809de1bd8da6590a80acbd92017) Move to config.web_console.permissions ([@gsamokovarov])
* [96127ac1](https://github.com/rails/web-console/commit/96127aac143e1e653fffdc4bb65e1ce0b5ff342d) Introduce Binding#console as an alternative interface ([@gsamokovarov])
* [d4591ca5](https://github.com/rails/web-console/commit/d4591ca5396ed15a08818f3da11134852a485b27) Introduce Rails 6 support ([@gsamokovarov])
* [f97d8a88](https://github.com/rails/web-console/commit/f97d8a889a38366485e5c5e8985995c19bf61d13) Introduce Ruby 2.6 support ([@gsamokovarov])
* [d6deacd9](https://github.com/rails/web-console/commit/d6deacd9d5fcaabf3e3051d6985b53f924f86956) Drop Rails 5 support ([@gsamokovarov])
* [90fda878](https://github.com/rails/web-console/commit/90fda8789d402f05647c18f8cdf8e5c3d01692dd) Drop Ruby 2.4 support ([@gsamokovarov])
* [#265](https://github.com/rails/web-console/pull/265) Add support for nested exceptions ([@yuki24])

## 3.7.0

* [#263](https://github.com/rails/web-console/pull/263) Show binding changes ([@causztic])
* [#258](https://github.com/rails/web-console/pull/258) Support Ctrl-A, Ctrl-W and Ctrl-U ([@gsamokovarov])
* [#257](https://github.com/rails/web-console/pull/257) Always try to keep the console underneath the website content ([@gsamokovarov])

## 3.6.2

* [#255](https://github.com/rails/web-console/pull/255) Fix the truncated HTML body, because of wrong Content-Length header ([@timomeh])

## 3.6.1

* [#252](https://github.com/rails/web-console/pull/252) Fix improper injection in Rack bodies like ActionDispatch::Response::RackBody ([@gsamokovarov])

## 3.6.0

* [#254](https://github.com/rails/web-console/pull/254) Rescue ActionDispatch::RemoteIp::IpSpoofAttackError ([@wjordan])
* [#250](https://github.com/rails/web-console/pull/250) Close original body to comply with Rack SPEC ([@wagenet])
* [#249](https://github.com/rails/web-console/pull/249) Update for frozen-string-literal friendliness ([@pat])
* [#248](https://github.com/rails/web-console/pull/248) Fix copy on Safari ([@ybart])
* [#246](https://github.com/rails/web-console/pull/246) International keyboard special character input fixes ([@fl0l0u])
* [#244](https://github.com/rails/web-console/pull/244) Let WebConsole.logger respect Rails.logger ([@gsamokovarov])

## 3.5.1

* [#239](https://github.com/rails/web-console/pull/239) Fix the ActionDispatch::DebugExceptions integration ([@gsamokovarov])

## 3.5.0

* [#237](https://github.com/rails/web-console/pull/237) Bindex integration for JRuby 9k support ([@gsamokovarov])
* [#236](https://github.com/rails/web-console/pull/236) Remove unused Active Support lazy load hook ([@betesh])
* [#230](https://github.com/rails/web-console/pull/230) Handle invalid remote addresses ([@akirakoyasu])

## 3.4.0

* [#205](https://github.com/rails/web-console/pull/205) Introduce autocompletion ([@sh19910711])

## 3.3.1

Drop support for Rails `4.2.0`.

## 3.3.0

* [#203](https://github.com/rails/web-console/pull/203) Map bindings to traces based on the trace __FILE__ and __LINE__ ([@gsamokovarov])

## 3.2.1

* [#202](https://github.com/rails/web-console/pull/202) Use first binding when there is no application binding ([@sh19910711])

## 3.2.0

* [#198](https://github.com/rails/web-console/pull/198) Pick the first application trace binding on errors ([@sh19910711])
* [#189](https://github.com/rails/web-console/pull/189) Silence ActionView rendering information ([@gsamokovarov])

## 3.1.1

* [#185](https://github.com/rails/web-console/pull/185) Fix `rails console` startup ([@gsamokovarov])

## 3.1.0

* [#182](https://github.com/rails/web-console/pull/182) Let `#console` live in `Kernel` ([@schneems])
* [#181](https://github.com/rails/web-console/pull/181) Log internal Web Console errors ([@gsamokovarov])
* [#180](https://github.com/rails/web-console/pull/180) Autoload Web Console constants for faster Rails boot time ([@herminiotorres])

## 3.0.0

* [#173](https://github.com/rails/web-console/pull/173) Revert "Change config.development_only default until 4.2.4 is released" ([@gsamokovarov])
* [#171](https://github.com/rails/web-console/pull/171) Fixed blocked IP logging ([@gsamokovarov])
* [#162](https://github.com/rails/web-console/pull/162) Render the console inside the body tag ([@gsamokovarov])
* [#165](https://github.com/rails/web-console/pull/165) Revamped integrations for CRuby and Rubinius ([@gsamokovarov])

## 2.3.0

This is mainly a Rails 5 compatibility release. If you have the chance, please
go to 3.1.0 instead.

* [#181](https://github.com/rails/web-console/pull/181) Log internal Web Console errors ([@schneems])
* [#150](https://github.com/rails/web-console/pull/150) Revert #150. ([@gsamokovarov])

## 2.2.1

* [#150](https://github.com/rails/web-console/pull/150) Change config.development_only default until 4.2.4 is released ([@gsamokovarov])

## 2.2.0

* [#140](https://github.com/rails/web-console/pull/140) Add the ability to close the console on each page ([@sh19910711])
* [#135](https://github.com/rails/web-console/pull/135) Run the console only in development mode and raise warning in tests ([@frenesim])
* [#134](https://github.com/rails/web-conscle/pull/134) Force development only web console by default ([@gsamokovarov])
* [#123](https://github.com/rails/web-console/pull/123) Replace deprecated `alias_method_chain` with `alias_method` ([@jonatack])

## 2.1.3

* Fix remote code execution vulnerability in Web Console. CVE-2015-3224.

## 2.1.2

* [#115](https://github.com/rails/web-console/pull/115) Show proper binding when raising an error in a template ([@gsamokovarov])
* [#114](https://github.com/rails/web-console/pull/114) Fix templates non rendering, because of missing template suffix ([@gsamokovarov])

## 2.1.1

* [#112](https://github.com/rails/web-console/pull/112) Always allow application/x-www-form-urlencoded content type ([@gsamokovarov])

## 2.1.0

* [#109](https://github.com/rails/web-console/pull/109) Revamp unavailable session response message ([@gsamokovarov])
* [#107](https://github.com/rails/web-console/pull/107) Fix pasting regression for all browsers ([@parterburn])
* [#105](https://github.com/rails/web-console/pull/105) Lock scroll bottom on console window resize ([@noahpatterson])
* [#104](https://github.com/rails/web-console/pull/104) Always whitelist localhost and inform users why no console is displayed ([@gsamokovarov])
* [#100](https://github.com/rails/web-console/pull/100) Accept text/plain as acceptable content type for Puma ([@gsamokovarov])
* [#98](https://github.com/rails/web-console/pull/98) Add arbitrary big z-index to the console ([@bglbruno])
* [#88](https://github.com/rails/web-console/pull/88) Spelling fixes ([@jeffnv])
* [#86](https://github.com/rails/web-console/pull/86) Disable autofocus when initializing the console ([@ryandao])
* [#84](https://github.com/rails/web-console/pull/84) Allow Rails 5 as dependency in gemspec ([@jonatack])
* [#69](https://github.com/rails/web-console/pull/69) Introduce middleware for request dispatch and console rendering ([@gsamokovarov])

[@stephannv]: https://github.com/stephannv
[@mikelkew]: https://github.com/mikelkew
[@jonatack]: https://github.com/jonatack
[@ryandao]: https://github.com/ryandao
[@jeffnv]: https://github.com/jeffnv
[@gsamokovarov]: https://github.com/gsamokovarov
[@bglbruno]: https://github.com/bglbruno
[@noahpatterson]: https://github.com/noahpatterson
[@parterburn]: https://github.com/parterburn
[@sh19910711]: https://github.com/sh19910711
[@frenesim]: https://github.com/frenesim
[@herminiotorres]: https://github.com/herminiotorres
[@schneems]: https://github.com/schneems
[@betesh]: https://github.com/betesh
[@akirakoyasu]: https://github.com/akirakoyasu
[@wagenet]: https://github.com/wagenet
[@wjordan]: https://github.com/wjordan
[@pat]: https://github.com/pat
[@ybart]: https://github.com/ybart
[@fl0l0u]: https://github.com/fl0l0u
[@timomeh]: https://github.com/timomeh
[@causztic]: https://github.com/causztic
[@yuki24]: https://github.com/yuki24
[@patorash]: https://github.com/patorash
[@celvro]: https://github.com/celvro
[@JuanitoFatas]: https://github.com/JuanitoFatas
[@p8]: https://github.com/p8
[@voxik]: https://github.com/voxik
[@ryanwood]: https://github.com/ryanwood
