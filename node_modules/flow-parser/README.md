# The flow-parser package

This package contains the Flow parser in its compiled-to-JavaScript form.

# What is Flow

See [flow.org](https://flow.org/). The code for the Flow parser [lives on GitHub](https://github.com/facebook/flow/tree/master/src/parser).

# What is the Flow Parser

The Flow Parser is a JavaScript parser written in OCaml. It produces an AST that conforms to the [ESTree spec](https://github.com/estree/estree) and that mostly matches what [esprima](http://esprima.org/) produces. The Flow Parser can be compiled to native code or can be compiled to JavaScript using [js_of_ocaml](http://ocsigen.org/js_of_ocaml/). This npm package contains the Flow parser compiled to JavaScript.

# Usage

You can use the Flow parser in your browser or in node. To use in node you can just do

```JavaScript
require('flow-parser').parse('1+1', {});
```

To use in the browser, you can add

```HTML
<script src="flow_parser.js"></script>
```

which will make the `flow` object available to use like so:

```JavaScript
flow.parse('1+1', {});
```

## Options

The second argument to `flow.parse` is the options object. Currently supported options:

* `all_comments` (boolean, default `true`) - include a list of all comments from the whole program
* `comments` (boolean, default `true`) - attach comments to AST nodes (`leadingComments` and `trailingComments`)
* `enums` (boolean, default `false`) - enable parsing of Flow enums
* `esproposal_class_instance_fields` (boolean, default `false`) - enable parsing of class instance fields
* `esproposal_class_static_fields` (boolean, default `false`) - enable parsing of class static fields
* `esproposal_decorators` (boolean, default `false`) - enable parsing of decorators
* `esproposal_export_star_as` (boolean, default `false`) - enable parsing of `export * as` syntax
* `esproposal_nullish_coalescing` (boolean, default `false`) - enable parsing of nullish coalescing (`??`)
* `esproposal_optional_chaining` (boolean, default `false`) - enable parsing of optional chaining (`?.`)
* `types` (boolean, default `true`) - enable parsing of Flow types
* `use_strict` (boolean, default `false`) - treat the file as strict, without needing a "use strict" directive
