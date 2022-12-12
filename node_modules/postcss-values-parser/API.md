# API Documentation

*Please use only this documented API when working with the parser. Methods
not documented here are subject to change at any point.*

<!-- toc -->

- [`parser` function](#parser-function)
  * [`parser.atword([props])`](#parseratwordprops)
  * [`parser.colon([props])`](#parsercolonprops)
  * [`parser.comma([props])`](#parsercommaprops)
  * [`parser.comment([props])`](#parsercommentprops)
  * [`parser.func([props])`](#parserfuncprops)
  * [`parser.number([props])`](#parsernumberprops)
  * [`parser.operator([props])`](#parseroperatorprops)
  * [`parser.paren([props])`](#parserparenprops)
  * [`parser.string([props])`](#parserstringprops)
  * [`parser.value([props])`](#parservalueprops)
  * [`parser.word([props])`](#parserwordprops)
  * [`parser.unicodeRange([props])`](#parserunicoderangeprops)
- [Node types](#node-types)
  * [`node.type`](#nodetype)
  * [`node.parent`](#nodeparent)
  * [`node.toString()`, `String(node)`, or `'' + node`](#nodetostring-stringnode-or---node)
  * [`node.next()` & `node.prev()`](#nodenext--nodeprev)
  * [`node.replaceWith(node)`](#nodereplacewithnode)
  * [`node.remove()`](#noderemove)
  * [`node.clone()`](#nodeclone)
  * [`node.raws`](#noderaws)
  * [`node.source`](#nodesource)
  * [`node.sourceIndex`](#nodesourceindex)
- [Container types](#container-types)
  * [`container.nodes`](#containernodes)
  * [`container.first` & `container.last`](#containerfirst--containerlast)
  * [`container.at(index)`](#containeratindex)
  * [`container.index(node)`](#containerindexnode)
  * [`container.length`](#containerlength)
  * [`container.each(callback)`](#containereachcallback)
  * [`container.walk(callback)`](#containerwalkcallback)
  * [`container.walk` proxies](#containerwalk-proxies)
  * [`container.prepend(node)` & `container.append(node)`](#containerprependnode--containerappendnode)
  * [`container.insertBefore(old, new)` & `container.insertAfter(old, new)`](#containerinsertbeforeold-new--containerinsertafterold-new)
  * [`container.removeChild(node)`](#containerremovechildnode)
  * [`container.removeAll()` or `container.empty()`](#containerremoveall-or-containerempty)
- [Root nodes`](#root-nodes)
- [Value nodes](#value-nodes)

<!-- tocstop -->

## `parser` function

  This is the module's main entry point, and returns a `new Parser`.

  ```js
  let parser = require('postcss-values-parser');

  let ast = parser(source) // tokenizes the source string
              .parse();    // parses the tokens and returns an AST
  ```

### `parser.atword([props])`

  Creates a new AtWord value.

  ```js
  parser.atword({ value: '@foo' });
  // → @foo
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.colon([props])`

  Creates a new colon Node.

  ```js
  parser.colon({ value: ':' });
  // → :
  ```

  Arguments:

  * `props (object)`: The new node's properties. If no properties are specified,
  the default value of `:` will be used. It's not recommended to deviate from this.

### `parser.comma([props])`

  Creates a new comma Node.

  ```js
  parser.comma({ value: ',' });
  // → ,
  ```

  Arguments:

  * `props (object)`: The new node's properties. If no properties are specified,
  the default value of `,` will be used. It's not recommended to deviate from this.

### `parser.comment([props])`

  Creates a new comment.

  ```js
  parser.comment({ value: 'Affirmative, Dave. I read you.' });
  // → /* Affirmative, Dave. I read you. */
  ```
  
  ```js
  parser.comment({ value: 'Affirmative, Dave. I read you.', inline: true });
  // → // Affirmative, Dave. I read you.
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.func([props])`

  Creates a new function value Container node.

  ```js
  let func = parser.func({ value: 'calc' });

  func.append(parser.paren());
  func.append(parser.paren({ value: ')' }));

  func.toString();
  // → calc()
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.number([props])`

  Creates a new number Node.

  ```js
  parser.number({ value: 10, unit: 'px' });
  // → 10px
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.operator([props])`

  Creates a new operator Node.

  ```js
  parser.operator({ value: '+' });
  // → +
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.paren([props])`

  Creates a new parenthesis Node.

  ```js
  parser.paren();
  // → (

  parser.paren({ value: ')' });
  // → )
  ```

  Arguments:

  * `props (object)`: The new node's properties. If no value is specified, the
  default value of `(` will be used.

### `parser.string([props])`

  Creates a new string node.

  ```js
  parser.string();
  // → (empty)

  parser.string({ value: 'hello', quote: '"' });
  // → "hello"
  ```

  Arguments:

  * `props (object)`: The new node's properties. Note: If no `quote` property is
  specified, the default value of `'` will be used.

### `parser.value([props])`

  Creates a new value Node. This node acts as the container for all values within
  the Root node, but can be created for convenience.

### `parser.word([props])`

  Creates a new word Node. A `Word` is anything that doesn't fall into one of the
  other node types.

  ```js
  let word = parser.word({ value: '#fff' });
  // → #fff

  word.isHex;
  // → true

  word.isColor;
  // → true
  ```

  Arguments:

  * `props (object)`: The new node's properties.

### `parser.unicodeRange([props])`

  Creates a new unicode range Node.

  ```js
  parser.unicodeRange({ value: 'U+26' });
  // → U+26
  ```

  Arguments:

  * `props (object)`: The new node's properties.
  
## Node types

### `node.type`

  A string representation of the node type. It can be one of the following;
  `atword`, `colon`, `comma`, `comment`, `func`, `number`, `operator`,
  `paren`, `string`, `unicoderange`, `value`, `word`.

  ```js
  parser.word({ value: '#fff' }).type;
  // → 'word'
  ```

### `node.parent`

  Returns the parent node.

  ```js
  root.nodes[0].parent === root;
```

### `node.toString()`, `String(node)`, or `'' + node`

  Returns a string representation of the node.

  ```js
  let color = parser.word({ value: '#fff' });
  console.log(String(color));
  // → #fff
  ```

### `node.next()` & `node.prev()`

  Returns the next/previous child of the parent node.

  ```js
  let next = func.next();
  if (next && next.type !== 'paren') {
      throw new Error('Unclosed function parenthesis!');
  }
  ```

### `node.replaceWith(node)`

  Replace a node with another.

  ```js
  let ast = parser('#fff').parse();
  let word = ast.first.first;
  let atword = parser.atword({ value: '@purple' });

  word.replaceWith(atword);
  ```

  Arguments:

  * `node`: The node to substitute the original with.

### `node.remove()`

  Removes the node from its parent node.

  ```js
  if (node.type === 'word') {
      node.remove();
  }
  ```

### `node.clone()`

  Returns a copy of a node, detached from any parent containers that the
  original might have had.

  ```js
  let word = parser.word({ value: '#fff' });
  let cloned = word.clone();

  cloned.value = '#fff';
  String(cloned);
  // → #000

  String(word);
  // → #fff
  ```

### `node.raws`

  Extra whitespaces around the node will be assigned to `node.raws.before` and
  `node.raws.after`. Spaces in this context have no semantic meaning, but may
  be useful for inspection:

  ```css
    1px        solid         black
  ```

  Any space following a node/segement is assigned to the next node's
  `raws.before` property, unless the node with the trailing space is the only
  node in the set.

  ```js
  let source = 'calc(something about mary)';
  let ast = parser(source).parse();
  let func = ast.first.first;

  let something = func.first.next();
  let about = something.next();

  something.raws.after;
  // → (empty)

  about.raws.before;
  // → ' '
  ```

  Additionally, any space remaining after the last node in a
  set will be assigned to the last non-symbol child's `raws.after` property.
  For example:

  ```js
  let source = 'calc(something )';
  let ast = parser(source).parse();
  let func = ast.first.first;

  let something = func.first.next();
  something.raws.after;
  // → ' '
  ```

### `node.source`

An object describing the node's start/end, line/column source position.

Within the following CSS, the `.bar` class node ...

```css
.foo,
  .bar {}
```

... will contain the following `source` object.

```js
source: {
    start: {
        line: 2,
        column: 3
    },
    end: {
        line: 2,
        column: 6
    }
}
```

### `node.sourceIndex`

The zero-based index of the node within the original source string.

Within the following CSS, the `.baz` class node will have a `sourceIndex` of `12`.

```css
.foo, .bar, .baz {}
```

## Container types

The `root`, `node`, and `pseudo` nodes have some helper methods for working
with their children.

### `container.nodes`

  An array of the container's children.

  ```js
  // Input: h1 h2
  nodes.at(0).nodes.length   // → 3
  nodes.at(0).nodes[0].value // → 'h1'
  nodes.at(0).nodes[1].value // → ' '
  ```

### `container.first` & `container.last`

  The first/last child of the container.

  ```js
  node.first === node.nodes[0];
  node.last === node.nodes[node.nodes.length - 1];
  ```

### `container.at(index)`

  Returns the node at position `index`.

  ```js
  node.at(0) === node.first;
  node.at(0) === node.nodes[0];
  ```

  Arguments:

  * `index`: The index of the node to return.

### `container.index(node)`

  Return the index of the node within its container.

  ```js
  node.index(node.nodes[2]) // → 2
  ```

  Arguments:

  * `node`: A node within the current container.

### `container.length`

  Proxy to the length of the container's nodes.

  ```js
  container.length === container.nodes.length
  ```

### `container.each(callback)`

  Iterate the container's immediate children, calling `callback` for each child.
  You may return `false` within the callback to break the iteration.

  ```js
  let className;
  nodes.each(function (node, index) {
      if (node.type === 'class') {
          className = node.value;
          return false;
      }
  });
  ```

  Note that unlike `Array#forEach()`, this iterator is safe to use whilst adding
  or removing nodes from the container.

  Arguments:

  * `callback (function)`: A function to call for each node, which receives `node`
    and `index` arguments.

### `container.walk(callback)`

  Like `container#each`, but will also iterate child nodes as long as they are
  `container` types.

  ```js
  nodes.walk(function (node, index) {
      // all nodes
  });
  ```

  Arguments:

  * `callback (function)`: A function to call for each node, which receives `node`
    and `index` arguments.

  This iterator is safe to use whilst mutating `container.nodes`,
  like `container#each`.

### `container.walk` proxies

The container class provides proxy methods for iterating over types of nodes,
so that it is easier to write modules that target specific nodes. Those
methods are:

* `container.walkAtWords`
* `container.walkColons`
* `container.walkCommas`
* `container.walkComments`
* `container.walkFunctionNodes`
* `container.walkNumberNodes`
* `container.walkOperators`
* `container.walkParenthesis`
* `container.walkStringNodes`
* `container.walkUnicodeRanges`
* `container.walkWords`

### `container.prepend(node)` & `container.append(node)`

Add a node to the start/end of the container. Note that doing so will set
the parent property of the node to this container.

```js
let color = parser.word({ value: '#fff' });
node.append(color);
```

Arguments:

* `node`: The node to add.

### `container.insertBefore(old, new)` & `container.insertAfter(old, new)`

Add a node before or after an existing node in a container:

```js
nodes.walk(function (node) {
    if (node.type !== 'word') {
        let colon = parser.colon();
        node.parent.insertAfter(node, colon);
    }
});
```

Arguments:

* `old`: The existing node in the container.
* `new`: The new node to add before/after the existing node.

### `container.removeChild(node)`

Remove the node from the container. Note that you can also use
`node.remove()` if you would like to remove just a single node.

```js
node.length // → 2
node.remove(word)
node.length // → 1;
word.parent       // undefined
```

Arguments:

* `node`: The node to remove.

### `container.removeAll()` or `container.empty()`

Remove all children from the container.

```js
node.removeAll();
node.length // → 0
```

## Root nodes`

A root node represents the top-level Container for Value nodes. Indeed, all
a root's `toString()` method does is join its node children with a ','.
Other than this, it has no special functionality and acts like a container.

## Value nodes

A Value node represents a single compound node. For example, this
node string `1px solid black`, is represented as three distinct nodes.
It has no special functionality of its own.
