# Changelog
## v1.13.13

### Description


### Closed Issues
* IE11 compatibility failure v>1.13.5 ([#1918](https://github.com/beautify-web/js-beautify/issues/1918))


## v1.13.11

### Description


### Closed Issues
* Support short PHP tags ([#1840](https://github.com/beautify-web/js-beautify/issues/1840))


## v1.13.6

### Description


### Closed Issues
* Fix space-before-conditional: false to work on switch-case statement ([#1881](https://github.com/beautify-web/js-beautify/pull/1881))
* Optional chaining obj?.[expr] ([#1801](https://github.com/beautify-web/js-beautify/issues/1801))


## v1.13.5

### Description
Placeholder milestone for testing release scripts

### Closed Issues


## v1.13.1

### Description


### Closed Issues
* Option 'max_preserve_newlines' not working on beautify_css.js CSS Beautifier ([#1863](https://github.com/beautify-web/js-beautify/issues/1863))
* React Fragment Short Syntax <></> issue ([#1854](https://github.com/beautify-web/js-beautify/issues/1854))
* add  viewport meta tag to index.html ([#1843](https://github.com/beautify-web/js-beautify/pull/1843))
* Add basic smarty templating support ([#1820](https://github.com/beautify-web/js-beautify/issues/1820))
* Tagged Template literals ([#1244](https://github.com/beautify-web/js-beautify/issues/1244))


## v1.13.0

### Description
This release truly fixes the python cssbeautifier installation and updates cssbeautifier cli to use the same general code as jsbeautifier. 

Also, as of this release Node.js 8.x is no longer guaranteed to work. Node.js 8.x LTS reached end-of-life in January 2020. 
Parts of our test infrastructure no longer support Node.js 8.x. The js-beautifier should still run on Node.js 8.x, but it is not part of the CI system and so not guaranteed to work. 


### Closed Issues
* (internal) Refactor python cssbeautifier to reuse jsbeautifier CLI methods ([#1832](https://github.com/beautify-web/js-beautify/pull/1832))
* (internal) Switch from node-static to serve ([#1831](https://github.com/beautify-web/js-beautify/pull/1831))
* Fixed pip install cssbeautifier ([#1830](https://github.com/beautify-web/js-beautify/pull/1830))


## v1.12.0

### Description


### Closed Issues
* Python jsbeautifier fails for special chars ([#1809](https://github.com/beautify-web/js-beautify/issues/1809))
* pip install cssbeautifier fails ([#1808](https://github.com/beautify-web/js-beautify/issues/1808))
* Add expand brace-style option to css beautifier ([#1796](https://github.com/beautify-web/js-beautify/pull/1796))
* Support nullish-coalescing ([#1794](https://github.com/beautify-web/js-beautify/issues/1794))
* Upgrade ga.js to analytics.js ([#1777](https://github.com/beautify-web/js-beautify/issues/1777))
* Newline rule not working with css-like files ([#1776](https://github.com/beautify-web/js-beautify/issues/1776))
* no new line after self closing tag ([#1718](https://github.com/beautify-web/js-beautify/issues/1718))
* HTML format, no break after <label>? ([#1365](https://github.com/beautify-web/js-beautify/issues/1365))
* Does this extension still supports applying Allman style to CSS? ([#1353](https://github.com/beautify-web/js-beautify/issues/1353))
* Add brace_style option for CSS ([#1259](https://github.com/beautify-web/js-beautify/issues/1259))


## v1.11.0

### Description


### Closed Issues
* Please bump mkdirp to fix mkdirp@0.5.1 vulnerability ([#1768](https://github.com/beautify-web/js-beautify/issues/1768))
* Incorrect indentation of Handlebars inline partials ([#1756](https://github.com/beautify-web/js-beautify/issues/1756))
* Support optional-chaining ([#1727](https://github.com/beautify-web/js-beautify/issues/1727))
* Please support es module ([#1706](https://github.com/beautify-web/js-beautify/issues/1706))
* Support new js proposals: optional-chaining & pipeline-operator ([#1530](https://github.com/beautify-web/js-beautify/issues/1530))
* Optional <p> closing not implemented ([#1503](https://github.com/beautify-web/js-beautify/issues/1503))


## v1.10.3

### Description


### Closed Issues
* Unquoted href causes wrong indentation ([#1736](https://github.com/beautify-web/js-beautify/issues/1736))
* Broken private fields in classes (JS) ([#1734](https://github.com/beautify-web/js-beautify/issues/1734))
* Fix for python 2.7 and cli parameters ([#1712](https://github.com/beautify-web/js-beautify/pull/1712))
* Search (ctrl+f) works only in view field in CodeMirror ([#1696](https://github.com/beautify-web/js-beautify/issues/1696))


## v1.10.2

### Description


### Closed Issues
* Please update CodeMirror Addon ([#1695](https://github.com/beautify-web/js-beautify/issues/1695))
* Nested braces indentation ([#223](https://github.com/beautify-web/js-beautify/issues/223))


## v1.10.1

### Description


### Closed Issues
* javascript fails to format when <?php > is first text inside <script> tag ([#1687](https://github.com/beautify-web/js-beautify/issues/1687))
* 414 Request-URI Too Large ([#1640](https://github.com/beautify-web/js-beautify/issues/1640))


## v1.10.0

### Description
# Description
* Added `templating` setting to control when template languages are recognized.  All languages are off by default in Javascript and on by default in HTML. 
* Thanks to @HanabishiRecca, @averydev, @kalbasit, @asteinha  for contributions

https://github.com/beautify-web/js-beautify/compare/v1.9.1...v1.10.0



### Closed Issues
* beautifying scss selector with colon in it adds space ([#1667](https://github.com/beautify-web/js-beautify/issues/1667))
* Javascript multiline comments duplicates ([#1663](https://github.com/beautify-web/js-beautify/issues/1663))
* Tokenizer crashes if the input terminates with a dot character. ([#1658](https://github.com/beautify-web/js-beautify/issues/1658))
* stop reformatting valid css \\! into invalid \\ ! ([#1656](https://github.com/beautify-web/js-beautify/pull/1656))
* wrong indent for unclosed <? - need to support disabling templating ([#1647](https://github.com/beautify-web/js-beautify/issues/1647))
* Beautify inserts space before exclamation mark in comment <!-- in css <style> ([#1641](https://github.com/beautify-web/js-beautify/issues/1641))
* 'less' mixins parameter formatting problem ([#1582](https://github.com/beautify-web/js-beautify/issues/1582))
* Change css tests to use 4 space indenting instead of tabs ([#1527](https://github.com/beautify-web/js-beautify/issues/1527))
* Braces after case get pushed onto new line ([#1357](https://github.com/beautify-web/js-beautify/issues/1357))
* Extra space in pseudo-elements and pseudo-classes selectors ([#1233](https://github.com/beautify-web/js-beautify/issues/1233))
* LESS formatting - mixins with multiple variables ([#1018](https://github.com/beautify-web/js-beautify/issues/1018))
* Bug in less format ([#842](https://github.com/beautify-web/js-beautify/issues/842))


## v1.9.1

### Description


### Closed Issues
* nested table not beautified correctly ([#1649](https://github.com/beautify-web/js-beautify/issues/1649))
* Add an option to preserve indentation on empty lines ([#1322](https://github.com/beautify-web/js-beautify/issues/1322))


## v1.9.0

### Description
# Description
* Fixed Tab indenting - when tabs indenting enabled, they are used universally.  Also, tab size customizable: 8-space tabs would mean each tab is treated as 8 spaces. (#1294, #1551) 
* Accurate line wrapping - Layout always wraps when line length exceed specified column, unless wrapping would not reduce line length. (#284, #1238)
* Improved Template handling in HTML - Go, Django, Handlebars, ERB/EJS/ASP, PHP (still only handlebars indenting) (#881, #1602, #1620)
* Improved Template handling in Javascript - ERB/EJS/ASP, PHP (no indenting, no Django or Handlebars due to potential syntax conflicts for curly braces) (#1377)
* Fixed indenting of mustache inverted conditionals (#1623 @e2tha-e)
* Fixed indenting for HTML tags with option end tags (#1213)

https://github.com/beautify-web/js-beautify/compare/v1.8.9...v1.9.0



### Closed Issues
* Incorrect indentation of `^` inverted section tags in Handlebars/Mustache code ([#1623](https://github.com/beautify-web/js-beautify/issues/1623))
* PHP In HTML Attributes ([#1620](https://github.com/beautify-web/js-beautify/issues/1620))
* DeanEdward python unpacker offset problem ([#1616](https://github.com/beautify-web/js-beautify/issues/1616))
* CLI on Windows doesn't accept -f - for stdin? ([#1609](https://github.com/beautify-web/js-beautify/issues/1609))
* HTML type attribute breaks JavaScript beautification? ([#1606](https://github.com/beautify-web/js-beautify/issues/1606))
* Use of global MODE before declaration caused uglify problem ([#1604](https://github.com/beautify-web/js-beautify/issues/1604))
* When building html tags using Mustache variables, extra whitespace is added after opening arrow ([#1602](https://github.com/beautify-web/js-beautify/issues/1602))
* <script type="text/html">isnot abled to be beautified ([#1591](https://github.com/beautify-web/js-beautify/issues/1591))
* _get_full_indent undefined ([#1590](https://github.com/beautify-web/js-beautify/issues/1590))
* Website "autodetect" setting doesn't distinguish css vs javascript ([#1565](https://github.com/beautify-web/js-beautify/issues/1565))
* Add setting to keep HTML tag text content unformatted or ignore custom delimiters ([#1560](https://github.com/beautify-web/js-beautify/issues/1560))
* HTML auto formatting using spaces instead of tabs ([#1551](https://github.com/beautify-web/js-beautify/issues/1551))
* Unclosed single quote in php tag causes formatting changes which break php code ([#1377](https://github.com/beautify-web/js-beautify/issues/1377))
* Using tabs when wrapping attributes and wrapping if needed ([#1294](https://github.com/beautify-web/js-beautify/issues/1294))
* HTML --wrap-attributes doesn't respect --wrap-line-length ([#1238](https://github.com/beautify-web/js-beautify/issues/1238))
* Bad indent level(HTML) ([#1213](https://github.com/beautify-web/js-beautify/issues/1213))
* js-beautify produces invalid code for variables with Unicode escape sequences ([#1211](https://github.com/beautify-web/js-beautify/issues/1211))
* support vuejs ([#1154](https://github.com/beautify-web/js-beautify/issues/1154))
* Go templates in HTML ([#881](https://github.com/beautify-web/js-beautify/issues/881))
* Better behavior for javascript --wrap-line-length ([#284](https://github.com/beautify-web/js-beautify/issues/284))


## v1.8.9

### Description


### Closed Issues
* Won't run from CLI - bad option name `files` ([#1583](https://github.com/beautify-web/js-beautify/issues/1583))
* in the .vue file `space_after_anon_function` is invalid ([#1425](https://github.com/beautify-web/js-beautify/issues/1425))
* Add function default_options() to beautifier.js ([#1364](https://github.com/beautify-web/js-beautify/issues/1364))
* fix: Missing space before function parentheses ? ([#1077](https://github.com/beautify-web/js-beautify/issues/1077))
* Support globs in CLI ([#787](https://github.com/beautify-web/js-beautify/issues/787))


## v1.8.8

### Description


### Closed Issues
*  async function in object wrong indentation ([#1573](https://github.com/beautify-web/js-beautify/issues/1573))


## v1.8.7

### Description


### Closed Issues
* Add tests for html  `indent_scripts` option ([#1518](https://github.com/beautify-web/js-beautify/issues/1518))
* Support dynamic import ([#1197](https://github.com/beautify-web/js-beautify/issues/1197))
* HTML: add an option to preserve manual wrapping of attributes ([#1125](https://github.com/beautify-web/js-beautify/issues/1125))
* js-beautify adds a space between # and include ([#1114](https://github.com/beautify-web/js-beautify/issues/1114))
* space_after_anon_function doesn't work with anon async functions ([#1034](https://github.com/beautify-web/js-beautify/issues/1034))
* Space before function arguments (space-after-function) (space-after-named-function) ([#608](https://github.com/beautify-web/js-beautify/issues/608))


## v1.8.6

### Description
Beautifier has moved to https://beautifier.io

### Closed Issues
* JS beautify break the angular compile ([#1544](https://github.com/beautify-web/js-beautify/issues/1544))
* base64 string is broken with v1.8.4 ([#1535](https://github.com/beautify-web/js-beautify/issues/1535))
* Bookmarklet becomes totally useless ([#1408](https://github.com/beautify-web/js-beautify/issues/1408))
* HTTPS ([#1399](https://github.com/beautify-web/js-beautify/issues/1399))
* Beautify breaks when js starts with space followed by multi-line comment ([#789](https://github.com/beautify-web/js-beautify/issues/789))


## v1.8.4

### Description
Broader adoption of 1.8.x revealed a few more high priority fixes


### Closed Issues
* Multiple newlines added between empty textarea and "unformatted" inline elements  ([#1534](https://github.com/beautify-web/js-beautify/issues/1534))
* unindent_chained_methods broken ([#1533](https://github.com/beautify-web/js-beautify/issues/1533))


## v1.8.3

### Description


### Closed Issues
* Missing Bower Assets ([#1521](https://github.com/beautify-web/js-beautify/issues/1521))
* Javascript ternary breaked with `await` ([#1519](https://github.com/beautify-web/js-beautify/issues/1519))
* Object property indented after `await` ([#1517](https://github.com/beautify-web/js-beautify/issues/1517))
* Handlebars formatting problems ([#870](https://github.com/beautify-web/js-beautify/issues/870))
* beautify.js doesn't have indent_level option ([#724](https://github.com/beautify-web/js-beautify/issues/724))


## v1.8.1

### Description


### Closed Issues
* Why npm is a dependency? ([#1516](https://github.com/beautify-web/js-beautify/issues/1516))
* indent_inner_html not working in v1.8.0 ([#1514](https://github.com/beautify-web/js-beautify/issues/1514))


## v1.8.0

### Description
Massive set of fixes and improvements.

Thanks to contributors: @cheerypick, @swan46, @MacKLess, @Elrendio, @madman-bob, @amanda-bot, @Hirse, @aeschli, and many more.

Special thanks to @astronomersiva and @garretwilson for finding key bugs in the RC releases,
and to @MacKLess for driving down the open bug count with tons of regression tests.

Highlights:

* CSS: `newline_between_rules` support for nested rules - CSS/SASS/SCSS/LESS  (@MacKLess)
* CSS: @import support in CSS (@MacKLess)
* HTML: inline element support (@madman-bob)
* HTML: `wrap_attributes` setting `align-multiple` (@cheerypick)
* HTML: optional close tags do not over indent - li, tr, etc.
* HTML: Improved line wrapping in HTML - still not fully correct
* HTML: 10x performance improvement in HTML beautifier
* JS: ES6 BigInt support (@thejoshwolfe)
* JS: ES6 Dynamic import support 
* CSS: :hover for @extend formatting (@MacKLess)
* HTML: Incorrect line wrapping issue (@andreyvolokitin)
* JS: Javascript ++ Operator Indentation (@Elrendio)
* JS: Better packer handling in Python (@swan46)





### Closed Issues
* list items of nested lists get indented backwards ([#1501](https://github.com/beautify-web/js-beautify/issues/1501))
* Make beautifier auto-convert options with dashes into underscores ([#1497](https://github.com/beautify-web/js-beautify/issues/1497))
* ReferenceError: token is not defined ([#1496](https://github.com/beautify-web/js-beautify/issues/1496))
* Publish v1.8.0 ([#1495](https://github.com/beautify-web/js-beautify/issues/1495))
* still probem #1439 / #1337 ([#1491](https://github.com/beautify-web/js-beautify/issues/1491))
* Duplicating HTML Code Nested In PHP ([#1483](https://github.com/beautify-web/js-beautify/issues/1483))
* Handlebars - `if` tags are broken when using helper with `textarea` ([#1482](https://github.com/beautify-web/js-beautify/issues/1482))
* TypeError: Cannot read property '1' of null ([#1481](https://github.com/beautify-web/js-beautify/issues/1481))
* Space in Self Closing Tag Issue ([#1478](https://github.com/beautify-web/js-beautify/issues/1478))
* Weird Formatting in VSCode ([#1475](https://github.com/beautify-web/js-beautify/issues/1475))
* Indent with tab issue on website ([#1470](https://github.com/beautify-web/js-beautify/issues/1470))
* Contents of hbs tags are converted to lowercase ([#1464](https://github.com/beautify-web/js-beautify/issues/1464))
* HTML tags are indented wrongly when attributes are present ([#1462](https://github.com/beautify-web/js-beautify/issues/1462))
* hbs tags are stripped when there is a comment below or inline ([#1461](https://github.com/beautify-web/js-beautify/issues/1461))
* Spaces added to handlebars with '=' ([#1460](https://github.com/beautify-web/js-beautify/issues/1460))
* jsbeautifier.org don't works ([#1445](https://github.com/beautify-web/js-beautify/issues/1445))
* Commenting code and then beautifying removes line breaks ([#1440](https://github.com/beautify-web/js-beautify/issues/1440))
* Less: Where is my space? ([#1411](https://github.com/beautify-web/js-beautify/issues/1411))
* No newline after @import ([#1406](https://github.com/beautify-web/js-beautify/issues/1406))
* "html.format.wrapAttributes": "force-aligned" adds empty line on long attributes ([#1403](https://github.com/beautify-web/js-beautify/issues/1403))
* HTML: wrap_line_length is handled incorrectly ([#1401](https://github.com/beautify-web/js-beautify/issues/1401))
* js-beautify is breaking code by adding space after import ([#1393](https://github.com/beautify-web/js-beautify/issues/1393))
* JS-Beautify should format XML tags inside HTML files ([#1383](https://github.com/beautify-web/js-beautify/issues/1383))
* python unpacker can not handle if radix given as [] and not as a number ([#1381](https://github.com/beautify-web/js-beautify/issues/1381))
* unindent_chained_methods breaks indentation for if statements without brackets  ([#1378](https://github.com/beautify-web/js-beautify/issues/1378))
* function parameters merged into single line when starting with ! or [ ([#1374](https://github.com/beautify-web/js-beautify/issues/1374))
* CSS selector issue (header > div[class~="div-all"]) in SCSS file ([#1373](https://github.com/beautify-web/js-beautify/issues/1373))
* Add "Create Issue for Unexpected Output" button to website ([#1371](https://github.com/beautify-web/js-beautify/issues/1371))
* Add combobox to control type of beautification ([#1370](https://github.com/beautify-web/js-beautify/issues/1370))
* Add Options textbox to website for debugging ([#1369](https://github.com/beautify-web/js-beautify/issues/1369))
* Python version fails to properly beautify packed code ([#1367](https://github.com/beautify-web/js-beautify/issues/1367))
* preserve-newline doesn't work for text blocks inside tags ([#1352](https://github.com/beautify-web/js-beautify/issues/1352))
* How to keep comments on their own lines after formating ([#1348](https://github.com/beautify-web/js-beautify/issues/1348))
* Beautification of Multiline PHP ([#1346](https://github.com/beautify-web/js-beautify/issues/1346))
* Beautification of PHP with echo short tags ([#1339](https://github.com/beautify-web/js-beautify/issues/1339))
* <button> with force-expand-multiline formatting bug ([#1335](https://github.com/beautify-web/js-beautify/issues/1335))
* js-beautify 1.7.5 breaks some correct JS code when run with -X ([#1334](https://github.com/beautify-web/js-beautify/issues/1334))
* URGENT: @extend with :hover, :focus and so on... ([#1331](https://github.com/beautify-web/js-beautify/issues/1331))
* JSBeautify options for programmatic use? ([#1327](https://github.com/beautify-web/js-beautify/issues/1327))
* js-beautify: fix handling for --eol and --outfile ([#1315](https://github.com/beautify-web/js-beautify/pull/1315))
* Note that `gsort` is GNU sort ([#1314](https://github.com/beautify-web/js-beautify/issues/1314))
* `pip` doesn't use same version as `/usr/bin/env python` ([#1312](https://github.com/beautify-web/js-beautify/issues/1312))
* Negative numbers removes newlines in arrays ([#1288](https://github.com/beautify-web/js-beautify/issues/1288))
* Wrap and align html attributes when line reaches wrap-line-length ([#1285](https://github.com/beautify-web/js-beautify/issues/1285))
* Javascript ++ Operator get wrong indent ([#1283](https://github.com/beautify-web/js-beautify/issues/1283))
* Generate js-beautify executable properly on windows when installed from PIP ([#1266](https://github.com/beautify-web/js-beautify/issues/1266))
* Add or preserve empty line between nested SCSS rules ([#1258](https://github.com/beautify-web/js-beautify/issues/1258))
* Create beta channel for releases ([#1255](https://github.com/beautify-web/js-beautify/issues/1255))
* Add install tests for packages ([#1254](https://github.com/beautify-web/js-beautify/issues/1254))
* Formatting slow when line wrap is set ([#1231](https://github.com/beautify-web/js-beautify/issues/1231))
* [!true && ...] Negated expressions in an array get collapsed into a single line ([#1229](https://github.com/beautify-web/js-beautify/issues/1229))
* await import(...) ([#1228](https://github.com/beautify-web/js-beautify/issues/1228))
* The result of "Format document" is weird of certain HTML content. ([#1223](https://github.com/beautify-web/js-beautify/issues/1223))
* (next_tag || "").match is not a function ([#1202](https://github.com/beautify-web/js-beautify/issues/1202))
* html.format.wrapAttributes on handlebars template ([#1199](https://github.com/beautify-web/js-beautify/issues/1199))
* Don't indent unclosed HTML tags containing server directives "<@" ([#1193](https://github.com/beautify-web/js-beautify/issues/1193))
* `force-expand-multiline` doesn't work as expected ([#1186](https://github.com/beautify-web/js-beautify/issues/1186))
* HTML text content formatted incorrectly ([#1184](https://github.com/beautify-web/js-beautify/issues/1184))
* Content deleted when formatting with indent_handlebars: true ([#1174](https://github.com/beautify-web/js-beautify/issues/1174))
* Nested span tags not indenting properly ([#1167](https://github.com/beautify-web/js-beautify/issues/1167))
* SCSS Comment Issue ([#1165](https://github.com/beautify-web/js-beautify/issues/1165))
* Less function parameters are wrapped unexpected ([#1156](https://github.com/beautify-web/js-beautify/issues/1156))
* Support underscore templates ([#1130](https://github.com/beautify-web/js-beautify/issues/1130))
* html-bar/handlebar {{else if}} block is indented ([#1123](https://github.com/beautify-web/js-beautify/issues/1123))
* Wrap line length, first line not correct  ([#1122](https://github.com/beautify-web/js-beautify/issues/1122))
* TypeError: Cannot read property 'replace' of undefined ([#1120](https://github.com/beautify-web/js-beautify/issues/1120))
* Strange behaviours of formatting for double spans ([#1113](https://github.com/beautify-web/js-beautify/issues/1113))
* Missing space between "else" and "if". ([#1107](https://github.com/beautify-web/js-beautify/issues/1107))
* invalid indentation for html code ([#1098](https://github.com/beautify-web/js-beautify/issues/1098))
* HTML "select" tags have too much indentation ([#1097](https://github.com/beautify-web/js-beautify/issues/1097))
* Formatting breaks apart unquoted attribute ([#1094](https://github.com/beautify-web/js-beautify/issues/1094))
* HTML formatting wraps ending block tag for no reason with nested inline elements ([#1041](https://github.com/beautify-web/js-beautify/issues/1041))
* Ignore expressions in handlebars tags. ([#1040](https://github.com/beautify-web/js-beautify/issues/1040))
* not correctly joining lines for HTML ([#1033](https://github.com/beautify-web/js-beautify/issues/1033))
* Fails to format SVG files properly ([#1027](https://github.com/beautify-web/js-beautify/issues/1027))
* Template tags with new lines in them ([#1016](https://github.com/beautify-web/js-beautify/issues/1016))
* Span tags do not re-indent correctly ([#1010](https://github.com/beautify-web/js-beautify/issues/1010))
* Error in --eol processing in python ([#987](https://github.com/beautify-web/js-beautify/issues/987))
* Extra space added when quote is present ([#943](https://github.com/beautify-web/js-beautify/issues/943))
* weird formatting for HTML5 <tr> ([#882](https://github.com/beautify-web/js-beautify/issues/882))
* Respect non-breaking spaces ([#869](https://github.com/beautify-web/js-beautify/issues/869))
* Media Queries style issue ([#863](https://github.com/beautify-web/js-beautify/issues/863))
* Weird Beautify Style? ([#857](https://github.com/beautify-web/js-beautify/issues/857))
* "unformatted" paradigm broken, "unformatted" and "inline" are not the same ([#841](https://github.com/beautify-web/js-beautify/issues/841))
* Increment/Decrement Operator on object property extra indent on subsequent line ([#814](https://github.com/beautify-web/js-beautify/issues/814))
* Inconsistence of "newline_between_rules" with @import or @media ([#769](https://github.com/beautify-web/js-beautify/issues/769))
* Unexpected line break in "-1" ([#740](https://github.com/beautify-web/js-beautify/issues/740))
* Blank line before and after CSS / JS comments ([#736](https://github.com/beautify-web/js-beautify/issues/736))
* newline_between_rules support for Sass (enhancement) ([#657](https://github.com/beautify-web/js-beautify/issues/657))
* CSS comment spacing disregards `newline_between_rules`, `selector_separator_newline` ([#645](https://github.com/beautify-web/js-beautify/issues/645))
* HTML: wrap_line_length may produce buggy spaces ([#607](https://github.com/beautify-web/js-beautify/issues/607))
* Wrong code formatting using Handlebars ([#576](https://github.com/beautify-web/js-beautify/issues/576))
* option to ignore section or line in html ([#575](https://github.com/beautify-web/js-beautify/issues/575))
* Tokenize html before beautifying ([#546](https://github.com/beautify-web/js-beautify/issues/546))
* Extra newline is inserted after the comment line instead of before it ([#531](https://github.com/beautify-web/js-beautify/issues/531))
* html-beautify's max_preserve_newlines preserves one new line too much ([#517](https://github.com/beautify-web/js-beautify/issues/517))
* Disable/Skip HTML single-line comment  ([#426](https://github.com/beautify-web/js-beautify/issues/426))
* Add tests for various javascript dependency loading libraries ([#360](https://github.com/beautify-web/js-beautify/issues/360))
* Formatting of @import broken ([#358](https://github.com/beautify-web/js-beautify/issues/358))
* newline removal seems not to work properly (in sublime text 3 on xp pro sp3) ([#348](https://github.com/beautify-web/js-beautify/issues/348))


## v1.7.5

### Description


### Closed Issues
* Strict mode: js_source_text is not defined [CSS] ([#1286](https://github.com/beautify-web/js-beautify/issues/1286))
* Made brace_style option more inclusive ([#1277](https://github.com/beautify-web/js-beautify/pull/1277))
* White space before"!important" tag missing in CSS beautify ([#1273](https://github.com/beautify-web/js-beautify/issues/1273))


## v1.7.4

### Description
Thanks @cejast for contributing!

### Closed Issues
* Whitespace after ES7 `async` keyword for arrow functions ([#896](https://github.com/beautify-web/js-beautify/issues/896))


## v1.7.3

### Description
* Fixed broken installs

Lessons learned:
* Don't publish and go to bed.
* I thought I had sufficient test coverage and I did not. Tests will be implemented to protect against this before the next release (#1254).
* Also, this break highlights the need to create a beta channel for releases and a way to request feedback on beta releases (#1255).
* The project has been maintained by mostly one person over the past year or so, with some additions by other individuals. This break also highlights the need for this project to have a few more people who have the ability address issues/emergencies (#1256).
* Many projects do not not lock or even limit their version dependencies.  Those that do often use `^x.x.x` instead of `~x.x.x`.  Consider switching to making major version updates under more circumstances to limit risk to dependent projects.  (#1257)


### Closed Issues
* Version 1.7.0 fail to install through pip ([#1250](https://github.com/beautify-web/js-beautify/issues/1250))
* Installing js-beautify fails ([#1247](https://github.com/beautify-web/js-beautify/issues/1247))


## v1.7.0

### Description


### Closed Issues
* undindent-chained-methods option. Resolves #482 ([#1240](https://github.com/beautify-web/js-beautify/pull/1240))
* Add test and tools folder to npmignore ([#1239](https://github.com/beautify-web/js-beautify/issues/1239))
* incorrect new-line insertion after "yield" ([#1206](https://github.com/beautify-web/js-beautify/issues/1206))
* Do not modify built-in objects ([#1205](https://github.com/beautify-web/js-beautify/issues/1205))
* Fix label checking incorrect box when clicked ([#1169](https://github.com/beautify-web/js-beautify/pull/1169))
* Webpack ([#1149](https://github.com/beautify-web/js-beautify/pull/1149))
* daisy-chain indentation leads to over-indentation ([#482](https://github.com/beautify-web/js-beautify/issues/482))


## v1.6.12

### Description


### Closed Issues
* CSS: Preserve Newlines ([#537](https://github.com/beautify-web/js-beautify/issues/537))


## v1.6.11

### Description
Reverted #1117 - Preserve newlines broken

### Closed Issues
* On beautify, new line before next CSS selector ([#1142](https://github.com/beautify-web/js-beautify/issues/1142))


## v1.6.10

### Description
Added `preserver_newlines` to css beautifier

### Closed Issues


## v1.6.9

### Description
* Fixed html formatting issue with attribute wrap (Thanks, @HookyQR!)
* Fixed python package publishing


### Closed Issues
* Wrong HTML beautification starting with v1.6.5 ([#1115](https://github.com/beautify-web/js-beautify/issues/1115))
* Ignore linebreak when meet handlebar ([#1104](https://github.com/beautify-web/js-beautify/pull/1104))
* Lines are not un-indented correctly when attributes are wrapped ([#1103](https://github.com/beautify-web/js-beautify/issues/1103))
* force-aligned is not aligned when indenting with tabs ([#1102](https://github.com/beautify-web/js-beautify/issues/1102))
* Python package fails to publish  ([#1101](https://github.com/beautify-web/js-beautify/issues/1101))
* Explaination of 'operator_position' is absent from README.md ([#1047](https://github.com/beautify-web/js-beautify/issues/1047))


## v1.6.8

### Description
* Fixed a batch of comment and semicolon-less code bugs


### Closed Issues
* Incorrect indentation after loop with comment ([#1090](https://github.com/beautify-web/js-beautify/issues/1090))
* Extra newline is inserted after beautifying code with anonymous function ([#1085](https://github.com/beautify-web/js-beautify/issues/1085))
* end brace with next comment line make bad indent ([#1043](https://github.com/beautify-web/js-beautify/issues/1043))
* Javascript comment in last line doesn't beautify well ([#964](https://github.com/beautify-web/js-beautify/issues/964))
* indent doesn't work with comment (jsdoc) ([#913](https://github.com/beautify-web/js-beautify/issues/913))
* Wrong indentation, when new line between chained methods ([#892](https://github.com/beautify-web/js-beautify/issues/892))
* Comments in a non-semicolon style have extra indent ([#815](https://github.com/beautify-web/js-beautify/issues/815))
* [bug] Incorrect indentation due to commented line(s) following a function call with a function argument. ([#713](https://github.com/beautify-web/js-beautify/issues/713))
* Wrong indent formatting ([#569](https://github.com/beautify-web/js-beautify/issues/569))


## v1.6.7

### Description
Added `content_unformatted` option (Thanks @arai-a)

### Closed Issues
* HTML pre code indentation ([#928](https://github.com/beautify-web/js-beautify/issues/928))
* Beautify script/style tags but ignore their inner JS/CSS content ([#906](https://github.com/beautify-web/js-beautify/issues/906))


## v1.6.6

### Description
* Added support for editorconfig from stdin
* Added js-beautify to cdnjs
* Fixed CRLF to LF for HTML and CSS on windows
* Added inheritance/overriding to config format (Thanks @DaniGuardiola and @HookyQR)
* Added `force-align` to `wrap-attributes` (Thanks @Lukinos)
* Added `force-expand-multiline` to `wrap-attributes` (Thanks @tobias-zucali)
* Added `preserve-inline` as independent brace setting (Thanks @Coburn37)
* Fixed handlebars with angle-braces (Thanks @mmsqe)



### Closed Issues
* Wrong indentation for comment after nested unbraced control constructs ([#1079](https://github.com/beautify-web/js-beautify/issues/1079))
* Should prefer breaking the line after operator ? instead of before operator < ([#1073](https://github.com/beautify-web/js-beautify/issues/1073))
* New option "force-expand-multiline" for "wrap_attributes" ([#1070](https://github.com/beautify-web/js-beautify/pull/1070))
* Breaks if html file starts with comment ([#1068](https://github.com/beautify-web/js-beautify/issues/1068))
* collapse-preserve-inline restricts users to collapse brace_style ([#1057](https://github.com/beautify-web/js-beautify/issues/1057))
* Parsing failure on numbers with "e" ([#1054](https://github.com/beautify-web/js-beautify/issues/1054))
* Issue with Browser Instructions ([#1053](https://github.com/beautify-web/js-beautify/issues/1053))
* Add preserve inline function for expand style braces ([#1052](https://github.com/beautify-web/js-beautify/issues/1052))
* Update years in LICENSE ([#1038](https://github.com/beautify-web/js-beautify/issues/1038))
* JS. Switch with template literals. Unexpected indentation. ([#1030](https://github.com/beautify-web/js-beautify/issues/1030))
* The object with spread object formatted not correctly ([#1023](https://github.com/beautify-web/js-beautify/issues/1023))
* Bad output generator function in class ([#1013](https://github.com/beautify-web/js-beautify/issues/1013))
* Support editorconfig for stdin ([#1012](https://github.com/beautify-web/js-beautify/issues/1012))
* Publish to cdnjs ([#992](https://github.com/beautify-web/js-beautify/issues/992))
* breaks if handlebars comments contain handlebars tags ([#930](https://github.com/beautify-web/js-beautify/issues/930))
* Using jsbeautifyrc is broken ([#929](https://github.com/beautify-web/js-beautify/issues/929))
* Option to put HTML attributes on their own lines, aligned ([#916](https://github.com/beautify-web/js-beautify/issues/916))
* Erroneously changes CRLF to LF on Windows in HTML and CSS ([#899](https://github.com/beautify-web/js-beautify/issues/899))
* Weird space in {get } vs { normal } ([#888](https://github.com/beautify-web/js-beautify/issues/888))
* Bad for-of formatting with constant Array ([#875](https://github.com/beautify-web/js-beautify/issues/875))
* Problems with filter property in css and scss ([#755](https://github.com/beautify-web/js-beautify/issues/755))
* Add "collapse-one-line" option for non-collapse brace styles  ([#487](https://github.com/beautify-web/js-beautify/issues/487))


## v1.6.4

### Description
* Fixed JSX multi-line root element handling 
* Fixed CSS Combinator spacing (NOTE: use `space_around_combinator` option)
* Fixed (more) CSS pseudo-class and pseudo-element selectors (Thanks @Konamiman!)
* Fixed Shorthand generator functions and `yield*` (Thanks @jgeurts!)
* Added EditorConfig support (Thanks @ethanluoyc!)
* Added indent_body_inner_html and indent_head_inner_html (Thanks @spontaliku-softaria!)
* Added js-beautify to https://cdn.rawgit.com (Thanks @zxqfox)





### Closed Issues
* css-beautify sibling combinator space issue ([#1001](https://github.com/beautify-web/js-beautify/issues/1001))
* Bug: Breaks when the source code it found an unclosed multiline comment. ([#996](https://github.com/beautify-web/js-beautify/issues/996))
* CSS: Preserve white space before pseudo-class and pseudo-element selectors ([#985](https://github.com/beautify-web/js-beautify/pull/985))
* Spelling error in token definition ([#984](https://github.com/beautify-web/js-beautify/issues/984))
* collapse-preserve-inline does not preserve simple, single line ("return") statements ([#982](https://github.com/beautify-web/js-beautify/issues/982))
* Publish the library via cdn ([#971](https://github.com/beautify-web/js-beautify/issues/971))
* Bug with css calc() function ([#957](https://github.com/beautify-web/js-beautify/issues/957))
* &:first-of-type:not(:last-child) when prettified insert erroneous white character ([#952](https://github.com/beautify-web/js-beautify/issues/952))
* Shorthand generator functions are formatting strangely ([#941](https://github.com/beautify-web/js-beautify/issues/941))
* Add handlebars support on cli for html ([#935](https://github.com/beautify-web/js-beautify/pull/935))
* Do not put a space within `yield*` generator functions. ([#920](https://github.com/beautify-web/js-beautify/issues/920))
* Possible to add an indent_inner_inner_html option? (Prevent indenting second-level tags) ([#917](https://github.com/beautify-web/js-beautify/issues/917))
* Messing up jsx formatting multi-line attribute ([#914](https://github.com/beautify-web/js-beautify/issues/914))
* Bug report: Closing 'body' tag isn't formatted correctly ([#900](https://github.com/beautify-web/js-beautify/issues/900))
* { throw … } not working with collapse-preserve-inline ([#898](https://github.com/beautify-web/js-beautify/issues/898))
* ES6 concise method not propely indented ([#889](https://github.com/beautify-web/js-beautify/issues/889))
* CSS beautify changing symantics ([#883](https://github.com/beautify-web/js-beautify/issues/883))
* Dojo unsupported script types. ([#874](https://github.com/beautify-web/js-beautify/issues/874))
* Readme version comment  ([#868](https://github.com/beautify-web/js-beautify/issues/868))
* Extra space after pseudo-elements within :not() ([#618](https://github.com/beautify-web/js-beautify/issues/618))
* space in media queries after colon &: selectors ([#565](https://github.com/beautify-web/js-beautify/issues/565))
* Integrating editor config ([#551](https://github.com/beautify-web/js-beautify/issues/551))
* Preserve short expressions/statements on single line ([#338](https://github.com/beautify-web/js-beautify/issues/338))


## v1.6.3

### Description
Bug fixes

### Closed Issues
* CLI broken when output path is not set ([#933](https://github.com/beautify-web/js-beautify/issues/933))
* huge memory leak ([#909](https://github.com/beautify-web/js-beautify/issues/909))
* don't print unpacking errors on stdout (python) ([#884](https://github.com/beautify-web/js-beautify/pull/884))
* Fix incomplete list of non-positionable operators (python lib) ([#878](https://github.com/beautify-web/js-beautify/pull/878))
* Fix Issue #844 ([#873](https://github.com/beautify-web/js-beautify/pull/873))
* assignment exponentiation operator ([#864](https://github.com/beautify-web/js-beautify/issues/864))
* Bug in Less mixins ([#844](https://github.com/beautify-web/js-beautify/issues/844))
* Can't Nest Conditionals ([#680](https://github.com/beautify-web/js-beautify/issues/680))
* ternary operations ([#670](https://github.com/beautify-web/js-beautify/issues/670))
* Support newline before logical or ternary operator ([#605](https://github.com/beautify-web/js-beautify/issues/605))
* Provide config files for format and linting ([#336](https://github.com/beautify-web/js-beautify/issues/336))


## v1.6.2

### Description


### Closed Issues
* Add missing 'collapse-preserve-inline' option to js module ([#861](https://github.com/beautify-web/js-beautify/pull/861))


## v1.6.1

### Description
Fixes for regressions found in 1.6.0


### Closed Issues
* Inconsistent formatting for arrays of objects ([#860](https://github.com/beautify-web/js-beautify/issues/860))
* Publish v1.6.1 ([#859](https://github.com/beautify-web/js-beautify/issues/859))
* Space added to "from++" due to ES6 keyword  ([#858](https://github.com/beautify-web/js-beautify/issues/858))
* Changelog generator doesn't sort versions above 9 right ([#778](https://github.com/beautify-web/js-beautify/issues/778))
* space-after-anon-function not applied to object properties ([#761](https://github.com/beautify-web/js-beautify/issues/761))
* Separating 'input' elements adds whitespace ([#580](https://github.com/beautify-web/js-beautify/issues/580))
* Inline Format ([#572](https://github.com/beautify-web/js-beautify/issues/572))
* Preserve attributes line break in HTML ([#455](https://github.com/beautify-web/js-beautify/issues/455))
* Multiline Array ([#406](https://github.com/beautify-web/js-beautify/issues/406))


## v1.6.0

### Description
* Inline/short object and json preservation (all rejoice!)
* ES6 annotations, module import/export, arrow functions, concise methods, and more
* JSX spread attributes
* HTML wrap attributes, inline element fixes, doctype and php fixes
* Test framework hardening
* Windows build fixed and covered by appveyor continuous integration



### Closed Issues
* Individual tests pollute options object ([#855](https://github.com/beautify-web/js-beautify/issues/855))
* Object attribute assigned fat arrow function with implicit return of a ternary causes next line to indent ([#854](https://github.com/beautify-web/js-beautify/issues/854))
* Treat php tags as single in html ([#850](https://github.com/beautify-web/js-beautify/pull/850))
* Read piped input by default ([#849](https://github.com/beautify-web/js-beautify/pull/849))
* Replace makefile dependency with bash script ([#848](https://github.com/beautify-web/js-beautify/pull/848))
* list of HTML inline elements incomplete; wraps inappropriately ([#840](https://github.com/beautify-web/js-beautify/issues/840))
* Beautifying bracket-less if/elses ([#838](https://github.com/beautify-web/js-beautify/issues/838))
* <col> elements within a <colgroup> are getting indented incorrectly ([#836](https://github.com/beautify-web/js-beautify/issues/836))
* single attribute breaks jsx beautification ([#834](https://github.com/beautify-web/js-beautify/issues/834))
* Improve Python packaging ([#831](https://github.com/beautify-web/js-beautify/pull/831))
* Erroneously changes CRLF to LF on Windows. ([#829](https://github.com/beautify-web/js-beautify/issues/829))
* Can't deal with XHTML5 ([#828](https://github.com/beautify-web/js-beautify/issues/828))
* HTML after PHP is indented ([#826](https://github.com/beautify-web/js-beautify/issues/826))
* exponentiation operator ([#825](https://github.com/beautify-web/js-beautify/issues/825))
* Add support for script type "application/ld+json" ([#821](https://github.com/beautify-web/js-beautify/issues/821))
* package.json: Remove "preferGlobal" option ([#820](https://github.com/beautify-web/js-beautify/pull/820))
* Don't use array.indexOf() to support legacy browsers ([#816](https://github.com/beautify-web/js-beautify/pull/816))
* ES6 Object Shortand Indenting Weirdly Sometimes ([#810](https://github.com/beautify-web/js-beautify/issues/810))
* Implicit Return Function on New Line not Preserved ([#806](https://github.com/beautify-web/js-beautify/issues/806))
* Misformating "0b" Binary Strings ([#803](https://github.com/beautify-web/js-beautify/issues/803))
* Beautifier breaks ES6 nested template strings ([#797](https://github.com/beautify-web/js-beautify/issues/797))
* Misformating "0o" Octal Strings ([#792](https://github.com/beautify-web/js-beautify/issues/792))
* Do not use hardcoded directory for tests ([#788](https://github.com/beautify-web/js-beautify/pull/788))
* Handlebars {{else}} tag not given a newline ([#784](https://github.com/beautify-web/js-beautify/issues/784))
* Wrong indentation for XML header (<?xml version="1.0"?>) ([#783](https://github.com/beautify-web/js-beautify/issues/783))
* is_whitespace for loop incrementing wrong variable ([#777](https://github.com/beautify-web/js-beautify/pull/777))
* Newline is inserted after comment with comma_first ([#775](https://github.com/beautify-web/js-beautify/issues/775))
* Cannot copy more than 1000 characters out of CodeMirror buffer ([#768](https://github.com/beautify-web/js-beautify/issues/768))
* Missing 'var' in beautify-html.js; breaks strict mode ([#763](https://github.com/beautify-web/js-beautify/issues/763))
* Fix typo in the example javascript code of index.html ([#753](https://github.com/beautify-web/js-beautify/pull/753))
* Prevent incorrect wrapping of return statements. ([#751](https://github.com/beautify-web/js-beautify/pull/751))
* `js-beautify -X` breaks code with jsx spread attributes ([#734](https://github.com/beautify-web/js-beautify/issues/734))
* Unhelpful error when .jsbeautifyrc has invalid json ([#728](https://github.com/beautify-web/js-beautify/issues/728))
* Support for ES7 decorators ([#685](https://github.com/beautify-web/js-beautify/issues/685))
* Don't wrap XML declaration (or processing instructions) ([#683](https://github.com/beautify-web/js-beautify/pull/683))
* JSX/JS: Single field objects should not expand ([#674](https://github.com/beautify-web/js-beautify/issues/674))
* ES6 Module Loading Object Destructuring newlines ([#668](https://github.com/beautify-web/js-beautify/issues/668))
* Beautifying css tears @media in two lines, adds spaces in names with hyphens ([#656](https://github.com/beautify-web/js-beautify/issues/656))
* ES6 concise method not propely indented ([#647](https://github.com/beautify-web/js-beautify/issues/647))
* Extra newline inserted with `wrap_attributes` set to "force" ([#641](https://github.com/beautify-web/js-beautify/issues/641))
* `wrap_attributes` ignores `wrap_attributes_indent_size` and `wrap_line_length` when set to "auto" ([#640](https://github.com/beautify-web/js-beautify/issues/640))
* Error building on Windows ([#638](https://github.com/beautify-web/js-beautify/issues/638))
* Mixed shorthand function with arrow function in object literal is mis-formatted ([#602](https://github.com/beautify-web/js-beautify/issues/602))
* Space does not let save using "&:" ([#594](https://github.com/beautify-web/js-beautify/issues/594))
* Indenting is broken in some cases ([#578](https://github.com/beautify-web/js-beautify/issues/578))
* modified cli.js so that it can read from piped input by default ([#558](https://github.com/beautify-web/js-beautify/pull/558))
* Update release process instructions ([#543](https://github.com/beautify-web/js-beautify/issues/543))
* Publish v1.6.0 ([#542](https://github.com/beautify-web/js-beautify/issues/542))
* es6 destructuring ([#511](https://github.com/beautify-web/js-beautify/issues/511))
* NPM js-beautify: different treatment of "-" in command line ([#390](https://github.com/beautify-web/js-beautify/issues/390))
* Newline inserted after ES6 module import/export ([#382](https://github.com/beautify-web/js-beautify/issues/382))
* Option to preserve or inline "short objects" on a single line ([#315](https://github.com/beautify-web/js-beautify/issues/315))
* Format json in line ([#114](https://github.com/beautify-web/js-beautify/issues/114))


## v1.5.10

### Description
Hotfix for directives
Version jump due to release script tweaks


### Closed Issues
* Preserve directive doesn't work as intended ([#723](https://github.com/beautify-web/js-beautify/issues/723))


## v1.5.7

### Description
* Beautifier does not break PHP and Underscore.js templates
* Fix for SCSS pseudo classes and intperpolation/mixins
* Alternative Newline Characters in CSS and HTML
* Preserve formatting or completely ignore section of javascript using comments


### Closed Issues
* Support for legacy JavaScript versions (e.g. WSH+JScript & Co) ([#720](https://github.com/beautify-web/js-beautify/pull/720))
* Is \\n hard coded into CSS Beautifier logic? ([#715](https://github.com/beautify-web/js-beautify/issues/715))
* Spaces and linebreaks after # and around { } messing up interpolation/mixins (SASS/SCSS) ([#689](https://github.com/beautify-web/js-beautify/issues/689))
* Calls to functions get completely messed up in Sass (*.scss) ([#675](https://github.com/beautify-web/js-beautify/issues/675))
* No new line after selector in scss files ([#666](https://github.com/beautify-web/js-beautify/issues/666))
* using html-beautify on handlebars template deletes unclosed tag if on second line ([#623](https://github.com/beautify-web/js-beautify/issues/623))
* more Extra space after scss pseudo classes ([#557](https://github.com/beautify-web/js-beautify/issues/557))
* Unnecessary spaces in PHP code ([#490](https://github.com/beautify-web/js-beautify/issues/490))
* Some underscore.js template tags are broken ([#417](https://github.com/beautify-web/js-beautify/issues/417))
* Selective ignore using comments (feature request) ([#384](https://github.com/beautify-web/js-beautify/issues/384))


## v1.5.6

### Description
* JSX support!
* Alternative Newline Characters
* CSS and JS comment formatting fixes 
* General bug fixing


### Closed Issues
* Fix tokenizer's bracket pairs' open stack ([#693](https://github.com/beautify-web/js-beautify/pull/693))
* Indentation is incorrect for HTML5 void tag <source> ([#692](https://github.com/beautify-web/js-beautify/issues/692))
* Line wrapping breaks at the wrong place when the line is indented. ([#691](https://github.com/beautify-web/js-beautify/issues/691))
* Publish v1.5.6 ([#687](https://github.com/beautify-web/js-beautify/issues/687))
* Replace existing file fails using python beautifier ([#686](https://github.com/beautify-web/js-beautify/issues/686))
* Pseudo-classes formatted incorrectly and inconsistently with @page ([#661](https://github.com/beautify-web/js-beautify/issues/661))
* doc: add end_with_newline option ([#650](https://github.com/beautify-web/js-beautify/pull/650))
* Improve support for xml parts of jsx (React) => spaces, spread attributes and nested objects break the process ([#646](https://github.com/beautify-web/js-beautify/issues/646))
* html-beautify formats handlebars comments but does not format html comments ([#635](https://github.com/beautify-web/js-beautify/issues/635))
* Support for ES7 async ([#630](https://github.com/beautify-web/js-beautify/issues/630))
* css beautify adding an extra newline after a comment line in a css block ([#609](https://github.com/beautify-web/js-beautify/issues/609))
* No option to "Indent with tabs" for HTML files ([#587](https://github.com/beautify-web/js-beautify/issues/587))
* Function body is indented when followed by a comment ([#583](https://github.com/beautify-web/js-beautify/issues/583))
* JSX support ([#425](https://github.com/beautify-web/js-beautify/issues/425))
* Alternative Newline Characters ([#260](https://github.com/beautify-web/js-beautify/issues/260))


## v1.5.5

### Description
* Initial implementation of comma-first formatting - Diff-friendly literals!
* CSS: Add newline between rules
* LESS: improved function parameter formatting
* HTML: options for wrapping attributes
* General bug fixing

### Closed Issues
* Add GUI support for `--indent-inner-html`. ([#633](https://github.com/beautify-web/js-beautify/pull/633))
* Publish v1.5.5 ([#629](https://github.com/beautify-web/js-beautify/issues/629))
* CSS: Updating the documentation for the 'newline_between_rules' ([#615](https://github.com/beautify-web/js-beautify/pull/615))
* Equal Sign Removed from Filter Properties Alpha Opacity Assignment ([#599](https://github.com/beautify-web/js-beautify/issues/599))
* Keep trailing spaces on comments ([#598](https://github.com/beautify-web/js-beautify/issues/598))
* only print the file names of changed files ([#597](https://github.com/beautify-web/js-beautify/issues/597))
*  CSS: support add newline between rules ([#574](https://github.com/beautify-web/js-beautify/pull/574))
* elem[array]++ changes to elem[array] ++ inserting unnecessary gap ([#570](https://github.com/beautify-web/js-beautify/issues/570))
* add support to less functions paramters braces ([#568](https://github.com/beautify-web/js-beautify/pull/568))
* selector_separator_newline: true for Sass doesn't work ([#563](https://github.com/beautify-web/js-beautify/issues/563))
* yield statements are being beautified to their own newlines since 1.5.2 ([#560](https://github.com/beautify-web/js-beautify/issues/560))
* HTML beautifier inserts extra newline into `<li>`s ending with `<code>` ([#524](https://github.com/beautify-web/js-beautify/issues/524))
* Add wrap_attributes option ([#476](https://github.com/beautify-web/js-beautify/issues/476))
* Add or preserve empty line between CSS rules ([#467](https://github.com/beautify-web/js-beautify/issues/467))
* Support comma first style of variable declaration ([#245](https://github.com/beautify-web/js-beautify/issues/245))


## v1.5.4

### Description
* Fix for LESS/CSS pseudo/classes
* Fix for HTML img tag spaces

https://github.com/beautify-web/js-beautify/compare/v1.5.3...v1.5.4

### Closed Issues
* TypeScript oddly formatted with 1.5.3 ([#552](https://github.com/beautify-web/js-beautify/issues/552))
* HTML beautifier inserts double spaces between adjacent tags ([#525](https://github.com/beautify-web/js-beautify/issues/525))
* Keep space in font rule ([#491](https://github.com/beautify-web/js-beautify/issues/491))
* [Brackets plug in] Space after </a> disappears ([#454](https://github.com/beautify-web/js-beautify/issues/454))
* Support nested pseudo-classes and parent reference (LESS) ([#427](https://github.com/beautify-web/js-beautify/pull/427))
* Alternate approach: preserve single spacing and treat img as inline element ([#415](https://github.com/beautify-web/js-beautify/pull/415))


## v1.5.3

### Description
* High priority bug fixes
* Major fixes to css-beautifier to not blow up LESS/SCSS
* Lower priority bug fixes that were very ugly

https://github.com/beautify-web/js-beautify/compare/v1.5.2...v1.5.3

### Closed Issues
* [TypeError: Cannot read property 'type' of undefined] ([#548](https://github.com/beautify-web/js-beautify/issues/548))
* Bug with RegExp ([#547](https://github.com/beautify-web/js-beautify/issues/547))
* Odd behaviour on less ([#520](https://github.com/beautify-web/js-beautify/issues/520))
* css beauitify ([#506](https://github.com/beautify-web/js-beautify/issues/506))
* Extra space after scss pseudo classes. ([#500](https://github.com/beautify-web/js-beautify/issues/500))
* Generates invalid scss when formatting ampersand selectors ([#498](https://github.com/beautify-web/js-beautify/issues/498))
* bad formatting of .less files using @variable or &:hover syntax ([#489](https://github.com/beautify-web/js-beautify/issues/489))
* Incorrect beautifying of CSS comment including an url. ([#466](https://github.com/beautify-web/js-beautify/issues/466))
* Handle SASS parent reference &: ([#414](https://github.com/beautify-web/js-beautify/issues/414))
* Js-beautify breaking selectors in less code.  ([#410](https://github.com/beautify-web/js-beautify/issues/410))
* Problem with "content" ([#364](https://github.com/beautify-web/js-beautify/issues/364))
* Space gets inserted between function and paren for function in Define  ([#313](https://github.com/beautify-web/js-beautify/issues/313))
* beautify-html returns null on broken html ([#301](https://github.com/beautify-web/js-beautify/issues/301))
* Indentation of functions inside conditionals not passing jslint ([#298](https://github.com/beautify-web/js-beautify/issues/298))


## v1.5.2

### Description
* Improved indenting for statements, array, variable declaration, "Starless" block-comments
* Support for bitwise-not, yield, get, set, let, const, generator functions
* Reserved words can be used as object property names
* Added options: space_after_anon_function, end-with-newline
* Properly tokenize Numbers (including decimals and exponents)
* Do not break "x++ + y"
* function declaration inside array behaves the same as in expression
* Close String literals at newline
* Support handlebar syntax 
* Check `<script>` "type"-attribute
* Allow `<style>` and `<script>` tags to be unformatted
* Port css nesting fix to python
* Fix python six dependency
* Initial very cursory support for ES6 module, export, and import 

https://github.com/beautify-web/js-beautify/compare/v1.5.1...v1.5.2

### Closed Issues
* Allow custom elements to be unformatted ([#540](https://github.com/beautify-web/js-beautify/pull/540))
* Need option to ignore brace style ([#538](https://github.com/beautify-web/js-beautify/issues/538))
* Refactor to Output and OutputLine classes ([#536](https://github.com/beautify-web/js-beautify/pull/536))
* Recognize ObjectLiteral on open brace ([#535](https://github.com/beautify-web/js-beautify/pull/535))
* Refactor to fully tokenize before formatting ([#530](https://github.com/beautify-web/js-beautify/pull/530))
* Cleanup checked in six.py file ([#527](https://github.com/beautify-web/js-beautify/pull/527))
* Changelog.md? ([#526](https://github.com/beautify-web/js-beautify/issues/526))
* New line added between each css declaration ([#523](https://github.com/beautify-web/js-beautify/issues/523))
* Kendo Template scripts get messed up! ([#516](https://github.com/beautify-web/js-beautify/issues/516))
* SyntaxError: Unexpected token ++ ([#514](https://github.com/beautify-web/js-beautify/issues/514))
* space appears before open square bracket when the object name is "set" ([#508](https://github.com/beautify-web/js-beautify/issues/508))
* Unclosed string problem ([#505](https://github.com/beautify-web/js-beautify/issues/505))
* "--n" and "++n" are not indented like "n--" and "n++" are... ([#495](https://github.com/beautify-web/js-beautify/issues/495))
* Allow `<style>` and `<script>` tags to be unformatted ([#494](https://github.com/beautify-web/js-beautify/pull/494))
* Preserve new line at end of file ([#492](https://github.com/beautify-web/js-beautify/issues/492))
* Line wraps breaking numbers (causes syntax error) ([#488](https://github.com/beautify-web/js-beautify/issues/488))
* jsBeautify acts differently when handling different kinds of function expressions ([#485](https://github.com/beautify-web/js-beautify/issues/485))
* AttributeError: 'NoneType' object has no attribute 'groups' ([#479](https://github.com/beautify-web/js-beautify/issues/479))
* installation doco for python need update -- pip install six? ([#478](https://github.com/beautify-web/js-beautify/issues/478))
* Move einars/js-beautify to beautify-web/js-beautify ([#475](https://github.com/beautify-web/js-beautify/issues/475))
* Bring back space_after_anon_function ([#474](https://github.com/beautify-web/js-beautify/pull/474))
* fix for #453, Incompatible handlebar syntax ([#468](https://github.com/beautify-web/js-beautify/pull/468))
* Python: missing explicit dependency on "six" package ([#465](https://github.com/beautify-web/js-beautify/issues/465))
* function declaration inside array, adds extra line.  ([#464](https://github.com/beautify-web/js-beautify/issues/464))
* [es6] yield a array ([#458](https://github.com/beautify-web/js-beautify/issues/458))
* Publish v1.5.2 ([#452](https://github.com/beautify-web/js-beautify/issues/452))
* Port css colon character fix to python  ([#446](https://github.com/beautify-web/js-beautify/issues/446))
* Cannot declare object literal properties with unquoted reserved words ([#440](https://github.com/beautify-web/js-beautify/issues/440))
* Do not put a space within `function*` generator functions. ([#428](https://github.com/beautify-web/js-beautify/issues/428))
* beautification of "nth-child" css fails csslint ([#418](https://github.com/beautify-web/js-beautify/issues/418))
* comment breaks indent ([#413](https://github.com/beautify-web/js-beautify/issues/413))
* AngularJS inline templates are being corrupted! ([#385](https://github.com/beautify-web/js-beautify/issues/385))
* Beautify HTML: Setting inline JS and CSS to stay unformatted ([#383](https://github.com/beautify-web/js-beautify/issues/383))
* Spaces in function definition ([#372](https://github.com/beautify-web/js-beautify/issues/372))
* Chained code indents break at comment lines ([#314](https://github.com/beautify-web/js-beautify/issues/314))
* Handling of newlines around if/else/if statements ([#311](https://github.com/beautify-web/js-beautify/issues/311))
* Tags in javascript are being destroyed ([#117](https://github.com/beautify-web/js-beautify/issues/117))


