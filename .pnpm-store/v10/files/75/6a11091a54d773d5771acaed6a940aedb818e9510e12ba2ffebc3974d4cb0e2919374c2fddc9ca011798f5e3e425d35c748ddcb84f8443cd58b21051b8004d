<h1 align="center">
    <p></p>
    <img src="https://cdn.jsdelivr.net/gh/nextapps-de/flexsearch@master/doc/flexsearch-logo-glass.svg?v2" alt="FlexSearch.js: Next-Generation full text search library for Browser and Node.js">
    <p></p>
</h1>
<h3>Web's fastest and most memory-flexible full-text search library with zero dependencies.</h3>

<a target="_blank" href="https://www.npmjs.com/package/flexsearch"><img src="https://img.shields.io/npm/v/flexsearch.svg"></a>
<a target="_blank" href="https://github.com/nextapps-de/flexsearch/blob/master/LICENSE.md"><img src="https://img.shields.io/npm/l/flexsearch.svg"></a>
<!--<a target="_blank" href="https://travis-ci.org/nextapps-de/flexsearch"><img src="https://travis-ci.org/nextapps-de/flexsearch.svg?branch=master"></a>-->
<!--<a target="_blank" href="https://coveralls.io/github/nextapps-de/flexsearch?branch=master"><img src="https://coveralls.io/repos/github/nextapps-de/flexsearch/badge.svg?branch=master&v=0"></a>-->

<a href="#installation">Basic Start</a> &ensp;&bull;&ensp; <a href="#api">API Reference</a> &ensp;&bull;&ensp; <a href="#builds">Document Indexes</a> &ensp;&bull;&ensp; <a>Using Worker</a> &ensp;&bull;&ensp; <a href="CHANGELOG.md">Changelog</a>

### FlexSearch v0.7.0

The new version is finally available. FlexSearch v0.7.0 is a modern re-implementation and was newly developed from the ground up. The result is an improvement in every single aspect and covers tons of enhancements and improvements which was collected over the last 3 years.

This new version has a good compatibility with the old generation, but it might require some migrations steps in your code.

Read the documentation of new features and changes:<br>
<a href="https://github.com/nextapps-de/flexsearch/blob/master/doc/0.7.0.md">https://github.com/nextapps-de/flexsearch/blob/master/doc/0.7.0.md</a>

Read the documentation of new language encoding features:<br>
<a href="https://github.com/nextapps-de/flexsearch/blob/master/doc/0.7.0-lang.md">https://github.com/nextapps-de/flexsearch/blob/master/doc/0.7.0-lang.md</a>

<h1></h1>

When it comes to raw search speed <a href="https://nextapps-de.github.io/flexsearch/bench/" target="_blank">FlexSearch outperforms every single searching library out there</a> and also provides flexible search capabilities like multi-field search, phonetic transformations or partial matching. 

Depending on the used <a href="#options">options</a> it also provides the <a href="#memory">most memory-efficient index</a>. FlexSearch introduce a new scoring algorithm called <a href="#contextual">"contextual index"</a> based on a <a href="#dictionary">pre-scored lexical dictionary</a> architecture which actually performs queries up to 1,000,000 times faster compared to other libraries.
FlexSearch also provides you a non-blocking asynchronous processing model as well as web workers to perform any updates or queries on the index in parallel through dedicated balanced threads.

<!--
FlexSearch Server is available here: 
<a target="_blank" href="https://github.com/nextapps-de/flexsearch-server">https://github.com/nextapps-de/flexsearch-server</a>.
-->

Supported Platforms:
- Browser
- Node.js

<!--
Demos:
- <a href="https://raw.githack.com/nextapps-de/flexsearch/master/demo/autocomplete.html" target="_blank">Auto-Complete</a>
-->

Library Comparison "Gulliver's Travels":
- <a href="https://nextapps-de.github.io/flexsearch/bench/" target="_blank">Performance Benchmark</a>
- <a href="https://nextapps-de.github.io/flexsearch/bench/match.html" target="_blank">Scoring Benchmark</a>
- <a href="#consumption">Memory Consumption</a>

Plugins (extern projects):
- https://github.com/angeloashmore/react-use-flexsearch
- https://www.gatsbyjs.org/packages/gatsby-plugin-flexsearch/

### Get Latest Stable Build (Recommended)

<table>
    <tr><td colspan="3"></td></tr>
    <tr>
        <td>Build</td>
        <td>File</td>
        <td>CDN</td>
    </tr>
    <tr>
        <td>flexsearch.bundle.js</td>
        <td><a href="https://github.com/nextapps-de/flexsearch/raw/0.7.2/dist/flexsearch.bundle.js" target="_blank">Download</a></td>
        <td><a href="https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.bundle.js" target="_blank">https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.bundle.js</a></td>
    </tr>
    <tr></tr>
    <tr>
        <td>flexsearch.light.js</td>
        <td><a href="https://github.com/nextapps-de/flexsearch/raw/0.7.2/dist/flexsearch.light.js" target="_blank">Download</a></td>
        <td><a href="https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.light.js" target="_blank">https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.light.js</a></td>
    </tr>
    <tr></tr>
    <tr>
        <td>flexsearch.compact.js</td>
        <td><a href="https://github.com/nextapps-de/flexsearch/raw/0.7.2/dist/flexsearch.compact.js" target="_blank">Download</a></td>
        <td><a href="https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.compact.js" target="_blank">https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.compact.js</a></td>
    </tr>
    <tr></tr>
    <tr>
        <td>flexsearch.es5.js *</td>
        <td><a href="https://github.com/nextapps-de/flexsearch/raw/0.7.2/dist/flexsearch.es5.js" target="_blank">Download</a></td>
        <td><a href="https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.es5.js" target="_blank">https://rawcdn.githack.com/nextapps-de/flexsearch/0.7.2/dist/flexsearch.es5.js</a></td>
    </tr>
    <tr></tr>
    <tr>
        <td>ES6 Modules</td>
        <td><a href="https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/nextapps-de/flexsearch/tree/0.7.2/dist/module/" target="_blank">Download</a></td>
        <td>The <i>/dist/module/</i> folder of this Github repository</td>
    </tr>
</table>

<span>*</span> The bundle "flexsearch.es5.js" includes polyfills for EcmaScript 5 Support.

#### Get Latest (NPM)

```cmd
npm install flexsearch
```

#### Get Latest Nightly (Do not use for production!)

Just exchange the version number from the URLs above with "master", e.g.: "/flexsearch/__0.7.2__/dist/" into "/flexsearch/__master__/dist".

### Compare Web-Bundles

> The Node.js package includes all features from `flexsearch.bundle.js`.

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Feature</td>
        <td>flexsearch.bundle.js</td>
        <td>flexsearch.compact.js</td>
        <td>flexsearch.light.js</td>
    </tr>
    <tr>
        <td>
            <a href="#presets">Presets</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#async">Async Search</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#webworker">Workers (Web + Node.js)</a>
        </td>
        <td>✓</td>
        <td>-</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#contextual">Contextual Indexes</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>✓</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#docs">Index Documents (Field-Search)</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#store">Document Store</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#tokenizer">Partial Matching</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>✓</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            Relevance Scoring
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>✓</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#cache">Auto-Balanced Cache by Popularity</a>
        </td>
        <td>✓</td>
        <td>-</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#tags">Tags</a>
        </td>
        <td>✓</td>
        <td>-</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#suggestions">Suggestions</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>
            <a href="#phonetic">Phonetic Matching</a>
        </td>
        <td>✓</td>
        <td>✓</td>
        <td>-</td>
    </tr>
    <tr></tr>
    <tr>
        <td>Customizable Charset/Language (Matcher, Encoder, Tokenizer, Stemmer, Filter, Split, RTL)</td>
        <td>✓</td>
        <td>✓</td>
        <td>✓</td>
    </tr>
    <tr></tr>
    <tr>
        <td><a href="#export">Export / Import Indexes</a></td>
        <td>✓</td>
        <td>-</td>
        <td>-</td>
    </tr>
    <tr>
        <td>File Size (gzip)</td>
        <td>6.8 kb</td>
        <td>5.3 kb</td>
        <td>2.9 kb</td>
    </tr>
</table>

<a name="compare" id="compare"></a>
## Performance Benchmark (Ranking)

Run Comparison: <a href="https://nextapps-de.github.io/flexsearch/bench/" target="_blank">Performance Benchmark "Gulliver's Travels"</a>

Operation per seconds, higher is better, except the test "Memory" on which lower is better.

<table>
    <tr><td colspan="8"></td></tr>
    <tr>
        <td>Rank</td>
        <td>Library</td>
        <td>Memory</td>
        <td>Query (Single Term)</td>
        <td>Query (Multi Term)</td>
        <td>Query (Long)</td>
        <td>Query (Dupes)</td>
        <td>Query (Not Found)</td>	
    </tr>
    <tr>
        <td>1</td>
        <td>FlexSearch</td>
        <td><b>17</b></td>
        <td><b>7084129</b></td>
        <td><b>1586856</b></td>
        <td><b>511585</b></td>
        <td><b>2017142</b></td>
        <td>3202006</td>
    </tr>
    <tr></tr>
    <tr>
        <td>2</td>
        <td>JSii</td>
        <td>27</td>
        <td>6564</td>
        <td>158149</td>
        <td>61290</td>
        <td>95098</td>
        <td>534109</td>
    </tr>
    <tr></tr>
    <tr>
        <td>3</td>
        <td>Wade</td>
        <td>424</td>
        <td>20471</td>
        <td>78780</td>
        <td>16693</td>
        <td>225824</td>
        <td>213754</td>
    </tr>
    <tr></tr>
    <tr>
        <td>4</td>
        <td>JS Search</td>
        <td>193</td>
        <td>8221</td>
        <td>64034</td>
        <td>10377</td>
        <td>95830</td>
        <td>167605</td>
    </tr>
    <tr></tr>
    <tr>
        <td>5</td>
        <td>Elasticlunr.js</td>
        <td>646</td>
        <td>5412</td>
        <td>7573</td>
        <td>2865</td>
        <td>23786</td>
        <td>13982</td>
    </tr>
    <tr></tr>
    <tr>
        <td>6</td>
        <td>BulkSearch</td>
        <td>1021</td>
        <td>3069</td>
        <td>3141</td>
        <td>3333</td>
        <td>3265</td>
        <td><b>21825569</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>7</td>
        <td>MiniSearch</td>
        <td>24348</td>
        <td>4406</td>
        <td>10945</td>
        <td>72</td>
        <td>39989</td>
        <td>17624</td>
    </tr>
    <tr></tr>
    <tr>
        <td>8</td>
        <td>bm25</td>
        <td>15719</td>
        <td>1429</td>
        <td>789</td>
        <td>366</td>
        <td>884</td>
        <td>1823</td>
    </tr>
    <tr></tr>
    <tr>
        <td>9</td>
        <td>Lunr.js</td>
        <td>2219</td>
        <td>255</td>
        <td>271</td>
        <td>272</td>
        <td>266</td>
        <td>267</td>
    </tr>
    <tr></tr>
    <tr>
        <td>10</td>
        <td>FuzzySearch</td>
        <td>157373</td>
        <td>53</td>
        <td>38</td>
        <td>15</td>
        <td>32</td>
        <td>43</td>
    </tr>
    <tr></tr>
    <tr>
        <td>11</td>
        <td>Fuse</td>
        <td>7641904</td>
        <td>6</td>
        <td>2</td>
        <td>1</td>
        <td>2</td>
        <td>3</td>
    </tr>
</table>

<a name="contextual"></a>
## Contextual Search

> __Note:__ This feature is disabled by default because of its extended memory usage. Read <a href="#contextual_enable">here</a> get more information about and how to enable.

FlexSearch introduce a new scoring mechanism called __Contextual Search__ which was invented by <a href="https://github.com/ts-thomas" target="_blank">Thomas Wilkerling</a>, the author of this library. A Contextual Search <a href="https://nextapps-de.github.io/flexsearch/bench/" target="_blank">incredibly boost up queries to a complete new level</a> but also requires some additional memory (depending on ___depth___).
The basic idea of this concept is to limit relevance by its context instead of calculating relevance through the whole distance of its corresponding document.
This way contextual search also <a href="https://nextapps-de.github.io/flexsearch/bench/match.html" target="_blank">improves the results of relevance-based queries</a> on a large amount of text data.

<p align="center">
    <img src="https://cdn.jsdelivr.net/gh/nextapps-de/flexsearch@master/doc/contextual-index.svg?v=4" width="100%">
</p>

<a name="installation"></a>
## Load Library

There are 3 types of indexes:

1. `Index` is a flat high performance index which stores id-content-pairs.
2. `Worker` / `WorkerIndex` is also a flat index which stores id-content-pairs but runs in background as a dedicated worker thread.
3. `Document` is multi-field index which can store complex JSON documents (could also exist of worker indexes).

The most of you probably need just one of them according to your scenario.

### ES6 Modules (Browser):

```js
import Index from "./index.js";
import Document from "./document.js";
import WorkerIndex from "./worker/index.js";

const index = new Index(options);
const document = new Document(options);
const worker = new WorkerIndex(options);
```

### Bundle (Browser)

```html
<html>
<head>
    <script src="js/flexsearch.bundle.js"></script>
</head>
...
```

Or via CDN:
```html
<script src="https://cdn.jsdelivr.net/gh/nextapps-de/flexsearch@0.7.2/dist/flexsearch.bundle.js"></script>
```

AMD:

```javascript
var FlexSearch = require("./flexsearch.js");
```

Load one of the builds from the folder <a href="https://github.com/nextapps-de/flexsearch/tree/0.7.2/dist">dist</a> within your html as a script and use as follows:

```js
var index = new FlexSearch.Index(options);
var document = new FlexSearch.Document(options);
var worker = new FlexSearch.Worker(options);
```

### Node.js

```npm
npm install flexsearch
```

In your code include as follows:

```js
const { Index, Document, Worker } = require("flexsearch");

const index = new Index(options);
const document = new Document(options);
const worker = new Worker(options);
```

## Basic Usage and Variants

```js
index.add(id, text);
index.search(text);
index.search(text, limit);
index.search(text, options);
index.search(text, limit, options);
index.search(options);
```

```js
document.add(doc);
document.add(id, doc);
document.search(text);
document.search(text, limit);
document.search(text, options);
document.search(text, limit, options);
document.search(options);
```

```js
worker.add(id, text);
worker.search(text);
worker.search(text, limit);
worker.search(text, options);
worker.search(text, limit, options);
worker.search(text, limit, options, callback);
worker.search(options);
```

The `worker` inherits from type `Index` and does not inherit from type `Document`. Therefore, a WorkerIndex basically works like a standard FlexSearch Index. Worker-Support in documents needs to be enabled by just passing the appropriate option during creation `{ worker: true }`.

> Every method called on a `Worker` index is treated as async. You will get back a `Promise` or you can provide a callback function as the last parameter alternatively.

<a name="api"></a>
## API Overview

Global methods:

- <a href="#flexsearch.register">FlexSearch.__registerCharset__(name, charset)</a>
- <a href="#flexsearch.language">FlexSearch.__registerLanguage__(name, language)</a>

Index methods:

- <a href="#index.add">Index.__add__(id, string)</a> *
- <a href="#index.append">Index.__append__(id, string)</a> *
- <a href="#index.update">Index.__update__(id, string)</a> *
- <a href="#index.remove">Index.__remove__(id)</a> *
- <a href="#index.search">Index.__search__(string, \<limit\>, \<options\>)</a> *
- <a href="#index.search">Index.__search__(options)</a> *
- _async_ <a href="#index.export">Index.__export__(handler)</a>
- _async_ <a href="#index.import">Index.__import__(key, data)</a>

WorkerIndex methods:

- _async_ <a href="#index.add">Index.__add__(id, string)</a>
- _async_ <a href="#index.append">Index.__append__(id, string)</a>
- _async_ <a href="#index.update">Index.__update__(id, string)</a>
- _async_ <a href="#index.remove">Index.__remove__(id)</a>
- _async_ <a href="#index.search">Index.__search__(string, \<limit\>, \<options\>)</a>
- _async_ <a href="#index.search">Index.__search__(options)</a>
- _async_ <a href="#index.export">~~Index.__export__(handler)~~</a> (WIP)
- _async_ <a href="#index.import">~~Index.__import__(key, data)~~</a> (WIP)

Document methods:

- <a href="#document.add">Document.__add__(\<id\>, document)</a> *
- <a href="#document.append">Document.__append__(\<id\>, document)</a> *
- <a href="#document.update">Document.__update__(\<id\>, document)</a> *
- <a href="#document.remove">Document.__remove__(id || document)</a> *
- <a href="#document.search">Document.__search__(string, \<limit\>, \<options\>)</a> *
- <a href="#document.search">Document.__search__(options)</a> *
- _async_ <a href="#document.export">Document.__export__(handler)</a>
- _async_ <a href="#document.import">Document.__import__(key, data)</a>

<span>*</span> For each of those methods there exist an asynchronous equivalent:

Async Version:

- _async_ <a href="#addAsync">.__addAsync__( ... , \<callback\>)</a>
- _async_ <a href="#appendAsync">.__appendAsync__( ... , \<callback\>)</a>
- _async_ <a href="#updateAsync">.__updateAsync__( ... , \<callback\>)</a>
- _async_ <a href="#removeAsync">.__removeAsync__( ... , \<callback\>)</a>
- _async_ <a href="#searchAsync">.__searchAsync__( ... , \<callback\>)</a>

Async methods will return a `Promise`, alternatively you can pass a callback function as the last parameter.

Methods `export` and also `import` are always async as well as every method you call on a Worker-based Index.

<a name="options"></a>
## Options

FlexSearch is highly customizable. Make use of the right options can really improve your results as well as memory economy and query time.

<a name="options-index"></a>
### Index Options

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>preset</td>
        <td>
            "memory"<br>
            "performance"<br>
            "match"<br>
            "score"<br>
            "default"
        </td>
        <td>
            The <a href="#presets">configuration profile</a> as a shortcut or as a base for your custom settings.<br>
        </td>
        <td>"default"</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tokenize</td>
        <td>
            "strict"<br>
            "forward"<br>
            "reverse"<br>
            "full"
        </td>
        <td>
            The <a href="#tokenizer">indexing mode (tokenizer)</a>.<br><br>Choose one of the <a href="#tokenizer">built-ins</a> or pass a <a href="#flexsearch.tokenizer">custom tokenizer function</a>.<br>
        </td>
        <td>"strict"</td>
    </tr>
    <tr></tr>
    <tr>
        <td>cache</td>
        <td>
            Boolean<br>
            Number
        </td>
        <td>Enable/Disable and/or set capacity of cached entries.<br><br>When passing a number as a limit the <b>cache automatically balance stored entries related to their popularity</b>.<br><br>Note: When just using "true" the cache has no limits and growth unbounded.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>resolution</td>
        <td>
            Number
        </td>
        <td>Sets the scoring resolution (default: 9).</td>
        <td>9</td>
    </tr>
    <tr></tr>
    <tr>
        <td>context</td>
        <td>
            Boolean<br>
            Context Options
        </td>
        <td>Enable/Disable <a href="#contextual">contextual indexing</a>. When passing "true" as value it will take the default values for the context.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>optimize</td>
        <td>
            Boolean
        </td>
        <td>When enabled it uses a memory-optimized stack flow for the index.</td>
        <td>true</td>
    </tr>
    <tr></tr>
    <tr>
        <td>boost</td>
        <td>
            function(arr, str, int) => float
        </td>
        <td>A custom boost function used when indexing contents to the index. The function has this signature: <code>Function(words[], term, index) => Float</code>. It has 3 parameters where you get an array of all words, the current term and the current index where the term is placed in the word array. You can apply your own calculation e.g. the occurrences of a term and return this factor (<1 means relevance is lowered, >1 means relevance is increased).<br><br>Note: this feature is currently limited by using the tokenizer "strict" only.</td>
        <td>null</td>
    </tr>
    <tr>
        <td colspan="4">
            Language-specific Options and Encoding:
        </td>
    </tr>
    <tr>
        <td>charset<br><br></td>
        <td>
            Charset Payload<br>
            String (key)
        </td>
        <td vertical-align="top">
            Provide a custom charset payload or pass one of the keys of built-in charsets.
        </td>
        <td>"latin"</td>
    </tr>
    <tr></tr>
    <tr>
        <td>language<br><br></td>
        <td>
            Language Payload<br>
            String (key)
        </td>
        <td vertical-align="top">
            Provide a custom language payload or pass in language shorthand flag (ISO-3166) of built-in languages.
        </td>
        <td>null</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encode<br><br><br><br><br><br><br></td>
        <td>
            false<br>
            "default"<br>
            "simple"<br>
            "balance"<br>
            "advanced"<br>
            "extra"<br>
            function(str) => [words]
        </td>
        <td>The encoding type.<br><br>Choose one of the <a href="#phonetic">built-ins</a> or pass a <a href="#flexsearch.encoder">custom encoding function</a>.</td>
        <td>"default"</td>
    </tr>
    <tr></tr>
    <tr>
        <td>stemmer<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td></td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>filter<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td></td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>matcher<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td></td>
        <td>false</td>
    </tr>
    <tr>
        <td colspan="4">
            Additional Options for Document Indexes:
        </td>
    </tr>
    <tr>
        <td>worker<br></td>
        <td>
            Boolean
        </td>
        <td>Enable/Disable and set count of running worker threads.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>document<br></td>
        <td>Document Descriptor</td>
        <td vertical-align="top">
            Includes definitions for the document index and storage.
        </td>
        <td></td>
    </tr>
</table>

<a name="options-context"></a>
### Context Options

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>resolution</td>
        <td>
            Number
        </td>
        <td>Sets the scoring resolution for the context (default: 1).</td>
        <td>1</td>
    </tr>
    <tr></tr>
    <tr>
        <td>depth<br><br></td>
        <td>
            false<br>
            Number
        </td>
        <td>Enable/Disable <a href="#contextual">contextual indexing</a> and also sets contextual distance of relevance. Depth is the maximum number of words/tokens away a term to be considered as relevant.</td>
        <td>1</td>
    </tr>
    <tr></tr>
    <tr>
        <td>bidirectional</td>
        <td>
            Boolean
        </td>
        <td>Sets the scoring resolution (default: 9).</td>
        <td>true</td>
    </tr>
</table>

<a name="options-document"></a>
### Document Options

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>id<br></td>
        <td>String</td>
        <td vertical-align="top"></td>
        <td>"id""</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tag<br><br></td>
        <td>false<br>String</td>
        <td vertical-align="top"></td>
        <td>"tag"</td>
    </tr>
    <tr></tr>
    <tr>
        <td>index<br><br><br></td>
        <td>String<br>Array&lt;String><br>Array&lt;Object></td>
        <td vertical-align="top"></td>
        <td></td>
    </tr>
    <tr></tr>
    <tr>
        <td>store<br><br><br></td>
        <td>Boolean<br>String<br>Array&lt;String></td>
        <td vertical-align="top"></td>
        <td>false</td>
    </tr>
</table>

<a name="options-charset"></a>
### Charset Options

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>split<br><br></td>
        <td>
            false<br>
            RegExp<br>
            String
        </td>
        <td vertical-align="top">
            The rule to split words when using non-custom tokenizer (<a href="#tokenizer">built-ins</a> e.g. "forward"). Use a string/char or use a regular expression (default: <code>/\W+/</code>).<br>
        </td>
        <td><code>/[\W_]+/</code></td>
    </tr>
    <tr></tr>
    <tr>
        <td>rtl<br></td>
        <td>
            Boolean
        </td>
        <td>Enables Right-To-Left encoding.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encode<br></td>
        <td>
            function(str) => [words]
        </td>
        <td>The custom encoding function.</td>
        <td>/lang/latin/default.js</td>
    </tr>
</table>

<a name="options-language"></a>
### Language Options

<table>
    <tr><td colspan="3"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
    </tr>
    <tr>
        <td>stemmer<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td>Disable or pass in language shorthand flag (ISO-3166) or a custom object.
    </tr>
    <tr></tr>
    <tr>
        <td>filter<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td>Disable or pass in language shorthand flag (ISO-3166) or a custom array.</td>
    </tr>
    <tr></tr>
    <tr>
        <td>matcher<br><br><br></td>
        <td>
            false<br>
            String<br>
            Function
        </td>
        <td>Disable or pass in language shorthand flag (ISO-3166) or a custom array.</td>
    </tr>
</table>

<a name="options-search"></a>
### Search Options

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>limit</td>
        <td>number</td>
        <td>Sets the limit of results.</td>
        <td>100</td>
    </tr>
    <tr></tr>
    <tr>
        <td>offset</td>
        <td>number</td>
        <td>Apply offset (skip items).</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>suggest</td>
        <td>Boolean</td>
        <td>Enables <a href="#suggestions">suggestions</a> in results.</td>
        <td>false</td>
    </tr>
</table>

<a name="options-field-search"></a>
### Document Search Options

* Additionally, to the Index search options above.

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Values</td>
        <td>Description</td>
        <td>Default</td>
    </tr>
    <tr>
        <td>index</td>
        <td>String<br>Array&lt;String&gt;<br>Array&lt;Object&gt;</td>
        <td>Sets the <a href="#docs">document fields</a> which should be searched. When no field is set, all fields will be searched. <a href="#options-field-search">Custom options per field</a> are also supported.</td>
        <td></td>
    </tr>
    <tr></tr>
    <tr>
        <td>tag</td>
        <td>String<br>Array&lt;String></td>
        <td>Sets the <a href="#docs">document fields</a> which should be searched. When no field is set, all fields will be searched. <a href="#options-field-search">Custom options per field</a> are also supported.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>enrich</td>
        <td>Boolean</td>
        <td>Enrich IDs from the results with the corresponding documents.</td>
        <td>false</td>
    </tr>
    <tr></tr>
    <tr>
        <td>bool</td>
        <td>"and"<br>"or"</td>
        <td>Sets the used <a href="#operators">logical operator</a> when searching through multiple fields or tags.</td>
        <td>"or"</td>
    </tr>
</table>

<a name="tokenizer"></a>
## Tokenizer (Prefix Search)

Tokenizer affects the required memory also as query time and flexibility of partial matches. Try to choose the most upper of these tokenizer which fits your needs:

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Description</td>
        <td>Example</td>
        <td>Memory Factor (n = length of word)</td>
    </tr>
    <tr>
        <td><b>"strict"</b></td>
        <td>index whole words</td>
        <td><code>foobar</code></td>
        <td>* 1</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"forward"</b></td>
        <td>incrementally index words in forward direction</td>
        <td><code>fo</code>obar<br><code>foob</code>ar<br></td>
        <td>* n</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"reverse"</b></td>
        <td>incrementally index words in both directions</td>
        <td>foob<code>ar</code><br>fo<code>obar</code></td>
        <td>* 2n - 1</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"full"</b></td>
        <td>index every possible combination</td>
        <td>fo<code>oba</code>r<br>f<code>oob</code>ar</td>
        <td>* n * (n - 1)</td>
    </tr>
</table>

<a name="phonetic"></a>
## Encoders

Encoding affects the required memory also as query time and phonetic matches. Try to choose the most upper of these encoders which fits your needs, or pass in a <a href="#flexsearch.encoder">custom encoder</a>:

<table>
    <tr><td colspan="4"></td></tr>
    <tr>
        <td>Option</td>
        <td>Description</td>
        <td>False-Positives</td>
        <td>Compression</td>
    </tr>
    <tr>
        <td><b>false</b></td>
        <td>Turn off encoding</td>
        <td>no</td>
        <td>0%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"default"</b></td>
        <td>Case in-sensitive encoding</td>
        <td>no</td>
        <td>0%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"simple"</b></td>
        <td>Case in-sensitive encoding<br>Charset normalizations</td>
        <td>no</td>
        <td>~ 3%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"balance"</b></td>
        <td>Case in-sensitive encoding<br>Charset normalizations<br>Literal transformations</td>
        <td>no</td>
        <td>~ 30%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"advanced"</b></td>
        <td>Case in-sensitive encoding<br>Charset normalizations<br>Literal transformations<br>Phonetic normalizations</td>
        <td>no</td>
        <td>~ 40%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>"extra"</b></td>
        <td>Case in-sensitive encoding<br>Charset normalizations<br>Literal transformations<br>Phonetic normalizations<br>Soundex transformations</td>
        <td>yes</td>
        <td>~ 65%</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>function()</b></td>
        <td>Pass custom encoding via <i>function(string):[words]</i></td>
        <td></td>
        <td></td>
    </tr>
</table>

## Usage

<a name="flexsearch.create"></a>
#### Create a new index

```js
var index = new Index();
```

Create a new index and choosing one of the presets:

```js
var index = new Index("performance");
```

Create a new index with custom options:

```js
var index = new Index({
    charset: "latin:extra",
    tokenize: "reverse",
    resolution: 9
});
```

Create a new index and extend a preset with custom options:

```js
var index = new FlexSearch({
    preset: "memory",
    tokenize: "forward",
    resolution: 5
});
```

<a href="#options">See all available custom options.</a>

<a name="index.add"></a>
#### Add text item to an index

Every content which should be added to the index needs an ID. When your content has no ID, then you need to create one by passing an index or count or something else as an ID (a value from type `number` is highly recommended). Those IDs are unique references to a given content. This is important when you update or adding over content through existing IDs. When referencing is not a concern, you can simply use something simple like `count++`.

> Index.__add(id, string)__

```js
index.add(0, "John Doe");
```

<a name="index.search"></a>
#### Search items

> Index.__search(string | options, \<limit\>, \<options\>)__

```js
index.search("John");
```

Limit the result:

```js
index.search("John", 10);
```

#### Check existence of already indexed IDs

You can check if an ID was already indexed by:

```js
if(index.contain(1)){
    console.log("ID is already in index");
}
```

<a name="async_search"></a>
## Async

You can call each method in its async version, e.g. `index.addAsync` or `index.searchAsync`.

You can assign callbacks to each async function:

```js
index.addAsync(id, content, function(){
    console.log("Task Done");
});

index.searchAsync(query, function(result){
    console.log("Results: ", result);
});
```

Or do not pass a callback function and getting back a `Promise` instead:

```js
index.addAsync(id, content).then(function(){
    console.log("Task Done");
});

index.searchAsync(query).then(function(result){
    console.log("Results: ", result);
});
```

Or use `async` and `await`:

```js
async function add(){
    await index.addAsync(id, content);
    console.log("Task Done");
}

async function search(){
    const results = await index.searchAsync(query);
    console.log("Results: ", result);
}
```

## Append Contents

You can append contents to an existing index like:

```js
index.append(id, content);
```

This will not overwrite the old indexed contents as it will do when perform `index.update(id, content)`. Keep in mind that `index.add(id, content)` will also perform "update" under the hood when the id was already being indexed.

Appended contents will have their own context and also their own full `resolution`. Therefore, the relevance isn't being stacked but gets its own context.

Let us take this example:

```js
index.add(0, "some index");
index.append(0, "some appended content");

index.add(1, "some text");
index.append(1, "index appended content");
```

When you query `index.search("index")` then you will get index id 1 as the first entry in the result, because the context starts from zero for the appended data (isn't stacked to the old context) and here "index" is the first term.

If you didn't want this behavior than just use the standard `index.add(id, content)` and provide the full length of content.

<a name="index.update"></a>
#### Update item from an index

> Index.__update(id, string)__

```js
index.update(0, "Max Miller");
```

<a name="index.remove"></a>
#### Remove item from an index

> Index.__remove(id)__

```js
index.remove(0);
```

<a name="flexsearch.tokenizer"></a>
#### Add custom tokenizer

> A tokenizer split words/terms into components or partials.

Define a private custom tokenizer during creation/initialization:
```js
var index = new FlexSearch({

    tokenize: function(str){

        return str.split(/\s-\//g);
    }
});
```

> The tokenizer function gets a string as a parameter and has to return an array of strings representing a word or term. In some languages every char is a term and also not separated via whitespaces.

<a name="flexsearch.language"></a>
#### Add language-specific stemmer and/or filter

> __Stemmer:__ several linguistic mutations of the same word (e.g. "run" and "running")

> __Filter:__ a blacklist of words to be filtered out from indexing at all (e.g. "and", "to" or "be")

Assign a private custom stemmer or filter during creation/initialization:
```js
var index = new FlexSearch({

    stemmer: {

        // object {key: replacement}
        "ational": "ate",
        "tional": "tion",
        "enci": "ence",
        "ing": ""
    },
    filter: [

        // array blacklist
        "in",
        "into",
        "is",
        "isn't",
        "it",
        "it's"
    ]
});
```

Using a custom filter, e.g.:
```js
var index = new FlexSearch({

    filter: function(value){

        // just add values with length > 1 to the index

        return value.length > 1;
    }
});
```

Or assign stemmer/filters globally to a language:

> Stemmer are passed as a object (key-value-pair), filter as an array.

```js
FlexSearch.registerLanguage("us", {

    stemmer: { /* ... */ },
    filter:  [ /* ... */ ]
});
```

Or use some pre-defined stemmer or filter of your preferred languages:
```html
<html>
<head>
    <script src="js/flexsearch.bundle.js"></script>
    <script src="js/lang/en.min.js"></script>
    <script src="js/lang/de.min.js"></script>
</head>
...
```

Now you can assign built-in stemmer during creation/initialization:
```js
var index_en = new FlexSearch.Index({
    language: "en"
});

var index_de = new FlexSearch.Index({
    language: "de"
});
```

In Node.js all built-in language packs files are available:

```js
const { Index } = require("flexsearch");

var index_en = new Index({
    language: "en"
});
```

<a name="rtl"></a>
### Right-To-Left Support

> Set the tokenizer at least to "reverse" or "full" when using RTL.

Just set the field "rtl" to _true_ and use a compatible tokenizer:

```js
var index = new Index({
    encode: str => str.toLowerCase().split(/[^a-z]+/),
    tokenize: "reverse",
    rtl: true
});
```

<a name="cjk"></a>
### CJK Word Break (Chinese, Japanese, Korean)

Set a custom tokenizer which fits your needs, e.g.:

```js
var index = FlexSearch.create({
    encode: str => str.replace(/[\x00-\x7F]/g, "").split("")
});
```

You can also pass a custom encoder function to apply some linguistic transformations.

```js
index.add(0, "一个单词");
```

```js
var results = index.search("单词");
```

<a name="docs"></a>
## Index Documents (Field-Search)

### The Document Descriptor

Assuming our document has a data structure like this:

```json
{ 
    "id": 0, 
    "content": "some text"
}
```

Old syntax FlexSearch v0.6.3 (___not supported anymore!___):

```js
const index = new Document({
    doc: {
        id: "id",
        field: ["content"]
    }
});
```

> The document descriptor has slightly changed, there is no `field` branch anymore, instead just apply one level higher, so `key` becomes a main member of options.

For the new syntax the field "doc" was renamed to `document` and the field "field" was renamed to `index`:

```js
const index = new Document({
    document: {
        id: "id",
        index: ["content"]
    }
});

index.add({ 
    id: 0, 
    content: "some text"
});
```

The field `id` describes where the ID or unique key lives inside your documents. The default key gets the value `id` by default when not passed, so you can shorten the example from above to:

```js
const index = new Document({
    document: {
        index: ["content"]
    }
});
```

The member `index` has a list of fields which you want to be indexed from your documents. When just selecting one field, then you can pass a string. When also using default key `id` then this shortens to just:

```js
const index = new Document({ document: "content" });
index.add({ id: 0, content: "some text" });
```

Assuming you have several fields, you can add multiple fields to the index:

```js
var docs = [{
    id: 0,
    title: "Title A",
    content: "Body A"
},{
    id: 1,
    title: "Title B",
    content: "Body B"
}];
```

```js
const index = new Document({
    id: "id",
    index: ["title", "content"]
});
```

You can pass custom options for each field:

```js
const index = new Document({
    id: "id",
    index: [{
        field: "title",
        tokenize: "forward",
        optimize: true,
        resolution: 9
    },{
        field:  "content",
        tokenize: "strict",
        optimize: true,
        resolution: 5,
        minlength: 3,
        context: {
            depth: 1,
            resolution: 3
        }
    }]
});
```

Field options gets inherited when also global options was passed, e.g.:

```js
const index = new Document({
    tokenize: "strict",
    optimize: true,
    resolution: 9,
    document: {
        id: "id",
        index:[{
            field: "title",
            tokenize: "forward"
        },{
            field: "content",
            minlength: 3,
            context: {
                depth: 1,
                resolution: 3
            }
        }]
    }
});
```

Note: The context options from the field "content" also gets inherited by the corresponding field options, whereas this field options was inherited by the global option.

### Nested Data Fields (Complex Objects)

Assume the document array looks more complex (has nested branches etc.), e.g.:

```json
{
  "record": {
    "id": 0,
    "title": "some title",
    "content": {
      "header": "some text",
      "footer": "some text"
    }
  }
}
```

Then use the colon separated notation ___"root:child:child"___ to define hierarchy within the document descriptor:

```js
const index = new Document({
    document: {
        id: "record:id",
        index: [
            "record:title",
            "record:content:header",
            "record:content:footer"
        ]
    }
});
```
> Just add fields you want to query against. Do not add fields to the index, you just need in the result (but did not query against). For this purpose you can store documents independently of its index (read below).

When you want to query through a field you have to pass the exact key of the field you have defined in the `doc` as a field name (with colon syntax):

```js
index.search(query, {
    index: [
        "record:title",
        "record:content:header",
        "record:content:footer"
    ]
});
```

Same as:

```js
index.search(query, [
    "record:title",
    "record:content:header",
    "record:content:footer"
]);
```

Using field-specific options:

```js
index.search([{
    field: "record:title",
    query: "some query",
    limit: 100,
    suggest: true
},{
    field: "record:title",
    query: "some other query",
    limit: 100,
    suggest: true
}]);
```

You can perform a search through the same field with different queries.

> When passing field-specific options you need to provide the full configuration for each field. They get not inherited like the document descriptor.

### Complex Documents

You need to follow 2 rules for your documents:

1. The document cannot start with an Array at the root index. This will introduce sequential data and isn't supported yet. See below for a workaround for such data.

```js
[ // <-- not allowed as document start!
  {
    "id": 0,
    "title": "title"
  }
]
```

2. The id can't be nested inside an array (also none of the parent fields can't be an array). This will introduce sequential data and isn't supported yet. See below for a workaround for such data.

```js
{
  "records": [ // <-- not allowed when ID or tag lives inside!
    {
      "id": 0,
      "title": "title"
    }
  ]
}
```

Here an example for a supported complex document:

```json
{
  "meta": {
    "tag": "cat",
    "id": 0
  },
  "contents": [
    {
      "body": {
        "title": "some title",
        "footer": "some text"
      },
      "keywords": ["some", "key", "words"]
    },
    {
      "body": {
        "title": "some title",
        "footer": "some text"
      },
      "keywords": ["some", "key", "words"]
    }
  ]
}
```

The corresponding document descriptor (when all fields should be indexed) looks like:

```js
const index = new Document({
    document: {
        id: "meta:id",
        tag: "meta:tag",
        index: [
            "contents[]:body:title",
            "contents[]:body:footer",
            "contents[]:keywords"
        ]
    }
});
```

Again, when searching you have to use the same colon-separated-string from your field definition.

```js
index.search(query, { 
    index: "contents[]:body:title"
});
```

### Not Supported Documents (Sequential Data)

This example breaks both rules from above:

```js
[ // <-- not allowed as document start!
  {
    "tag": "cat",
    "records": [ // <-- not allowed when ID or tag lives inside!
      {
        "id": 0,
        "body": {
          "title": "some title",
          "footer": "some text"
        },
        "keywords": ["some", "key", "words"]
      },
      {
        "id": 1,
        "body": {
          "title": "some title",
          "footer": "some text"
        },
        "keywords": ["some", "key", "words"]
      }
    ]
  }
]
```

You need to apply some kind of structure normalization.

A workaround to such a data structure looks like this:

```js
const index = new Document({
    document: {
        id: "record:id",
        tag: "tag",
        index: [
            "record:body:title",
            "record:body:footer",
            "record:body:keywords"
        ]
    }
});

function add(sequential_data){

    for(let x = 0, data; x < sequential_data.length; x++){

        data = sequential_data[x];

        for(let y = 0, record; y < data.records.length; y++){

            record = data.records[y];

            index.add({
                id: record.id,
                tag: data.tag,
                record: record
            });
        }
    }  
}

// now just use add() helper method as usual:

add([{
    // sequential structured data
    // take the data example above
}]);
```

You can skip the first loop when your document data has just one index as the outer array.

### Add/Update/Remove Documents to/from the Index

Just pass the document array (or a single object) to the index:

```js
index.add(docs);
```

Update index with a single object or an array of objects:

```js
index.update({
    data:{
        id: 0,
        title: "Foo",
        body: {
            content: "Bar"
        }
    }
});
```

Remove a single object or an array of objects from the index:

```js
index.remove(docs);
```

When the id is known, you can also simply remove by (faster):

```js
index.remove(id);
```

### Join / Append Arrays

On the complex example above, the field `keywords` is an array but here the markup did not have brackets like `keywords[]`. That will also detect the array but instead of appending each entry to a new context, the array will be joined into on large string and added to the index.

The difference of both kinds of adding array contents is the relevance when searching. When adding each item of an array via `append()` to its own context by using the syntax `field[]`, then the relevance of the last entry concurrent with the first entry. When you left the brackets in the notation, it will join the array to one whitespace-separated string. Here the first entry has the highest relevance, whereas the last entry has the lowest relevance.

So assuming the keyword from the example above are pre-sorted by relevance to its popularity, then you want to keep this order (information of relevance). For this purpose do not add brackets to the notation. Otherwise, it would take the entries in a new scoring context (the old order is getting lost).

Also you can left bracket notation for better performance and smaller memory footprint. Use it when you did not need the granularity of relevance by the entries.

### Field-Search

Search through all fields:

```js
index.search(query);
```

Search through a specific field:

```js
index.search(query, { index: "title" });
```

Search through a given set of fields:

```js
index.search(query, { index: ["title", "content"] });
```

Same as:

```js
index.search(query, ["title", "content"]);
```

Pass custom modifiers and queries to each field:

```js
index.search([{
    field: "content",
    query: "some query",
    limit: 100,
    suggest: true
},{
    field: "content",
    query: "some other query",
    limit: 100,
    suggest: true
}]);
```

You can perform a search through the same field with different queries.

<a href="#options-field-search">See all available field-search options.</a>

### The Result Set

Schema of the result-set:

> `fields[] => { field, result[] => { document }}`

The first index is an array of fields the query was applied to. Each of this field has a record (object) with 2 properties "field" and "result". The "result" is also an array and includes the result for this specific field. The result could be an array of IDs or as enriched with stored document data.

A non-enriched result set now looks like:

```js
[{
    field: "title",
    result: [0, 1, 2]
},{
    field: "content",
    result: [3, 4, 5]
}]
```

An enriched result set now looks like:

```js
[{
    field: "title",
    result: [
        { id: 0, doc: { /* document */ }},
        { id: 1, doc: { /* document */ }},
        { id: 2, doc: { /* document */ }}
    ]
},{
    field: "content",
    result: [
        { id: 3, doc: { /* document */ }},
        { id: 4, doc: { /* document */ }},
        { id: 5, doc: { /* document */ }}
    ]
}]
```

When using `pluck` instead of "field" you can explicitly select just one field and get back a flat representation:

```js
index.search(query, { pluck: "title", enrich: true });
```

```js
[
    { id: 0, doc: { /* document */ }},
    { id: 1, doc: { /* document */ }},
    { id: 2, doc: { /* document */ }}
]
```

This result set is a replacement of "boolean search". Instead of applying your bool logic to a nested object, you can apply your logic by yourself on top of the result-set dynamically. This opens hugely capabilities on how you process the results. Therefore, the results from the fields aren't squashed into one result anymore. That keeps some important information, like the name of the field as well as the relevance of each field results which didn't get mixed anymore.

> A field search will apply a query with the boolean "or" logic by default. Each field has its own result to the given query.

There is one situation where the `bool` property is being still supported. When you like to switch the default "or" logic from the field search into "and", e.g.:

```js
index.search(query, { 
    index: ["title", "content"],
    bool: "and" 
});
```

You will just get results which contains the query in both fields. That's it.

### Tags

Like the `key` for the ID just define the path to the tag:

```js
const index = new Document({
    document: { 
        id: "id",
        tag: "tag",
        index: "content"
    }
});
```

```js
index.add({
    id: 0,
    tag: "cat",
    content: "Some content ..."
});
```

Your data also can have multiple tags as an array:

```js
index.add({
    id: 1,
    tag: ["animal", "dog"],
    content: "Some content ..."
});
```

You can perform a tag-specific search by:

```js
index.search(query, { 
    index: "content",
    tag: "animal" 
});
```

This just gives you result which was tagged with the given tag.

Use multiple tags when searching:

```js
index.search(query, { 
    index: "content",
    tag: ["cat", "dog"]
});
```

This gives you result which are tagged with one of the given tag.

> Multiple tags will apply as the boolean "or" by default. It just needs one of the tags to be existing.

This is another situation where the `bool` property is still supported. When you like to switch the default "or" logic from the tag search into "and", e.g.:

```js
index.search(query, { 
    index: "content",
    tag: ["dog", "animal"],
    bool: "and"
});
```

You will just get results which contains both tags (in this example there is just one records which has the tag "dog" and "animal").

### Tag Search

You can also fetch results from one or more tags when no query was passed:

```js
index.search({ tag: ["cat", "dog"] });
```

In this case the result-set looks like:

```js
[{
    tag: "cat",
    result: [ /* all cats */ ]
},{
    tag: "dog",
    result: [ /* all dogs */ ]
}]
```

### Limit & Offset

> By default, every query is limited to 100 entries. Unbounded queries leads into issues. You need to set the limit as an option to adjust the size.

You can set the limit and the offset for each query:

```js
index.search(query, { limit: 20, offset: 100 });
```

> You cannot pre-count the size of the result-set. That's a limit by the design of FlexSearch. When you really need a count of all results you are able to page through, then just assign a high enough limit and get back all results and apply your paging offset manually (this works also on server-side). FlexSearch is fast enough that this isn't an issue.

## Document Store

Only a document index can have a store. You can use a document index instead of a flat index to get this functionality also when only storing ID-content-pairs.

You can define independently which fields should be indexed and which fields should be stored. This way you can index fields which should not be included in the search result.

> Do not use a store when: 1. an array of IDs as the result is good enough, or 2. you already have the contents/documents stored elsewhere (outside the index).

> When the `store` attribute was set, you have to include all fields which should be stored explicitly (acts like a whitelist).

> When the `store` attribute was not set, the original document is stored as a fallback.

This will add the whole original content to the store:

```js
const index = new Document({
    document: { 
        index: "content",
        store: true
    }
});

index.add({ id: 0, content: "some text" });
```

### Access documents from internal store

You can get indexed documents from the store:

```js
var data = index.get(1);
```

You can update/change store contents directly without changing the index by:

```js
index.set(1, data);
```

To update the store and also update the index then just use `index.update`, `index.add` or `index.append`.

When you perform a query, weather it is a document index or a flat index, then you will always get back an array of IDs.

Optionally you can enrich the query results automatically with stored contents by:

```js
index.search(query, { enrich: true });
```

Your results look now like:

```js
[{
    id: 0,
    doc: { /* content from store */ }
},{
    id: 1,
    doc: { /* content from store */ }
}]
```

### Configure Storage (Recommended)

This will add just specific fields from a document to the store (the ID isn't necessary to keep in store):

```js
const index = new Document({
    document: {
        index: "content",
        store: ["author", "email"]
    }
});

index.add(id, content);
```

You can configure independently what should being indexed and what should being stored. It is highly recommended to make use of this whenever you can.

Here a useful example of configuring doc and store:

```js
const index = new Document({
    document: { 
        index: "content",
        store: ["author", "email"] 
    }
});

index.add({
    id: 0,
    author: "Jon Doe",
    email: "john@mail.com",
    content: "Some content for the index ..."
});
```

You can query through the contents and will get back the stored values instead:

```js
index.search("some content", { enrich: true });
```

Your results are now looking like:

```js
[{
    field: "content",
    result: [{
        id: 0,
        doc: {
            author: "Jon Doe",
            email: "john@mail.com",
        }
    }]
}]
```

Both field "author" and "email" are not indexed.

<a name="chaining"></a>
### Chaining

Simply chain methods like:

```js
var index = FlexSearch.create()
                      .addMatcher({'â': 'a'})
                      .add(0, 'foo')
                      .add(1, 'bar');
```

```js
index.remove(0).update(1, 'foo').add(2, 'foobar');
```

<a name="contextual_enable"></a>
## Enable Contextual Scoring

Create an index and use the default context:
```js
var index = new FlexSearch({

    tokenize: "strict",
    context: true
});
```

Create an index and apply custom options for the context:
```js
var index = new FlexSearch({

    tokenize: "strict",
    context: { 
        resolution: 5,
        depth: 3,
        bidirectional: true
    }
});
```

> Only the tokenizer "strict" is actually supported by the contextual index.

> The contextual index requires <a href="#memory">additional amount of memory</a> depending on depth.

<a name="cache"></a>
### Auto-Balanced Cache (By Popularity)

You need to initialize the cache and its limit during the creation of the index:

```js
const index = new Index({ cache: 100 });
```

```js
const results = index.searchCache(query);
```

A common scenario for using a cache is an autocomplete or instant search when typing.

> When passing a number as a limit the cache automatically balance stored entries related to their popularity.

> When just using "true" the cache is unbounded and perform actually 2-3 times faster (because the balancer do not have to run).

<a name="webworker"></a>
## Worker Parallelism (Browser + Node.js)

The new worker model from v0.7.0 is divided into "fields" from the document (1 worker = 1 field index). This way the worker becomes able to solve tasks (subtasks) completely. The downside of this paradigm is they might not have been perfect balanced in storing contents (fields may have different length of contents). On the other hand there is no indication that balancing the storage gives any advantage (they all require the same amount in total).

When using a document index, then just apply the option "worker":
```js
const index = new Document({
    index: ["tag", "name", "title", "text"],
    worker: true
});

index.add({ 
    id: 1, tag: "cat", name: "Tom", title: "some", text: "some" 
}).add({
    id: 2, tag: "dog", name: "Ben", title: "title", text: "content" 
}).add({ 
    id: 3, tag: "cat", name: "Max", title: "to", text: "to" 
}).add({ 
    id: 4, tag: "dog", name: "Tim", title: "index", text: "index" 
});
```

```
Worker 1: { 1: "cat", 2: "dog", 3: "cat", 4: "dog" }
Worker 2: { 1: "Tom", 2: "Ben", 3: "Max", 4: "Tim" }
Worker 3: { 1: "some", 2: "title", 3: "to", 4: "index" }
Worker 4: { 1: "some", 2: "content", 3: "to", 4: "index" }
```

When you perform a field search through all fields then this task is being balanced perfectly through all workers, which can solve their subtasks independently.

### Worker Index

Above we have seen that documents will create worker automatically for each field. You can also create a WorkerIndex directly (same like using `Index` instead of `Document`).

Use as ES6 module:

```js
import WorkerIndex from "./worker/index.js";
const index = new WorkerIndex(options);
index.add(1, "some")
     .add(2, "content")
     .add(3, "to")
     .add(4, "index");
```

Or when bundled version was used instead:

```js
var index = new FlexSearch.Worker(options);
index.add(1, "some")
     .add(2, "content")
     .add(3, "to")
     .add(4, "index");
```

Such a WorkerIndex works pretty much the same as a created instance of `Index`.

> A WorkerIndex only support the `async` variant of all methods. That means when you call `index.search()` on a WorkerIndex this will perform also in async the same way as `index.searchAsync()` will do.

### Worker Threads (Node.js)

The worker model for Node.js is based on "worker threads" and works exactly the same way:

```js
const { Document } = require("flexsearch");

const index = new Document({
    index: ["tag", "name", "title", "text"],
    worker: true
});
```

Or create a single worker instance for a non-document index:

```js
const { Worker } = require("flexsearch");
const index = new Worker({ options });
```

### The Worker Async Model (Best Practices)

A worker will always perform as async. On a query method call you always should handle the returned promise (e.g. use `await`) or pass a callback function as the last parameter.

```js
const index = new Document({
    index: ["tag", "name", "title", "text"],
    worker: true
});
```

All requests and sub-tasks will run in parallel (prioritize "all tasks completed"):

```js
index.searchAsync(query, callback);
index.searchAsync(query, callback);
index.searchAsync(query, callback);
```

Also (prioritize "all tasks completed"):

```js
index.searchAsync(query).then(callback);
index.searchAsync(query).then(callback);
index.searchAsync(query).then(callback);
```

Or when you have just one callback when all requests are done, simply use `Promise.all()` which also prioritize "all tasks completed":

```js
Promise.all([
    index.searchAsync(query),
    index.searchAsync(query),
    index.searchAsync(query)
]).then(callback);
```

Inside the callback of `Promise.all()` you will also get an array of results as the first parameter respectively for each query you put into.

When using `await` you can prioritize the order (prioritize "first task completed") and solve requests one by one and just process the sub-tasks in parallel:

```js
await index.searchAsync(query);
await index.searchAsync(query);
await index.searchAsync(query);
```

Same for `index.add()`, `index.append()`, `index.remove()` or `index.update()`. Here there is a special case which isn't disabled by the library, but you need to keep in mind when using Workers.

When you call the "synced" version on a worker index:

```js
index.add(doc);
index.add(doc);
index.add(doc);
// contents aren't indexed yet,
// they just queued on the message channel 
```

Of course, you can do that but keep in mind that the main thread does not have an additional queue for distributed worker tasks. Running these in a long loop fires content massively to the message channel via `worker.postMessage()` internally. Luckily the browser and Node.js will handle such incoming tasks for you automatically (as long enough free RAM is available). When using the "synced" version on a worker index, the content isn't indexed one line below, because all calls are treated as async by default.

> When adding/updating/removing large bulks of content to the index (or high frequency), it is recommended to use the async version along with `async/await` to keep a low memory footprint during long processes.

<a name="export"></a>
## Export / Import

### Export

The export has slightly changed. The export now consist of several smaller parts, instead of just one large bulk. You need to pass a callback function which has 2 arguments "key" and "data". This callback function is called by each part, e.g.:

```js
index.export(function(key, data){ 
    
    // you need to store both the key and the data!
    // e.g. use the key for the filename and save your data
    
    localStorage.setItem(key, data);
});
```

Exporting data to the localStorage isn't really a good practice, but if size is not a concern than use it if you like. The export primarily exists for the usage in Node.js or to store indexes you want to delegate from a server to the client.

> The size of the export corresponds to the memory consumption of the library. To reduce export size you have to use a configuration which has less memory footprint (use the table at the bottom to get information about configs and its memory allocation).

When your save routine runs asynchronously you have to return a promise:

```js
index.export(function(key, data){ 
    
    return new Promise(function(resolve){
        
        // do the saving as async

        resolve();
    });
});
```

> You cannot export the additional table for the "fastupdate" feature. These table exists of references and when stored they fully get serialized and becomes too large. The lib will handle these automatically for you. When importing data, the index automatically disables "fastupdate".

### Import

Before you can import data, you need to create your index first. For document indexes provide the same document descriptor you used when export the data. This configuration isn't stored in the export.

```js
var index = new Index({ ... });
```

To import the data just pass a key and data:

```js
index.import(key, localStorage.getItem(key));
```

You need to import every key! Otherwise, your index does not work. You need to store the keys from the export and use this keys for the import (the order of the keys can differ).

This is just for demonstration and is not recommended, because you might have other keys in your localStorage which aren't supported as an import:

```js
var keys = Object.keys(localStorage);

for(let i = 0, key; i < keys.length; i++){
    
    key = keys[i];
    index.import(key, localStorage.getItem(key));
}
```

## Languages

Language-specific definitions are being divided into two groups:

1. Charset
    1. ___encode___, type: `function(string):string[]`
    2. ___rtl___, type: `boolean`
2. Language
    1. ___matcher___, type: `{string: string}`
    2. ___stemmer___, type: `{string: string}`
    3. ___filter___, type: `string[]`

The charset contains the encoding logic, the language contains stemmer, stopword filter and matchers. Multiple language definitions can use the same charset encoder. Also this separation let you manage different language definitions for special use cases (e.g. names, cities, dialects/slang, etc.).

To fully describe a custom language __on the fly__ you need to pass:

```js
const index = FlexSearch({
    // mandatory:
    encode: (content) => [words],
    // optionally:
    rtl: false,
    stemmer: {},
    matcher: {},
    filter: []
});
```

When passing no parameter it uses the `latin:default` schema by default.

<table>
    <tr></tr>
    <tr>
        <td>Field</td>
        <td>Category</td>
        <td>Description</td>
    </tr>
    <tr>
        <td><b>encode</b></td>
        <td>charset</td>
        <td>The encoder function. Has to return an array of separated words (or an empty string).</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>rtl</b></td>
        <td>charset</td>
        <td>A boolean property which indicates right-to-left encoding.</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>filter</b></td>
        <td>language</td>
        <td>Filter are also known as "stopwords", they completely filter out words from being indexed.</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>stemmer</b></td>
        <td>language</td>
        <td>Stemmer removes word endings and is a kind of "partial normalization". A word ending just matched when the word length is bigger than the matched partial.</td>
    </tr>
    <tr></tr>
    <tr>
        <td><b>matcher</b></td>
        <td>language</td>
        <td>Matcher replaces all occurrences of a given string regardless of its position and is also a kind of "partial normalization".</td>
    </tr>
</table>

### 1. Language Packs: ES6 Modules

The most simple way to assign charset/language specific encoding via modules is:

```js
import charset from "./dist/module/lang/latin/advanced.js";
import lang from "./dist/module/lang/en.js";

const index = FlexSearch({
    charset: charset,
    lang: lang
});
```

Just import the __default export__ by each module and assign them accordingly.

The full qualified example from above is:

```js
import { encode, rtl } from "./dist/module/lang/latin/advanced.js";
import { stemmer, filter, matcher } from "./dist/module/lang/en.js";

const index = FlexSearch({
    encode: encode,
    rtl: rtl,
    stemmer: stemmer,
    matcher: matcher,
    filter: filter
});
```

The example above is the standard interface which is at least exported from each charset/language.

You can also define the encoder directly and left all other options:

```js
import simple from "./dist/module/lang/latin/simple.js";

const index = FlexSearch({
    encode: simple
});
```

#### Available Latin Encoders

1. default
2. simple
3. balance
4. advanced
5. extra

You can assign a charset by passing the charset during initialization, e.g. `charset: "latin"` for the default charset encoder or `charset: "latin:soundex"` for a encoder variant.

#### Dialect / Slang

Language definitions (especially matchers) also could be used to normalize dialect and slang of a specific language.

### 2. Language Packs: ES5 (Language Packs)

You need to make the charset and/or language definitions available by:

1. All charset definitions are included in the `flexsearch.bundle.js` build by default, but no language-specific definitions are included
2. You can load packages located in `/dist/lang/` (files refers to languages, folders are charsets)
3. You can make a custom build

When loading language packs, make sure that the library was loaded before:

```html
<script src="dist/flexsearch.light.js"></script>
<script src="dist/lang/latin/default.min.js"></script>
<script src="dist/lang/en.min.js"></script>
```

When using the full "bundle" version the built-in latin encoders are already included and you just have to load the language file:

```html
<script src="dist/flexsearch.bundle.js"></script>
<script src="dist/lang/en.min.js"></script>
```

Because you loading packs as external packages (non-ES6-modules) you have to initialize them by shortcuts:

```js
const index = FlexSearch({
    charset: "latin:soundex",
    lang: "en"
});
```

> Use the `charset:variant` notation to assign charset and its variants. When just passing the charset without a variant will automatically resolve as `charset:default`.

You can also override existing definitions, e.g.:

```js
const index = FlexSearch({
    charset: "latin",
    lang: "en",
    matcher: {}
});
```

> Passed definitions will __not__ extend default definitions, they will replace them.

When you like to extend a definition just create a new language file and put in all the logic.

#### Encoder Variants

It is pretty straight forward when using an encoder variant:

```html
<script src="dist/flexsearch.light.js"></script>
<script src="dist/lang/latin/advanced.min.js"></script>
<script src="dist/lang/latin/extra.min.js"></script>
<script src="dist/lang/en.min.js"></script>
```

When using the full "bundle" version the built-in latin encoders are already included and you just have to load the language file:

```html
<script src="dist/flexsearch.bundle.js"></script>
<script src="dist/lang/en.min.js"></script>
```

```js
const index_advanced = FlexSearch({
    charset: "latin:advanced"
});

const index_extra = FlexSearch({
    charset: "latin:extra"
});
```

### Partial Tokenizer

In FlexSearch you can't provide your own partial tokenizer, because it is a direct dependency to the core unit. The built-in tokenizer of FlexSearch splits each word into fragments by different patterns:

1. strict (supports contextual index)
2. forward
3. reverse (including forward)
4. full

### Language Processing Pipeline

This is the default pipeline provided by FlexSearch:

<p>
    <img src="https://cdn.jsdelivr.net/gh/nextapps-de/flexsearch/doc/pipeline.svg?2">
</p>

#### Custom Pipeline

At first take a look into the default pipeline in `src/common.js`. It is very simple and straight forward. The pipeline will process as some sort of inversion of control, the final encoder implementation has to handle charset and also language specific transformations. This workaround has left over from many tests.

Inject the default pipeline by e.g.:

```js
this.pipeline(

    /* string: */ str.toLowerCase(),
    /* normalize: */ false,
    /* split: */ split,
    /* collapse: */ false
);
```

Use the pipeline schema from above to understand the iteration and the difference of pre-encoding and post-encoding. Stemmer and matchers needs to be applied after charset normalization but before language transformations, filters also.

Here is a good example of extending pipelines: `src/lang/latin/extra.js` → `src/lang/latin/advanced.js` → `src/lang/latin/simple.js`.

### How to contribute?

Search for your language in `src/lang/`, if it exists you can extend or provide variants (like dialect/slang). If the language doesn't exist create a new file and check if any of the existing charsets (e.g. latin) fits to your language. When no charset exist, you need to provide a charset as a base for the language.

A new charset should provide at least:

1. `encode` A function which normalize the charset of a passed text content (remove special chars, lingual transformations, etc.) and __returns an array of separated words__. Also stemmer, matcher or stopword filter needs to be applied here. When the language has no words make sure to provide something similar, e.g. each chinese sign could also be a "word". Don't return the whole text content without split.
3. `rtl` A boolean flag which indicates right-to-left encoding

Basically the charset needs just to provide an encoder function along with an indicator for right-to-left encoding:

```js
export function encode(str){ return [str] }
export const rtl = false;
```

<a name="compare" id="compare"></a>
## Encoder Matching Comparison

> Reference String: __"Björn-Phillipp Mayer"__

<table>
    <tr><td colspan="5"></td></tr>
    <tr>
        <td>Query</td>
        <td>default</td>
        <td>simple</td>
        <td>advanced</td>
        <td>extra</td>
    </tr>
    <tr>
        <td>björn</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>björ</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>bjorn</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>bjoern</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>philipp</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>filip</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>björnphillip</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>meier</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>björn meier</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>meier fhilip</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
        <td><b>yes</b></td>
    </tr>
    <tr></tr>
    <tr>
        <td>byorn mair</td>
        <td>no</td>
        <td>no</td>
        <td>no</td>
        <td><b>yes</b></td>
    </tr>
    <tr>
        <td><i>(false positives)</i></td>
        <td><b>no</b></td>
        <td><b>no</b></td>
        <td><b>no</b></td>
        <td>yes</td>
    </tr>
</table>

<a name="memory"></a>
## Memory Allocation

The book "Gulliver's Travels Swift Jonathan 1726" was fully indexed for the examples below.

The most memory-optimized meaningful setting will allocate just 1.2 Mb for the whole book indexed! This is probably the most tiny memory footprint you will get from a search library.

```js
import { encode } from "./lang/latin/extra.js";

index = new Index({
    encode: encode,
    tokenize: "strict",
    optimize: true,
    resolution: 1,
    minlength: 3,
    fastupdate: false,
    context: false
});
```

<a name="consumption"></a>
### Memory Consumption

The book "Gulliver's Travels" (Swift Jonathan 1726) was completely indexed for this test:

<br>
<img src="https://cdn.jsdelivr.net/gh/nextapps-de/flexsearch@master/doc/memory-comparison.svg?v=2">

### Compare Impact of Memory Allocation

by default a lexical index is very small:<br>
`depth: 0, bidirectional: 0, resolution: 3, minlength: 0` => 2.1 Mb

a higher resolution will increase the memory allocation:<br>
`depth: 0, bidirectional: 0, resolution: 9, minlength: 0` => 2.9 Mb

using the contextual index will increase the memory allocation:<br>
`depth: 1, bidirectional: 0, resolution: 9, minlength: 0` => 12.5 Mb

a higher contextual depth will increase the memory allocation:<br>
`depth: 2, bidirectional: 0, resolution: 9, minlength: 0` => 21.5 Mb

a higher minlength will decrease memory allocation:<br>
`depth: 2, bidirectional: 0, resolution: 9, minlength: 3` => 19.0 Mb

using bidirectional will decrease memory allocation:<br>
`depth: 2, bidirectional: 1, resolution: 9, minlength: 3` => 17.9 Mb

enable the option "fastupdate" will increase memory allocation:<br>
`depth: 2, bidirectional: 1, resolution: 9, minlength: 3` => 6.3 Mb

### Full Comparison Table

Every search library is constantly in competition with these 4 properties:

1. Memory Allocation
2. Performance
3. Matching Capabilities
4. Relevance Order (Scoring)

FlexSearch provides you many parameters you can use to adjust the optimal balance for your specific use-case.

<table>
    <tr><td colspan="5"></td></tr>
    <tr>
        <td>Modifier</td>
        <td>Memory Impact *</td>
        <td>Performance Impact **</td>
        <td>Matching Impact **</td>
        <td>Scoring Impact **</td>
    </tr>
    <tr>
        <td>resolution</td>
        <td>+1 (per level)</td>
        <td>+1 (per level)</td>
        <td>0</td>
        <td>+2 (per level)</td>
    </tr>
    <tr></tr>
    <tr>
        <td>depth</td>
        <td>+4 (per level)</td>
        <td>-1 (per level)</td>
        <td>-10 + depth</td>
        <td>+10</td>
    </tr>
    <tr></tr>
    <tr>
        <td>minlength</td>
        <td>-2 (per level)</td>
        <td>+2 (per level)</td>
        <td>-3 (per level)</td>
        <td>+2 (per level)</td>
    </tr>
    <tr></tr>
    <tr>
        <td>bidirectional</td>
        <td>-2</td>
        <td>0</td>
        <td>+3</td>
        <td>-1</td>
    </tr>
    <tr></tr>
    <tr>
        <td>fastupdate</td>
        <td>+1</td>
        <td>+10 (update, remove)</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>optimize: true</td>
        <td>-7</td>
        <td>-1</td>
        <td>0</td>
        <td>-3</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encoder: "icase"</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encoder: "simple"</td>
        <td>-2</td>
        <td>-1</td>
        <td>+2</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encoder: "advanced"</td>
        <td>-3</td>
        <td>-2</td>
        <td>+4</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encoder: "extra"</td>
        <td>-5</td>
        <td>-5</td>
        <td>+6</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>encoder: "soundex"</td>
        <td>-6</td>
        <td>-2</td>
        <td>+8</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tokenize: "strict"</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tokenize: "forward"</td>
        <td>+3</td>
        <td>-2</td>
        <td>+5</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tokenize: "reverse"</td>
        <td>+5</td>
        <td>-4</td>
        <td>+7</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>tokenize: "full"</td>
        <td>+8</td>
        <td>-5</td>
        <td>+10</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>document index</td>
        <td>+3 (per field)</td>
        <td>-1 (per field)</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>document tags</td>
        <td>+1 (per tag)</td>
        <td>-1 (per tag)</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>store: true</td>
        <td>+5 (per document)</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>store: [fields]</td>
        <td>+1 (per field)</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>cache: true</td>
        <td>+10</td>
        <td>+10</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>cache: 100</td>
        <td>+1</td>
        <td>+9</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>type of ids: number</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
        <td>0</td>
    </tr>
    <tr></tr>
    <tr>
        <td>type of ids: string</td>
        <td>+3</td>
        <td>-3</td>
        <td>0</td>
        <td>0</td>
    </tr>
</table>
* range from -10 to 10, lower is better (-10 => big decrease, 0 => unchanged, +10 => big increase)<br>
** range from -10 to 10, higher is better

<a name="presets"></a>
## Presets

1. `memory` (primary optimize for memory)
2. `performance` (primary optimize for performance)
3. `match` (primary optimize for matching)
4. `score` (primary optimize for scoring)
5. `default` (the default balanced profile)

These profiles are covering standard use cases. It is recommended to apply custom configuration instead of using profiles to get the best out for your situation. Every profile could be optimized further to its specific task, e.g. extreme performance optimized configuration or extreme memory and so on.

You can pass a preset during creation/initialization of the index. 

<!--
Compare these presets:
- <a href="https://raw.githack.com/nextapps-de/flexsearch/master/test/matching-presets.html" target="_blank">Relevance Scoring</a><br>
- <a href="https://raw.githack.com/nextapps-de/flexsearch/master/test/benchmark-presets.html" target="_blank">Benchmarks</a>
-->

## Best Practices

##### Use numeric IDs

It is recommended to use numeric id values as reference when adding content to the index. The byte length of passed ids influences the memory consumption significantly. If this is not possible you should consider to use a index table and map the ids with indexes, this becomes important especially when using contextual indexes on a large amount of content.

##### Split Complexity

Whenever you can, try to divide content by categories and add them to its own index, e.g.:

```js
var action = new FlexSearch();
var adventure = new FlexSearch();
var comedy = new FlexSearch();
```

This way you can also provide different settings for each category. This is actually the fastest way to perform a fuzzy search.

To make this workaround more extendable you can use a short helper:

```js
var index = {};

function add(id, cat, content){
    (index[cat] || (
        index[cat] = new FlexSearch
    )).add(id, content);
}

function search(cat, query){
    return index[cat] ?
        index[cat].search(query) : [];
}
```

Add content to the index:
```js
add(1, "action", "Movie Title");
add(2, "adventure", "Movie Title");
add(3, "comedy", "Movie Title");
```

Perform queries:
```js
var results = search("action", "movie title"); // --> [1]
```

Split indexes by categories improves performance significantly.

---

Copyright 2018-2021 Nextapps GmbH<br>
Released under the <a href="http://www.apache.org/licenses/LICENSE-2.0.html" target="_blank">Apache 2.0 License</a><br>
