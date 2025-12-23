# Design

There are three overall goals for this project:

* to provide a documented and maintainable parser
* to provide an error-tolerant parser suitable for use in an IDE
* to provide a portable parser that can be used in projects that don't link against CRuby

The design of the parser is based around these main goals.

## Structure

The first piece to understand about the parser is the design of its syntax tree. This is documented in `config.yml`. Every token and node is defined in that file, along with comments about where they are found in what kinds of syntax. This file is used to template out a lot of different files, all found in the `templates` directory. The `templates/template.rb` script performs the templating and outputs all files matching the directory structure found in the templates directory.

The templated files contain all of the code required to allocate and initialize nodes, pretty print nodes, and serialize nodes. This means for the most part, you will only need to then hook up the parser to call the templated functions to create the nodes in the correct position. That means editing the parser itself, which is housed in `prism.c`.

## Pratt parsing

In order to provide the best possible error tolerance, the parser is hand-written. It is structured using Pratt parsing, a technique developed by Vaughan Pratt back in the 1970s. Below are a bunch of links to articles and papers that explain Pratt parsing in more detail.

* https://web.archive.org/web/20151223215421/http://hall.org.ua/halls/wizzard/pdf/Vaughan.Pratt.TDOP.pdf
* https://tdop.github.io/
* https://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/
* https://matklad.github.io/2020/04/13/simple-but-powerful-pratt-parsing.html
* https://chidiwilliams.com/post/on-recursive-descent-and-pratt-parsing/

You can find most of the functions that correspond to constructs in the Pratt parsing algorithm in `prism.c`. As a couple of examples:

* `parse` corresponds to the `parse_expression` function
* `nud` (null denotation) corresponds to the `parse_expression_prefix` function
* `led` (left denotation) corresponds to the `parse_expression_infix` function
* `lbp` (left binding power) corresponds to accessing the `left` field of an element in the `binding_powers` array
* `rbp` (right binding power) corresponds to accessing the `right` field of an element in the `binding_powers` array

## Portability

In order to enable using this parser in other projects, the parser is written in C99, and uses only the standard library. This means it can be embedded in most any other project without having to link against CRuby. It can be used directly through its C API to access individual fields, or it can used to parse a syntax tree and then serialize it to a single blob. For more information on serialization, see the [docs/serialization.md](serialization.md) file.

## Error tolerance

The design of the error tolerance of this parser is still very much in flux. We are experimenting with various approaches as the parser is being developed to try to determine the best approach. Below are a bunch of links to articles and papers that explain error tolerance in more detail, as well as document some of the approaches that we're evaluating.

* https://tratt.net/laurie/blog/2020/automatic_syntax_error_recovery.html
* https://diekmann.uk/diekmann_phd.pdf
* https://eelcovisser.org/publications/2012/JongeKVS12.pdf
* https://www.antlr.org/papers/allstar-techreport.pdf
* https://github.com/microsoft/tolerant-php-parser/blob/main/docs/HowItWorks.md

Currently, there are a couple of mechanisms for error tolerance that are in place:

* If the parser expects a token in a particular position (for example the `in` keyword in a for loop or the `{` after `BEGIN` or `END`) then it will insert a missing token if one can't be found and continue parsing.
* If the parser expects an expression in a particular position but encounters a token that can't be used as that expression, it checks up the stack to see if that token would close out a parent node. If so, it will close out all of its parent nodes using missing nodes wherever necessary and continue parsing.
* If the parser cannot understand a token in any capacity, it will skip past the token.
