# json-logic-js

This parser accepts [JsonLogic](http://jsonlogic.com) rules and executes them in JavaScript.

The JsonLogic format is designed to allow you to share rules (logic) between front-end and back-end code (regardless of language difference), even to store logic along with a record in a database.  JsonLogic is documented extensively at [JsonLogic.com](http://jsonlogic.com), including examples of every [supported operation](http://jsonlogic.com/operations.html) and a place to [try out rules in your browser](http://jsonlogic.com/play.html).

The same format can also be executed in PHP by the library [json-logic-php](https://github.com/jwadhams/json-logic-php/)

## Installation

We recommend that you install this library with a package manager, like [NPM](https://www.npmjs.com/) (or Yarn, etc):

```bash
npm install json-logic-js
```

Note that this project uses a [module loader](http://ricostacruz.com/cheatsheets/umdjs.html) that also makes it suitable for RequireJS projects.

If that doesn't suit you, and you want to manage updates yourself, the entire library is self-contained in `logic.js` and you can download it straight into your project as you see fit.

```bash
curl -O https://raw.githubusercontent.com/jwadhams/json-logic-js/master/logic.js
```

## Examples

### Simple
```js
jsonLogic.apply( { "==" : [1, 1] } );
// true
```

This is a simple test, equivalent to `1 == 1`.  A few things about the format:

  1. The operator is always in the "key" position. There is only one key per JsonLogic rule.
  1. The values are typically an array.
  1. Each value can be a string, number, boolean, array (non-associative), or null

### Compound
Here we're beginning to nest rules.

```js
jsonLogic.apply(
  {"and" : [
    { ">" : [3,1] },
    { "<" : [1,3] }
  ] }
);
// true
```

In an infix language (like JavaScript) this could be written as:

```js
( (3 > 1) && (1 < 3) )
```

### Data-Driven

Obviously these rules aren't very interesting if they can only take static literal data. Typically `jsonLogic` will be called with a rule object and a data object. You can use the `var` operator to get attributes of the data object:

```js
jsonLogic.apply(
  { "var" : ["a"] }, // Rule
  { a : 1, b : 2 }   // Data
);
// 1
```

If you like, we support [syntactic sugar](https://en.wikipedia.org/wiki/Syntactic_sugar) on unary operators to skip the array around values:

```js
jsonLogic.apply(
  { "var" : "a" },
  { a : 1, b : 2 }
);
// 1
```

You can also use the `var` operator to access an array by numeric index:

```js
jsonLogic.apply(
  {"var" : 1 },
  [ "apple", "banana", "carrot" ]
);
// "banana"
```

Here's a complex rule that mixes literals and data. The pie isn't ready to eat unless it's cooler than 110 degrees, *and* filled with apples.

```js
var rules = { "and" : [
  {"<" : [ { "var" : "temp" }, 110 ]},
  {"==" : [ { "var" : "pie.filling" }, "apple" ] }
] };

var data = { "temp" : 100, "pie" : { "filling" : "apple" } };

jsonLogic.apply(rules, data);
// true
```

### Always and Never
Sometimes the rule you want to process is "Always" or "Never."  If the first parameter passed to `jsonLogic` is a non-object, non-associative-array, it is returned immediately.

```js
//Always
jsonLogic.apply(true, data_will_be_ignored);
// true

//Never
jsonLogic.apply(false, i_wasnt_even_supposed_to_be_here);
// false
```

## Compatibility

This library makes use of `Array.map` and `Array.reduce`, so it's not *exactly* Internet Explorer 8 friendly.

If you want to use JsonLogic *and* support deprecated browsers, you could easily use [BabelJS's polyfill](https://babeljs.io/docs/usage/polyfill/) or directly incorporate the polyfills documented on MDN for [map](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map) and [reduce](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce).

## Customization

It's not possible to include everyone's excellent ideas without the core library bloating, bringing in a ton of outside dependencies, or occasionally causing use case conflicts (some people need to safely execute untrusted rules, some people need to change outside state).

Check out the [documentation for adding custom operations](http://jsonlogic.com/add_operation.html) and be sure to stop by the [Wiki page of custom operations](https://github.com/jwadhams/json-logic-js/wiki/Custom-Operations) to see if someone has already solved your problem or to share your solution.
