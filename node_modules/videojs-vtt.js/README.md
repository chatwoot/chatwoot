# videojs-vtt.js

[![npm-version](http://img.shields.io/npm/v/videojs-vtt.js.svg)](https://www.npmjs.org/package/videojs-vtt.js) [![Dependency Status](https://david-dm.org/videojs/vtt.js.svg?theme=shields.io)](https://david-dm.org/videojs/vtt.js) [![devDependency Status](https://david-dm.org/videojs/vtt.js/dev-status.svg?theme=shields.io)](https://david-dm.org/videojs/vtt.js#info=devDependencies)

Implementation of the [WebVTT](https://developer.mozilla.org/en-US/docs/HTML/WebVTT) spec in JavaScript.

This is a fork of [Mozilla's vtt.js](http://github.com/mozilla/vtt.js) (which is used for parsing and processing WebVTT files in Firefox/Gecko) with some changes that are used by [Video.js](http://github.com/videojs/video.js).

## Table of Contents

- [Spec Compliance](#spec-compliance)
- [API](#api)
  - [WebVTT.Parser](#webvttparser)
    - [parse(data)](#parsedata)
    - [flush()](#flush)
    - [onregion(region)](#onregionregion)
    - [oncue(cue)](#oncuecue)
    - [onflush()](#onflush)
    - [onparsingerror(error)](#onparsingerrorerror)
    - [ontimestampmap(timestampmap)](#ontimestampmaptimestampmap)
  - [WebVTT.convertCueToDOMTree(window, cuetext)](#webvttconvertcuetodomtreewindow-cuetext)
  - [WebVTT.processCues(window, cues, overlay)](#webvttprocesscueswindow-cues-overlay)
  - [ParsingError](#parsingerror)
  - [VTTCue](#vttcue)
    - [Extended API](#extended-api)
      - [toJSON()](#tojson)
      - [VTTCue.fromJSON(json)](#vttcuefromjsonjson)
      - [VTTCue.create(options)](#vttcuecreateoptions)
  - [VTTRegion](#vttregion)
    - [Extended API](#extended-api-1)
        - [VTTRegion.fromJSON(json)](#vttregionfromjsonjson)
        - [VTTRegion.create(options)](#vttregioncreateoptions)
- [Browser](#browser)
  - [Building Yourself](#building-yourself)
  - [Bower](#bower)
  - [Usage](#usage)
- [Node](#node)
  - [vtt.js](#vttjs-1)
  - [node-vtt](#node-vtt)
- [Developing vtt.js](#developing-vttjs)
  - [Tests](#tests)
    - [Writing Tests](#writing-tests)
  - [Grunt Run Task](#grunt-run-task)

# Spec Compliance

- [Parsing](http://dev.w3.org/html5/webvtt/#webvtt-file-format-parsing) (Completed)
  - [File](http://dev.w3.org/html5/webvtt/#webvtt-file-parsing) (Completed)
  - [Region](http://dev.w3.org/html5/webvtt/#webvtt-region-settings-parsing) (Completed)
  - [Cue Timings and Settings](http://dev.w3.org/html5/webvtt/#webvtt-cue-timings-and-settings-parsing) (Completed)
  - [WebVTT Cue Text](http://dev.w3.org/html5/webvtt/#dfn-webvtt-cue-text-parsing-rules) (Completed)
  - [Cue DOM Construction](http://dev.w3.org/html5/webvtt/#webvtt-cue-text-dom-construction-rules) (Completed)
- [Rendering](http://dev.w3.org/html5/webvtt/#rendering) (In Progress)
  - [Processing Model](http://dev.w3.org/html5/webvtt/#processing-model) (In Progress) ***No VTTRegion or vertical text support***
    - [Apply WebVTT Cue Settings](http://dev.w3.org/html5/webvtt/#dfn-apply-webvtt-cue-settings) (In Progress)
      - Steps 1 - 11 (Completed)
      - Step 12 (In progress)
  - [Applying CSS Properties](http://dev.w3.org/html5/webvtt/#applying-css-properties-to-webvtt-node-objects) (Completed)
  - [CSS Extensions](http://dev.w3.org/html5/webvtt/#css-extensions) **(Won't Implement)**
- [WebVTT API Shim](http://dev.w3.org/html5/webvtt/#webvtt-api-for-browsers) (Completed)
  - [VTTCue](http://dev.w3.org/html5/webvtt/#vttcue-interface) (Completed) ***Shims the TextTrackCue interface as well***
  - [VTTRegion](http://dev.w3.org/html5/webvtt/#vttregion-interface) (Completed)

## Notes

Our processing model portion of the specification makes use of a custom property, `hasBeenReset`. It allows us to detect
when a VTTCue is dirty, i.e. one of its properties that affects display has changed and so we need to recompute its display
state. This allows us to reuse a cue's display state if it has already been computed and nothing has changed to effect its
position.

# API

## WebVTT.Parser

The parser has a simple API:

```javascript
var parser = new WebVTT.Parser(window, stringDecoder);
parser.onregion = function(region) {};
parser.oncue = function(cue) {};
parser.onflush = function() {};
parser.onparsingerror = function(e) {};
parser.parse(moreData);
parser.parse(moreData);
parser.flush();
```

The Parser constructor is passed a window object with which it will create new
VTTCues and VTTRegions as well as an optional StringDecoder object which
it will use to decode the data that the `parse()` function receives. For ease of
use, a StringDecoder is provided via `WebVTT.StringDecoder()`. If a custom
StringDecoder object is passed in it must support the API specified by the
[#whatwg string encoding](http://encoding.spec.whatwg.org/#api) spec.

### parse(data)

Hands data in some format to the parser for parsing. The passed data format
is expected to be decodable by the StringDecoder object that it has. The parser
decodes the data and reassembles partial data (streaming), even across line breaks.

```javascript
var parser = new WebVTT.Parser(window, WebVTT.StringDecoder());
parser.parse("WEBVTT\n\n");
parser.parse("00:32.500 --> 00:33.500 align:start size:50%\n");
parser.parse("<v.loud Mary>That's awesome!");
parser.flush();
```

### flush()

Indicates that no more data is expected and will force the parser to parse any
unparsed data that it may have. Will also trigger [onflush](#onflush).

### onregion(region)

Callback that is invoked for every region that is correctly parsed. Returns a [VTTRegion](#http://dev.w3.org/html5/webvtt/#dfn-vttregion)
object.

```js
parser.onregion = function(region) {
  console.log(region);
};
```

### oncue(cue)

Callback that is invoked for every cue that is fully parsed. In case of streaming parsing oncue is
delayed until the cue has been completely received. Returns a [VTTCue](#http://dev.w3.org/html5/webvtt/#vttcue-interface) object.

```js
parser.oncue = function(cue) {
  console.log(cue);
};
```

### onflush()

Is invoked in response to `flush()` and after the content was parsed completely.

```js
parser.onflush = function() {
  console.log("Flushed");
};
```

### onparsingerror(error)

Is invoked when a parsing error has occurred. This means that some part of the
WebVTT file markup is badly formed. See [ParsingError](#parsingerror) for more
information.

```js
parser.onparsingerror = function(e) {
  console.log(e);
};
```

### ontimestampmap(timestampmap)

Is invoked when an `X-TIMESTAMP-MAP` metadata header ([defined here](https://tools.ietf.org/html/draft-pantos-http-live-streaming-20#section-3.5)) is parsed. This header maps WebVTT cue timestamps to MPEG-2 (PES) timestamps in other Renditions of the Variant Stream.

```js
parser.ontimestampmap = function(timestamp) {
  console.log('LOCAL:', timestamp.LOCAL);
  console.log('MPEGTS:', timestamp.MPEGTS);
};
```

## WebVTT.convertCueToDOMTree(window, cuetext)

Parses the cue text handed to it into a tree of DOM nodes that mirrors the internal WebVTT node structure of
the cue text. It uses the window object handed to it to construct new HTMLElements and returns a tree of DOM
nodes attached to a top level div.

```javascript
var div = WebVTT.convertCueToDOMTree(window, cuetext);
```

## WebVTT.processCues(window, cues, overlay)

Converts the cuetext of the cues passed to it to DOM trees&mdash;by calling convertCueToDOMTree&mdash;and
then runs the processing model steps of the WebVTT specification on the divs. The processing model applies the necessary
CSS styles to the cue divs to prepare them for display on the web page. During this process the cue divs get added
to a block level element (overlay). The overlay should be a part of the live DOM as the algorithm will use the
computed styles (only of the divs to do overlap avoidance.

```javascript
var divs = WebVTT.processCues(window, cues, overlay);
```

## ParsingError

A custom JS error object that is reported through the
[onparsingerror](#onparsingerror) callback. It has a `name`, `code`, and
`message` property, along with all the regular properties that come with a
JavaScript error object.

```json
{
  "name": "ParsingError",
  "code": "SomeCode",
  "message": "SomeMessage"
}
```

There are two error codes that can be reported back currently:

- 0 BadSignature
- 1 BadTimeStamp

**Note:** Exceptions other then `ParsingError` will be thrown and not reported.

## VTTCue

A DOM shim for the VTTCue. See the [spec](http://dev.w3.org/html5/webvtt/#vttcue-interface)
for more information. Our VTTCue shim also includes properties of its abstract base class
[TextTrackCue](http://www.whatwg.org/specs/web-apps/current-work/multipage/the-video-element.html#texttrackcue).

```js
var cue = new window.VTTCue(0, 1, "I'm a cue.");
```

**Note:** Since this polyfill doesn't implement the track specification directly the `onenter`
and `onexit` events will do nothing and do not exist on this shim.

### Extended API

There is also an extended version of this shim that gives a few convenience methods
for converting back and forth between JSON and VTTCues. If you'd like to use these
methods then use `vttcue-extended.js` instead of `vttcue.js`. This isn't normally
built into the `vtt.js` distributable so you will have to build a custom distribution
instead of using bower.

#### toJSON()

Converts a cue to JSON.

```js
var json = cue.toJSON();
```

#### VTTCue.fromJSON(json)

Create and initialize a VTTCue from JSON.

```js
var cue = VTTCue.fromJSON(json);
```

#### VTTCue.create(options)

Initializes a VTTCue from an options object where the properties in the option
objects are the same as the properties on the VTTCue.

```js
var cue = VTTCue.create(options);
```

## VTTRegion

A DOM shim for the VTTRegion. See the [spec](http://dev.w3.org/html5/webvtt/#vttregion-interface)
for more information.

```js
var region = new window.VTTRegion(0, 1, "I'm a region.");
cue.region = region;
```

### Extended API

There is also an extended version of this shim that gives a few convenience methods
for converting back and forth between JSON and VTTRegions. If you'd like to use these
methods then us `vttregion-extended.js` instead of `vttregion.js`. This isn't normally
built into the `vtt.js` distributable so you will have to build a custom distribution
instead of using bower.

#### VTTRegion.fromJSON(json)

Creates and initializes a VTTRegion from JSON.

```js
var region = VTTRegion.fromJSON(json);
```

#### VTTRegion.create(options)

Creates a VTTRegion from an options object where the properties on the options
object are the same as the properties on the VTTRegion.

```js
var region = VTTRegion.create(options);
```

# Browser

In order to use the `vtt.js` in a browser, you need to get the built distribution of vtt.js. The distribution
contains polyfills for [TextDecoder](http://encoding.spec.whatwg.org/), [VTTCue](http://dev.w3.org/html5/webvtt/#vttcue-interface),
and [VTTRegion](http://dev.w3.org/html5/webvtt/#vttregion-interface) since not all browsers currently
support them.

## Building Yourself

Building a browser-ready version of the library is done using `grunt` (if you haven't installed
`grunt` globally, you can run it from `./node_modules/.bin/grunt` after running `npm install`):

```bash
$ grunt build
$ Running "uglify:dist" (uglify) task
$ File "dist/vtt.min.js" created.

$ Running "concat:dist" (concat) task
$ File "dist/vtt.js" created.

$ Done, without errors.
```

Your newly built `vtt.js` now lives in `dist/vtt.min.js`, or alternatively, `dist/vtt.js` for an
unminified version.

## Bower

You can also get the a prebuilt distribution from [Bower](http://bower.io/). Either run the shell
command:

```bash
$ bower install vtt.js
```

Or include `vtt.js` as a dependency in your `bower.json` file. `vtt.js` should now
live in `bower_components/vtt.js/vtt.min.js`. There is also an unminified
version included with bower at `bower_components/vtt.js/vtt.js`.

## Usage

To use `vtt.js` you can just include the script on an HTML page like so:

```html
<html>
<head>
  <meta charset="utf-8">
  <title>vtt.js in the browser</title>
  <script src="bower_components/vtt.js/vtt.min.js"></script>
</head>
<body>
  <script>
    var vtt = "WEBVTT\n\nID\n00:00.000 --> 00:02.000\nText",
        parser = new WebVTT.Parser(window, WebVTT.StringDecoder()),
        cues = [],
        regions = [];
    parser.oncue = function(cue) {
      cues.push(cue);
    };
    parser.onregion = function(region) {
      regions.push(region);
    }
    parser.parse(vtt);
    parser.flush();

    var div = WebVTT.convertCueToDOMTree(window, cues[0].text);
    var divs = WebVTT.processCues(window, cues, document.getElementById("overlay"));
  </script>
  <div id="overlay" style="position: relative; width: 300px; height: 150px"></div>
</body>
</html>
```

# Node

You have a couple of options if you'd like to run the library from Node.

## vtt.js

`vtt.js` is on npm. Just do:

```
npm install vtt.js
```

Require it and use it:

```js
var vtt = require("vtt.js"),
    WebVTT = vtt.WebVTT,
    VTTCue = vtt.VTTCue,
    VTTRegion = vtt.VTTRegion;

var parser = new WebVTT.Parser(window);
parser.parse();
// etc

var elements = WebVTT.processCues(window, cues, overlay);
var element = WebVTT.convertCueToDOMTree(window, cuetext);

var cue = new VTTCue(0, 1, "I'm a cue.");
var region = new VTTRegion();
```

See the [API](#api) for more information on how to use it.

**Note:** If you use this method you will have to provide your own window object
or a shim of one with the necessary functionality for either the parsing or processing
portion of the spec. The only shims that are provided to you are `VTTCue` and `VTTRegion`
which you can attach to your global that is passed into the various functions.

## node-vtt

Use [node-vtt](https://github.com/mozilla/node-vtt). Node-vtt runs `vtt.js` on a PhantomJS page
from Node so it has access to a full DOM and CSS layout engine which means you can run any part
of the library you want. See the [node-vtt](https://github.com/mozilla/node-vtt) repo for more
information.

# Developing vtt.js

A few things to note:

* When bumping the version remember to use the `grunt release` task as this will
bump `package.json` + `bower.json` and build the `dist` files for `vtt.js` in one
go.
* The [Grunt Run Task](#grunt-run-task) tool is handy for running the library without having
to run the whole test suite or set of tests.

## Tests

Tests are written and run using [Mocha](https://mochajs.org/) on node.js.

To run all the tests, do the following:

```bash
$ npm test
```

If you want to run individual tests, you can install the [Mocha](https://mochajs.org/) command-line
tool globally, and then run tests per-directory:

```bash
$ npm install -g mocha
$ cd tests/some/sub/dir
$ mocha --reporter spec --timeout 200000
```

See the [usage docs](https://mochajs.org/#usage) for further usage info.

### Writing Tests

Tests are done by comparing live parsed output to a last-known-good JSON file. The JSON files
can be easily generated using `vtt.js`, so you don't need to write these by hand
(see details below about [Grunt Run Task](#grunt-run-task)).

#### TestRunner

There's a prebuilt API in place for testing different parts of `vtt.js`. Simply
require the [TestRunner](https://github.com/videojs/vtt.js/blob/master/tests/test-runner.js)
module in the `lib` directory and start writing tests using `mocha`. See an example of a test file
[here](https://github.com/videojs/vtt.js/blob/master/tests/cue-settings/align/test.js)
with its first test's WebVTT file [here](https://github.com/videojs/vtt.js/blob/master/tests/cue-settings/align/bad-align.vtt)
and its corresponding [parsing JSON file](https://github.com/videojs/vtt.js/blob/master/tests/cue-settings/align/bad-align.json)
and [processing JSON file](https://github.com/videojs/vtt.js/blob/master/tests/cue-settings/align/bad-align-proc.json).
You can also check out the [tests](https://github.com/videojs/vtt.js/tree/master/tests)
directory for more examples on how to write tests.

#### jsonEqual(vttFile, jsonRefFile, message, onDone)

First parses the WebVTT file as UTF8 and compares it to the reference JSON file
and then parses the WebVTT file as a string and compares it to the reference JSON
file.

#### jsonEqualStreaming(vttFile, jsonRefFile, message, onDone)

Simulates parsing the file while streaming by splitting the WebVTT file into
chunks. Will simulate parsing like this `n` times for a single WebVTT file where
`n` is the length in unicode characters of the file, so use this only on small
files or else you will get a timeout failure on your test.

#### jsonEqualParsing(vttFile, jsonRefFile, message, onDone)

Runs `jsonEqual` and `jsonEqualStreaming` in one go.

#### jsonEqualProcModel(vttFile, jsonRefFile, message, onDone)

Runs the processing model over the `VTTCues` and `VTTRegions` that are returned
from parsing the WebVTT file.

#### jsonEqualAll(vttFile, jsonRefFile, message, onDone)

Runs `jsonEqualParsing` and `jsonEqualProcModel`. Note that `jsonRefFile` should
contain JSON that is generated from parsing. The processing model test will compare
its results to a JSON file located at `[vttFile]-proc.json`. Therefore, if you
have a WebVTT file named `basic.vtt` the JSON reference file for the processing
model tests will be `basic-proc.json`.

#### jsonEqualAllNoStream(vttFile, jsonRefFile, message, onDone)

Runs `jsonEqual` and `jsonEqualProcModel` use this if you want to do parsing
and processing tests, but do not want to simulate streaming because you
have too big of a WebVTT file.

## Grunt Run Task

You can automatically generate a JSON file for a given `.vtt` file using the
`run` Grunt task.

To get parsed JSON output from some WebVTT file do:

```bash
$ grunt run:my-vtt-file.vtt
$ grunt run:my-vtt-file.vtt > my-json-file.json
```

To get processed output from the WebVTT file do:

```bash
$ grunt run:my-vtt-file.vtt:p
$ grunt run:my-vtt-file.vtt:p > my-json-file.json
```

By passing the `c` flag you can automatically copy the output into a JSON file
with the same name as the WebVTT file:

```bash
$ grunt run:my-vtt-file.vtt:c
$ grunt run:my-vtt-file.vtt:pc
```

The parsed JSON output now lives in `my-vtt-file.json` and the processing JSON
output lives in `my-vtt-file-proc.json`.

You can also run it over a directory copying the output of parsing or
processing each WebVTT file to a corresponding JSON file like so:

```bash
$ grunt run:my-vtt-file-directory
$ grunt run:my-vtt-file-directory:p
```

This is useful when you've modified how `vtt.js` works and each JSON file needs
a slight change.

The `run` task utilizes a script called `cue2json`, but
does a few other things for you before each run like building a development
build for `cue2json` to use. It's also a bit easier to type in the CL options
for the task. If you want to know more about `cue2json` you can run it directly
like so:

```bash
$ ./bin/cue2json.js
$ Generate JSON test files from a reference VTT file.
$ Usage: node ./bin/cue2json.js [options]
$
$ Options:
$   -v, --vtt      Path to VTT file.
$   -d, --dir      Path to test directory. Will recursively find all JSON files with matching VTT files and rewrite them.
$   -c, --copy     Copies the VTT file to a JSON file with the same name.
$   -p, --process  Generate a JSON file of the output returned from the processing model.
```

**Notes:**

* `cue2json` utilizes the last development build done. This is why the Grunt `run` task is
good as you don't have to remember to build it yourself. If you don't build it yourself then you could
potentially get incorrect results from it.
* Since `cue2json` uses the actual parser to generate these JSON files there is the possibility that
the generated JSON will contain bugs. Therefore, always check the generated JSON files to check that the
parser actually parsed according to spec.
