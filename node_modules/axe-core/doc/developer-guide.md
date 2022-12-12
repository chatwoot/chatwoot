# Axe Developer Guide

Axe runs a series of tests to check for accessibility of content and functionality on a website. A test is made up of a series of Rules which are, themselves, made up of Checks. Axe executes these Rules asynchronously and, when the Rules are finished running, runs a callback function which is passed a Result structure. Since some Rules run on the page level while others do not, tests will also run in one of two ways. If a document is specified, the page level rules will run, otherwise they will not.

Axe 3.0 supports open Shadow DOM: see our virtual DOM APIs and test utilities for developing axe-core moving forward. Note: we do not and cannot support closed Shadow DOM.

1. [Getting Started](#getting-started)
   1. [Environment Pre-requisites](#environment-pre-requisites)
   1. [Building axe.js](#building-axejs)
   1. [Running Tests](#running-tests)
   1. [API Reference](#api-reference)
   1. [Supported CSS Selectors](#supported-css-selectors)
1. [Architecture Overview](#architecture-overview)
   1. [Rules](#rules)
   1. [Checks](#checks)
   1. [Common Functions](#common-functions)
   1. [Virtual Nodes](#virtual-nodes)
   1. [Core Utilities](#core-utilities)
1. [Virtual DOM APIs](#virtual-dom-apis)
   1. [API Name: axe.utils.getFlattenedTree](#api-name-axeutilsgetflattenedtree)
   1. [API Name: axe.utils.getNodeFromTree](#api-name-axeutilsgetnodefromtree)
1. [Test Utilities](#test-utilities)
   1. [Test Util Name: axe.testUtils.MockCheckContext](#test-util-name-mockcheckcontext)
   1. [Test Util Name: axe.testUtils.shadowSupport](#test-util-name-shadowsupport)
   1. [Test Util Name: axe.testUtils.fixtureSetup](#test-util-name-fixturesetup)
   1. [Test Util Name: axe.testUtils.checkSetup](#test-util-name-checksetup)
1. [Using Rule Generation CLI](#using-rule-generation-cli)

## Getting Started

### Environment Pre-requisites

1. You must have NodeJS installed.
1. Install npm development dependencies. In the root folder of your axe-core repository, run `npm install`

### Building axe.js

To build axe.js, simply run `npm run build` in the root folder of the axe-core repository. axe.js and axe.min.js are placed into the root folder.

### Running Tests

To run all tests from the command line you can run `npm test`, which will run all unit and integration tests using headless chrome and Selenium Webdriver.

You can also load tests in any supported browser, which is helpful for debugging. Tests require a local server to run, you must first start a local server to serve files. You can use Grunt to start one by running `npm start`. Once your local server is running you can load the following pages in any browser to run tests:

1. [Core Tests](../test/core/)
2. [Commons Tests](../test/commons/)
3. [Check Tests](../test/checks/)
4. [Rule Matches](../test/rule-matches/)
5. [Integration Tests](../test/integration/rules/)
6. There are additional tests located in [test/integration/full/](../test/integration/full/) for tests that need to be run against their own document.

### API Reference

[See API exposed on axe](./API.md#section-2-api-reference)

### Supported CSS Selectors

Axe supports the following CSS selectors:

- Type, Class, ID, and Universal selectors. E.g `div.main, #main`
- Pseudo selector `not`. E.g `th:not([scope])`
- Descendant and Child combinators. E.g. `table td`, `ul > li`
- Attribute selectors `=`, `^=`, `$=`, `*=`. E.g `a[href^="#"]`

## Architecture Overview

Axe tests for accessibility using objects called Rules. Each Rule tests for a high-level aspect of accessibility, such as color contrast, button labels, and alternate text for images. Each rule is made up of a series of Checks. Depending on the rule; all, some, or none of these checks must pass in order for the rule to pass.

Upon execution, a Rule runs each of its Checks against all relevant nodes. Which nodes are relevant is determined by the Rule's `selector` property and `matches` function. If a Rule has no Checks that apply to a given node, the Rule will result in an inapplicable result.

After execution, a Check will return `true`, `false`, or `undefined` depending on whether or not the tested condition was satisfied. The result, as well as more information on what caused the Check to pass or fail, will be stored in either the `passes`, `violations`, or `incomplete` arrays.

### Rules

Rules are defined by JSON files in the [lib/rules directory](../lib/rules). The JSON object is used to seed the [Rule object](../lib/core/base/rule.js#L30). A valid Rule JSON consists of the following:

- `id` - `String` A unique name of the Rule.
- `selector` - **optional** `String` which is a [CSS selector](#supported-css-selectors) that specifies the elements of the page on which the Rule runs. axe-core will look inside of the light DOM and _open_ [Shadow DOM](https://developer.mozilla.org/en-US/docs/Web/Web_Components/Shadow_DOM) trees for elements matching the provided selector. If omitted, the rule will run against every node.
- `excludeHidden` - **optional** `Boolean` Whether the rule should exclude hidden elements. Defaults to `true`.
- `enabled` - **optional** `Boolean` Whether the rule is enabled by default. Defaults to `true`.
- `pageLevel` - **optional** `Boolean` Whether the rule is page level. Page level rules will only run if given an entire `document` as context.
- `matches` - **optional** `String` The ID of the filtering function that will exclude elements that match the `selector` property. See the [`metadata-function-map`](../lib/core/base/metadata-function-map.js) file for all defined IDs.
- `impact` - **optional** `String` (one of `minor`, `moderate`, `serious`, or `critical`). Override the impact defined by checks.
- `tags` - **optional** `Array` Strings of the accessibility guidelines of which the Rule applies.
- `metadata` - `Object` Consisting of:
  - `description` - `String` Text string that describes what the rule does.
  - `helpUrl` - `String` **optional** URL that provides more information about the specifics of the violation. Links to a page on the Deque University site.
  - `help` - `String` Help text that describes the test that was performed.
- `any` - `Array` Checks that make up this Rule; one of these checks must return `true` for a Rule to pass.
- `all` - `Array` Checks that make up this Rule; all these checks must return `true` for a Rule to pass.
- `none` - `Array` Checks that make up this Rule; none of these checks must return `true` for a Rule to pass.

The `any`, `all` and `none` arrays must contain either a `String` which references the `id` of the Check; or an object of the following format:

- `id` - `String` The unique ID of the Check.
- `options` - `Mixed` Any options the Check requires that are specific to the Rule.

There is a Grunt target which will ensure each Rule has a valid format, which can be run with `npx grunt validate`.

#### Matches Function

A Rule's `matches` function is executed against each node which matches the Rule's `selector` and receive two parameters:

- `node` – node, the DOM Node to test
- `virtualNode`– object, the virtual DOM representation of the node. See [virtualNode documentation](#virtual-nodes) for more.

The matches function must return either `true` or `false`. Common functions are provided as `commons`. [See the data-table matches function for an example.](../lib/rules/data-table-matches.js)

### Checks

Similar to Rules, Checks are defined by JSON files in the [lib/checks directory](../lib/checks). The JSON object is used to seed the [Check object](../lib/core/base/check.js). A valid Check JSON consists of the following:

- `id` - `String` A unique name of the Check
- `evaluate` - `String` The ID of the function that implements the check's functionality. See the [`metadata-function-map`](../lib/core/base/metadata-function-map.js) file for all defined IDs.
- `after` - **optional** `String` The ID of the function that gets called for checks that operate on a page-level basis, to process the results from the iframes.
- `options` - **optional** `Object` Any information the Check needs that you might need to customize and/or is locale specific. Options can be overridden at runtime (with the options parameter) or config-time. For example, the [valid-lang](../lib/checks/language/valid-lang.json) Check defines what ISO 639-1 language codes it should accept as valid. Options do not need to follow any specific format or type; it is up to the author of a Check to determine the most appropriate format.
- `metadata` - `Object` Consisting of:
  - `impact` - `String` (one of `minor`, `moderate`, `serious`, or `critical`)
  - `messages` - `Object` These messages are displayed when the Check passes or fails
    - `pass` - `String` [doT.js](http://olado.github.io/doT/) template string displayed when the Check passes
    - `fail` - `String` [doT.js](http://olado.github.io/doT/) template string displayed when the Check fails
    - `incomplete` – `String|Object` – [doT.js](http://olado.github.io/doT/) template string displayed when the Check is incomplete OR an object with `missingData` on why it returned incomplete. Refer to [rules.md](./rule-development.md).

#### Check `evaluate`

A Check's evaluate function is run a special context in order to give access to APIs which provide more information. Checks will run against a single node and do not have access to other frames. A Check must either return `true` or `false`.

The following variables are defined for `Check#evaluate`:

- `node` - `HTMLElement` The element that the Check is run against
- `options` - `Mixed` Any options specific to this Check that may be necessary. If not specified by the user at run-time or configure-time; it will use `options` as defined by the Check's JSON file.
- `virtualNode` – `Object` The virtualNode object for use with Shadow DOM. See [virtualNode documentation](#virtual-nodes).
- `this.data()` - `Function` Free-form data that either the Check message requires or is presented as `data` in the CheckResult object. Subsequent calls to `this.data()` will overwrite previous. See [aria-valid-attr](../lib/checks/aria/aria-valid-attr-value-evaluate.js) for example usage.
- `this.relatedNodes()` - `Function` Array or NodeList of elements that are related to this Check. For example the [duplicate-id](../lib/checks/parsing/duplicate-id-evaluate.js) Check will add all Elements which share the same ID.

#### Check `after`

You can use the `after` function to evaluate nodes that might be in other frames or to filter the number of violations or passes produced. The `after` function runs once for each Rule in the top-most (or originating) frame. Due to this, you should not perform DOM operations in after functions, but instead operate on `data` defined by the Check.

For example, the [duplicate-id](../lib/checks/parsing/duplicate-id.json) Check include an [after function](../lib/checks/parsing/duplicate-id-after.js) which reduces the number of violations so that only one violation per instance of a duplicate ID is found.

The following variables are defined for `Check#after`:

- `results` - `Array` Contains [CheckResults](#checkresult) for every matching node.

The after function must return an `Array` of CheckResults, due to this, it is a very common pattern to just use `Array#filter` to filter results:

```js
var uniqueIds = [];
return results.filter(function(r) {
  if (uniqueIds.indexOf(r.data) === -1) {
    uniqueIds.push(r.data);
    return true;
  }
  return false;
});
```

#### Pass, Fail and Incomplete Templates

Occasionally, you may want to add additional information about why a Check passed, failed or returned undefined into its message. For example, the [aria-valid-attr](../lib/checks/aria/valid-attr.json) will add information about any invalid ARIA attributes to its fail message. The message uses a [custom message format](./check-message-template.md). In the Check message, you have access to the `data` object as `data`.

```js
// aria-valid-attr check
"messages": {
  "pass": "ARIA attributes are used correctly for the defined role",
  "fail": {
    "singular": "ARIA attribute is not allowed: ${data.values}",
    "plural": "ARIA attributes are not allowed: ${data.values}"
  },
  "incomplete": "axe-core couldn't tell because of ${data.missingData}"
}
```

See [Developing Axe-core Rules](./rule-development.md) for more information
on writing rules and checks, including incomplete results.

#### CheckResult

When a Check is executed, its result is then added to a [CheckResult object](../lib/core/base/check-result.js). Much like the RuleResult object, the CheckResult object only contains information that is required to determine whether a Check, and its parent Rule passed or failed. `metadata` from the originating Check is combined later and will not be available until axe reaches the reporting stage.

A CheckResult has the following properties:

- `id` - `String` The ID of the Check this CheckResult belongs to.
- `data` - `Mixed` Any data the Check's evaluate function added with `this.data()`. Typically used to insert data from analysis into a message or to perform further tests in the post-processing function.
- `relatedNodes` - `Array` Nodes that are related to the current Check as defined by [check.evaluate](#check-evaluate).
- `result` - `Boolean` The return value of [check.evaluate](#check-evaluate).

### Common Functions

Common functions are an internal library used by the rules and checks. If you have code repeated across rules and checks, you can use these functions and contribute to them. Documentation is available in [source code](../lib/commons/).

#### Commons and Shadow DOM

To support open Shadow DOM while maintaining backwards compatibility, commons functions that query DOM nodes must operate on an in-memory representation of the DOM using axe-core’s built-in [API methods and utility functions](./API.md#virtual-dom-utilities).

Commons functions should do the virtual tree lookup and call a `virtual` function including the rest of the commons code. The naming of this special function should contain the original commons function name with `Virtual` added to signify it expects to operate on a virtual DOM tree.

Let’s look at an example:

```js
// lib/commons/text/accessible-text.js
import { getNodeFromTree } from '../../core/utils';
import accessibleTextVirtual from './accessible-text-virtual';

function accessibleText(element, inLabelledbyContext) {
  let virtualNode = getNodeFromTree(axe._tree[0], element); // throws an exception on purpose if axe._tree not correct
  return accessibleTextVirtual(virtualNode, inLabelledbyContext);
}

export default accessibleText;

// lib/commons/text/accessible-text-virtual.js
function accessibleTextVirtual(element, inLabelledbyContext) {
  // rest of the commons code minus the virtual tree lookup, since it’s passed in
}
```

`accessibleTextVirtual` would only be called directly if you’ve got a virtual node you can use. If you don’t already have one, call the `accessibleText` lookup function, which passes on a virtual DOM node with both the light DOM and Shadow DOM (if applicable).

### Virtual Nodes

To support open Shadow DOM, axe-core has the ability to handle virtual nodes in [rule matches](#matches-function) and [check evaluate](#check-evaluate) functions. The full set of API methods for Shadow DOM can be found in the [API documentation](./API.md#virtual-dom-utilities), but the general structure for a virtualNode is as follows:

```js
{
  actualNode: <HTMLElement>,
  children: <Array>,
  parent: <VirtualNode>,
  shadowId: <String>,
  attr: <Function>,
  hasAttr: <Function>,
  props: <Object>,
}
```

- A virtualNode is an object containing an HTML DOM element (`actualNode`).
- Children contains an array of child VirtualNodes.
- Parent is the VirtualNode parent
- The shadowID indicates whether the node is in an open shadow root and if it is, which one it is inside the boundary.
- Attr is a function which returns the value of the passed in attribute, similar to `node.getAttribute()` (e.g. `vNode.attr('aria-label')`)
- HasAttr is a function which returns true if the VirtualNode has the attribute, similar to `node.hasAttribute()` (e.g. `vNode.hasAttr('aria-label')`)
- Props is an object of HTML DOM element properties. The general structure is as follows:
  ```js
  {
    nodeName: <String>,
    nodeType: <Number>,
    id: <String>,
    nodeValue: <String>
  }
  ```

### Core Utilities

Core Utilities are an internal library that provides axe with functionality used throughout its core processes. Most notably among these are the queue function and the DqElement constructor.

#### Common Utility Functions

In addition to the ARIA lookupTable, there are also utility functions on the axe.commons.aria and axe.commons.dom namespaces:

- `axe.commons.aria.implicitRole` - Get the implicit role for a given node
- `axe.commons.aria.label` - Gets the accessible ARIA label text of a given element
- `axe.commons.dom.isVisible` - Determine whether an element is visible

#### Queue Function

The queue function creates an asynchronous "queue", list of functions to be invoked in parallel, but not necessarily returned in order. The queue function returns an object with the following methods:

- `defer(func)` Defer a function that may or may not run asynchronously
- `then(callback)` The callback to execute once all "deferred" functions have completed. Will only be invoked once.
- `abort()` Abort the "queue" and prevent `then` function from firing

#### DqElement Class

The DqElement is a "serialized" `HTMLElement`. It will calculate the CSS selector, grab the source outerHTML and offer an array for storing frame paths. The DqElement class takes the following parameters:

- `Element` - `HTMLElement` The element to serialize
- `Spec` - `Object` Properties to use in place of the element when instantiated on Elements from other frames

```js
var firstH1 = document.getElementByTagName('h1')[0];
var dqH1 = new axe.utils.DqElement(firstH1);
```

Elements returned by the DqElement class have the following methods and properties:

- `selector` - `string` A unique CSS selector for the element
- `source` - `string` The generated HTML source code of the element
- `element` - `DOMNode` The element which this object is based off or the containing frame, used for sorting.
- `toJSON()` - Returns an object containing the selector and source properties

## Virtual DOM APIs

Note: You shouldn’t need the Shadow DOM APIs below unless you’re working on the axe-core
engine, as rules and checks already have `virtualNode` objects passed in. However, these APIs
will make it easier to work with the virtual DOM.

### API Name: axe.utils.getFlattenedTree

#### Description

Recursively return an array containing the virtual DOM tree for the node specified, excluding comment nodes
and shadow DOM nodes `<content>` and `<slot>`. This method will return a flattened tree containing both
light and shadow DOM, if applicable.

#### Synopsis

```js
var element = document.body;
axe.utils.getFlattenedTree(element, shadowId);
```

#### Parameters

- `node` – HTMLElement. The current HTML node for which you want a flattened DOM tree.
- `shadowId` – string(optional). ID of the shadow DOM that is the closest shadow ancestor of the node

#### Returns

An array of objects, where each object is a virtualNode:

```js
[
  {
    actualNode: body,
    children: [virtualNodes],
    shadowId: undefined
  }
];
```

### API Name: axe.utils.getNodeFromTree

#### Description

Recursively return a single node from a virtual DOM tree. This is commonly used in rules and checks where the node is readily available without querying the DOM.

#### Synopsis

```js
axe.utils.getNodeFromTree(axe._tree[0], node);
```

#### Parameters

- `vNode` – object. The flattened DOM tree to fetch a virtual node from
- `node` – HTMLElement. The HTML DOM node for which you need a virtual representation

#### Returns

A virtualNode object:

```js
{
  actualNode: div,
  children: [virtualNodes],
  shadowId: undefined
}
```

## Test Utilities

All tests must support open Shadow DOM, so we created some test utilities to make this easier.

### Test Util Name: MockCheckContext

Create a check context for mocking and resetting data and relatedNodes in tests.

#### Synopsis

```js
describe('region', function() {
  var fixture = document.getElementById('fixture');

  var checkContext = new axe.testUtils.MockCheckContext();

  afterEach(function() {
    fixture.innerHTML = '';
    checkContext.reset();
  });

  it('should return true when all content is inside the region', function() {
    assert.isTrue(checks.region.evaluate.apply(checkContext, checkArgs));
    assert.equal(checkContext._relatedNodes.length, 0);
  });
});
```

#### Parameters

None

#### Returns

An object containing the data, relatedNodes, and a way to reset them.

```js
{
  data: (){},
  relatedNodes: (){},
  reset: (){}
}
```

### Test Util Name: shadowSupport

Provides an API for determining Shadow DOM v0 and v1 support in tests. For example: PhantomJS doesn't have Shadow DOM support, while some browsers do.

#### Synopsis

```js
(axe.testUtils.shadowSupport.v1 ? it : xit)(
  'should test Shadow tree content',
  function() {
    // The rest of the shadow DOM test
  }
);
```

#### Parameters

None

#### Returns

An object containing booleans for the following Shadow DOM supports: `v0`, `v1`, or `undefined`.

### Test Util Name: fixtureSetup

Method for injecting content into a fixture and caching the flattened DOM tree (light and Shadow DOM together).

#### Synopsis

```js
it(
  'should return true if there is only one ' +
    type +
    ' element with the same name',
  function() {
    axe.testUtils.fixtureSetup(
      '<input type="' +
        type +
        '" id="target" name="uniqueyname">' +
        '<input type="' +
        type +
        '" name="differentname">'
    );

    var node = fixture.querySelector('#target');
    assert.isTrue(check.evaluate.call(checkContext, node));
  }
);
```

#### Parameters

- `content` – Node|String. Stuff to go into the fixture (html or DOM node)

#### Returns

An HTML Element for the fixture

### Test Util Name: checkSetup

Create check arguments.

#### Synopsis

```js
it('should return true when all content is inside the region', function() {
  var checkArgs = checkSetup(
    '<div id="target"><div role="main"><a href="a.html#mainheader">Click Here</a><div><h1 id="mainheader" tabindex="0">Introduction</h1></div></div></div>'
  );

  assert.isTrue(checks.region.evaluate.apply(checkContext, checkArgs));
  assert.equal(checkContext._relatedNodes.length, 0);
});
```

#### Parameters

- `content` – String|Node. Stuff to go into the fixture (html or node)
- `options` – Object. Options argument for the check (optional, default: {})
- `target` – String. Target for the check, CSS selector (default: '#target')

#### Returns

An array with the DOM Node, options and virtualNode

```js
[node, options, virtualNode];
```

## Using Rule Generation CLI

Axe provides a CLI for generating the necessary files and configuration assets for authoring a rule.

To invoke the rule generator, run:

```sh
npm run rule-gen
```

The CLI acts a wizard, by asking a series of questions related to generation of the rule, for example:

```sh
- What is the name of the RULE? (Eg: aria-valid): sample-rule
- Does the RULE need a MATCHES file to be created?: Yes
- Would you like to create a CHECK for the RULE?: No
- Would you like to create UNIT test files? Yes
- Would you like to create INTEGRATION test files? Yes
```

Upon answering of which the assets are created in the respective directories.
