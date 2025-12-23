# JavaScript

Prism provides bindings to JavaScript out of the box.

## Node

To use the package from node, install the `@ruby/prism` dependency:

```sh
npm install @ruby/prism
```

Then import the package:

```js
import { loadPrism } from "@ruby/prism";
```

Then call the load function to get a parse function:

```js
const parse = await loadPrism();
```

## Browser

To use the package from the browser, you will need to do some additional work. The [javascript/example.html](../javascript/example.html) file shows an example of running Prism in the browser. You will need to instantiate the WebAssembly module yourself and then pass it to the `parsePrism` function.

First, get a shim for WASI since not all browsers support it yet.

```js
import { WASI } from "https://unpkg.com/@bjorn3/browser_wasi_shim@latest/dist/index.js";
```

Next, import the `parsePrism` function from `@ruby/prism`, either through a CDN or by bundling it with your application.

```js
import { parsePrism } from "https://unpkg.com/@ruby/prism@latest/src/parsePrism.js";
```

Next, fetch and instantiate the WebAssembly module. You can access it through a CDN or by bundling it with your application.

```js
const wasm = await WebAssembly.compileStreaming(fetch("https://unpkg.com/@ruby/prism@latest/src/prism.wasm"));
```

Next, instantiate the module and initialize WASI.

```js
const wasi = new WASI([], [], []);
const instance = await WebAssembly.instantiate(wasm, { wasi_snapshot_preview1: wasi.wasiImport });
wasi.initialize(instance);
```

Finally, you can create a function that will parse a string of Ruby code.

```js
function parse(source) {
  return parsePrism(instance.exports, source);
}
```

## API

Now that we have access to a `parse` function, we can use it to parse Ruby code:

```js
const parseResult = parse("1 + 2");
```

A ParseResult object is very similar to the Prism::ParseResult object from Ruby. It has the same properties: `value`, `comments`, `magicComments`, `errors`, and `warnings`. Here we can serialize the AST to JSON.

```js
console.log(JSON.stringify(parseResult.value, null, 2));
```

## Visitors

Prism allows you to traverse the AST of parsed Ruby code using visitors.

Here's an example of a custom `FooCalls` visitor:

```js
import { loadPrism, Visitor } from "@ruby/prism"

const parse = await loadPrism();
const parseResult = parse("foo()");

class FooCalls extends Visitor {
  visitCallNode(node) {
    if (node.name === "foo") {
      // Do something with the node
    }

    // Call super so that the visitor continues walking the tree
    super.visitCallNode(node);
  }
}

const fooVisitor = new FooCalls();

parseResult.value.accept(fooVisitor);
```

## Building

To build the WASM package yourself, first obtain a copy of `wasi-sdk`. You can retrieve this here: <https://github.com/WebAssembly/wasi-sdk>. Next, run:

```sh
make wasm WASI_SDK_PATH=path/to/wasi-sdk
```

This will generate `javascript/src/prism.wasm`. From there, you can run the tests to verify everything was generated correctly.

```sh
cd javascript
node test
```
