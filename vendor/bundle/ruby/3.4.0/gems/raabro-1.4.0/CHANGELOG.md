
# raabro CHANGELOG.md


## raabro 1.4.0  released 2020-10-06

* Ensure that jseq, for n elts, parses n-1 separators
* Introduce Tree #symbol, #symbod, #strind and #strinpd


## raabro 1.3.3  released 2020-09-24

* Merge Henrik's rewrite_ optimization


## raabro 1.3.2  released 2020-09-24

* Make a tiny rewrite_ optimization


## raabro 1.3.1  released 2020-05-10

* Add '!' (not) seq quantifier


## raabro 1.3.0  released 2020-05-10

* Add `nott` parser element
* Add Tree#strinp and #strim
* Skip 1.2.0 to align on http://github.com/jmettraux/jaabro


## raabro 1.1.6  released 2018-06-22

* Remove unused `add` var, gh-2, thanks to https://github.com/utilum


## raabro 1.1.5  released 2017-08-19

* Default name to nil for Tree#subgather, #gather, #sublookup, and #lookup


## raabro 1.1.4  released 2017-08-17

* fail with ArgumentError if Raabro.pp input is not a Raabro::Tree
* parse(x, error: true) will produce an error message
  `[ line, column, offset, err_message, err_visual ]`


## raabro 1.1.3  released 2016-07-11

* display `>nonstring(14)<` in Raabro.pp
* add "tears" to Raabro.pp


## raabro 1.1.2  released 2016-04-04

* add Raabro.pp(tree)


## raabro 1.1.1  released 2016-04-03

* Tree#clast


## raabro 1.1.0  released 2016-02-09

* many improvements
* unlock custom `rewrite(t)`


## raabro 1.0.5  released 2015-09-25

* allow for .parse(s, debug: 1 to 3)
* drop complications in _narrow(parser)


## raabro 1.0.4  released 2015-09-24

* provide a default .rewrite implementation


## raabro 1.0.3  released 2015-09-23

* drop the shrink! concept


## raabro 1.0.2  released 2015-09-23

* don't let parse() shrink tree when prune: false
* let parse() return tree anyway when prune: false
* add parse(s, rewrite: false) option


## raabro 1.0.1  released 2015-09-23

* take last parser as default :root
* provide default .parse for modules including Raabro


## raabro 1.0.0  released 2015-09-23

* first complete (hopefully) release


## raabro 0.9.0

* initial push to RubyGems

