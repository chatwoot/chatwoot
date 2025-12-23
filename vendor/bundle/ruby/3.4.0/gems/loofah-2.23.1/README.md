# Loofah

* https://github.com/flavorjones/loofah
* Docs: http://rubydoc.info/github/flavorjones/loofah/main/frames
* Mailing list: [loofah-talk@googlegroups.com](https://groups.google.com/forum/#!forum/loofah-talk)

## Status

[![ci](https://github.com/flavorjones/loofah/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/flavorjones/loofah/actions/workflows/ci.yml)
[![Tidelift dependencies](https://tidelift.com/badges/package/rubygems/loofah)](https://tidelift.com/subscription/pkg/rubygems-loofah?utm_source=rubygems-loofah&utm_medium=referral&utm_campaign=readme)


## Description

Loofah is a general library for manipulating and transforming HTML/XML documents and fragments, built on top of Nokogiri.

Loofah also includes some HTML sanitizers based on `html5lib`'s safelist, which are a specific application of the general transformation functionality.

Active Record extensions for HTML sanitization are available in the [`loofah-activerecord` gem](https://github.com/flavorjones/loofah-activerecord).


## Features

* Easily write custom transformations for HTML and XML
* Common HTML sanitizing transformations are built-in:
  * _Strip_ unsafe tags, leaving behind only the inner text.
  * _Prune_ unsafe tags and their subtrees, removing all traces that they ever existed.
  * _Escape_ unsafe tags and their subtrees, leaving behind lots of <tt>&lt;</tt> and <tt>&gt;</tt> entities.
  * _Whitewash_ the markup, removing all attributes and namespaced nodes.
* Other common HTML transformations are built-in:
  * Add the _nofollow_ attribute to all hyperlinks.
  * Add the _target=\_blank_ attribute to all hyperlinks.
  * Remove _unprintable_ characters from text nodes.
* Format markup as plain text, with (or without) sensible whitespace handling around block elements.
* Replace Rails's `strip_tags` and `sanitize` view helper methods.


## Compare and Contrast

Loofah is both:

- a general framework for transforming XML, XHTML, and HTML documents
- a specific toolkit for HTML sanitization

### General document transformation

Loofah tries to make it easy to write your own custom scrubbers for whatever document transformation you need. You don't like the built-in scrubbers? Build your own, like a boss.


### HTML sanitization

Another Ruby library that provides HTML sanitization is [`rgrove/sanitize`](https://github.com/rgrove/sanitize), another library built on top of Nokogiri, which provides a bit more flexibility on the tags and attributes being scrubbed.

You may also want to look at [`rails/rails-html-sanitizer`](https://github.com/rails/rails-html-sanitizer) which is built on top of Loofah and provides some useful extensions and additional flexibility in the HTML sanitization.


## The Basics

Loofah wraps [Nokogiri](http://nokogiri.org) in a loving embrace. Nokogiri is a stable, well-maintained parser for XML, HTML4, and HTML5.

Loofah implements the following classes:

* `Loofah::HTML5::Document`
* `Loofah::HTML5::DocumentFragment`
* `Loofah::HTML4::Document` (aliased as `Loofah::HTML::Document` for now)
* `Loofah::HTML4::DocumentFragment` (aliased as `Loofah::HTML::DocumentFragment` for now)
* `Loofah::XML::Document`
* `Loofah::XML::DocumentFragment`

These document and fragment classes are subclasses of the similarly-named Nokogiri classes `Nokogiri::HTML5::Document` et al.

Loofah also implements `Loofah::Scrubber`, which represents the document transformation, either by wrapping
a block,

``` ruby
span2div = Loofah::Scrubber.new do |node|
  node.name = "div" if node.name == "span"
end
```

or by implementing a method.


### Side Note: Fragments vs Documents

Generally speaking, unless you expect to have a DOCTYPE and a single root node, you don't have a *document*, you have a *fragment*. For HTML, another rule of thumb is that *documents* have `html` and `body` tags, and *fragments* usually do not.

**HTML fragments** should be parsed with `Loofah.html5_fragment` or `Loofah.html4_fragment`. The result won't be wrapped in `html` or `body` tags, won't have a DOCTYPE declaration, `head` elements will be silently ignored, and multiple root nodes are allowed.

**HTML documents** should be parsed with `Loofah.html5_document` or `Loofah.html4_document`. The result will have a DOCTYPE declaration, along with `html`, `head` and `body` tags.

**XML fragments** should be parsed with `Loofah.xml_fragment`. The result won't have a DOCTYPE declaration, and multiple root nodes are allowed.

**XML documents** should be parsed with `Loofah.xml_document`. The result will have a DOCTYPE declaration and a single root node.


### Side Note: HTML4 vs HTML5

⚠ _HTML5 functionality is not available on JRuby, or with versions of Nokogiri `< 1.14.0`._

Currently, Loofah's methods `Loofah.document` and `Loofah.fragment` are aliases to `.html4_document` and `.html4_fragment`, which use Nokogiri's HTML4 parser. (Similarly, `Loofah::HTML::Document` and `Loofah::HTML::DocumentFragment` are aliased to `Loofah::HTML4::Document` and `Loofah::HTML4::DocumentFragment`.)

**Please note** that in a future version of Loofah, these methods and classes may switch to using Nokogiri's HTML5 parser and classes on platforms that support it [1].

**We strongly recommend that you explicitly use `.html5_document` or `.html5_fragment`** unless you know of a compelling reason not to. If you are sure that you need to use the HTML4 parser, you should explicitly call `.html4_document` or `.html4_fragment` to avoid breakage in a future version.

  [1]: [[feature request] HTML5 parser for JRuby implementation · Issue #2227 · sparklemotion/nokogiri](https://github.com/sparklemotion/nokogiri/issues/2227)


### `Loofah::HTML5::Document` and `Loofah::HTML5::DocumentFragment`

These classes are subclasses of `Nokogiri::HTML5::Document` and `Nokogiri::HTML5::DocumentFragment`.

The module methods `Loofah.html5_document` and `Loofah.html5_fragment` will parse either an HTML document and an HTML fragment, respectively.

``` ruby
Loofah.html5_document(unsafe_html).is_a?(Nokogiri::HTML5::Document)         # => true
Loofah.html5_fragment(unsafe_html).is_a?(Nokogiri::HTML5::DocumentFragment) # => true
```

Loofah injects a `scrub!` method, which takes either a symbol (for built-in scrubbers) or a `Loofah::Scrubber` object (for custom scrubbers), and modifies the document in-place.

Loofah overrides `to_s` to return HTML:

``` ruby
unsafe_html = "ohai! <div>div is safe</div> <script>but script is not</script>"

doc = Loofah.html5_fragment(unsafe_html).scrub!(:prune)
doc.to_s    # => "ohai! <div>div is safe</div> "
```

and `text` to return plain text:

``` ruby
doc.text    # => "ohai! div is safe "
```

Also, `to_text` is available, which does the right thing with whitespace around block-level and line break elements.

``` ruby
doc = Loofah.html5_fragment("<h1>Title</h1><div>Content<br>Next line</div>")
doc.text    # => "TitleContentNext line"            # probably not what you want
doc.to_text # => "\nTitle\n\nContent\nNext line\n"  # better
```

### `Loofah::HTML4::Document` and `Loofah::HTML4::DocumentFragment`

These classes are subclasses of `Nokogiri::HTML4::Document` and `Nokogiri::HTML4::DocumentFragment`.

The module methods `Loofah.html4_document` and `Loofah.html4_fragment` will parse either an HTML document and an HTML fragment, respectively.

``` ruby
Loofah.html4_document(unsafe_html).is_a?(Nokogiri::HTML4::Document)         # => true
Loofah.html4_fragment(unsafe_html).is_a?(Nokogiri::HTML4::DocumentFragment) # => true
```

### `Loofah::XML::Document` and `Loofah::XML::DocumentFragment`

These classes are subclasses of `Nokogiri::XML::Document` and `Nokogiri::XML::DocumentFragment`.

The module methods `Loofah.xml_document` and `Loofah.xml_fragment` will parse an XML document and an XML fragment, respectively.

``` ruby
Loofah.xml_document(bad_xml).is_a?(Nokogiri::XML::Document)         # => true
Loofah.xml_fragment(bad_xml).is_a?(Nokogiri::XML::DocumentFragment) # => true
```

### Nodes and Node Sets

Nokogiri's `Node` and `NodeSet` classes also get a `scrub!` method, which makes it easy to scrub subtrees.

The following code will apply the `employee_scrubber` only to the `employee` nodes (and their subtrees) in the document:

``` ruby
Loofah.xml_document(bad_xml).xpath("//employee").scrub!(employee_scrubber)
```

And this code will only scrub the first `employee` node and its subtree:

``` ruby
Loofah.xml_document(bad_xml).at_xpath("//employee").scrub!(employee_scrubber)
```

### `Loofah::Scrubber`

A Scrubber wraps up a block (or method) that is run on a document node:

``` ruby
# change all <span> tags to <div> tags
span2div = Loofah::Scrubber.new do |node|
  node.name = "div" if node.name == "span"
end
```

This can then be run on a document:

``` ruby
Loofah.html5_fragment("<span>foo</span><p>bar</p>").scrub!(span2div).to_s
# => "<div>foo</div><p>bar</p>"
```

Scrubbers can be run on a document in either a top-down traversal (the default) or bottom-up. Top-down scrubbers can optionally return `Scrubber::STOP` to terminate the traversal of a subtree. Read below and in the `Loofah::Scrubber` class for more detailed usage.

Here's an XML example:

``` ruby
# remove all <employee> tags that have a "deceased" attribute set to true
bring_out_your_dead = Loofah::Scrubber.new do |node|
  if node.name == "employee" and node["deceased"] == "true"
    node.remove
    Loofah::Scrubber::STOP # don't bother with the rest of the subtree
  end
end
Loofah.xml_document(File.read('plague.xml')).scrub!(bring_out_your_dead)
```

### Built-In HTML Scrubbers

Loofah comes with a set of sanitizing scrubbers that use `html5lib`'s safelist algorithm:

``` ruby
doc = Loofah.html5_document(input)
doc.scrub!(:strip)       # replaces unknown/unsafe tags with their inner text
doc.scrub!(:prune)       #  removes unknown/unsafe tags and their children
doc.scrub!(:escape)      #  escapes unknown/unsafe tags, like this: &lt;script&gt;
doc.scrub!(:whitewash)   #  removes unknown/unsafe/namespaced tags and their children,
                         #          and strips all node attributes
```

Loofah also comes with some common transformation tasks:

``` ruby
doc.scrub!(:nofollow)    #  adds rel="nofollow" attribute to links
doc.scrub!(:noopener)    #  adds rel="noopener" attribute to links
doc.scrub!(:noreferrer)  #  adds rel="noreferrer" attribute to links
doc.scrub!(:unprintable) #  removes unprintable characters from text nodes
doc.scrub!(:targetblank) #     adds target="_blank" attribute to links
```

See `Loofah::Scrubbers` for more details and example usage.


### Chaining Scrubbers

You can chain scrubbers:

``` ruby
Loofah.html5_fragment("<span>hello</span> <script>alert('OHAI')</script>") \
      .scrub!(:prune) \
      .scrub!(span2div).to_s
# => "<div>hello</div> "
```

### Shorthand

The class methods `Loofah.scrub_html5_fragment` and `Loofah.scrub_html5_document` (and the corresponding HTML4 methods) are shorthand.

These methods:

``` ruby
Loofah.scrub_html5_fragment(unsafe_html, :prune)
Loofah.scrub_html5_document(unsafe_html, :prune)
Loofah.scrub_html4_fragment(unsafe_html, :prune)
Loofah.scrub_html4_document(unsafe_html, :prune)
Loofah.scrub_xml_fragment(bad_xml, custom_scrubber)
Loofah.scrub_xml_document(bad_xml, custom_scrubber)
```

do the same thing as (and arguably semantically clearer than):

``` ruby
Loofah.html5_fragment(unsafe_html).scrub!(:prune)
Loofah.html5_document(unsafe_html).scrub!(:prune)
Loofah.html4_fragment(unsafe_html).scrub!(:prune)
Loofah.html4_document(unsafe_html).scrub!(:prune)
Loofah.xml_fragment(bad_xml).scrub!(custom_scrubber)
Loofah.xml_document(bad_xml).scrub!(custom_scrubber)
```


### View Helpers

Loofah has two "view helpers": `Loofah::Helpers.sanitize` and `Loofah::Helpers.strip_tags`, both of which are drop-in replacements for the Rails Action View helpers of the same name.

These are not required automatically. You must require `loofah/helpers` to use them.


## Requirements

* Nokogiri >= 1.5.9


## Installation

Unsurprisingly:

> gem install loofah

Requirements:

* Ruby >= 2.5


## Support

The bug tracker is available here:

* https://github.com/flavorjones/loofah/issues

And the mailing list is on Google Groups:

* Mail: loofah-talk@googlegroups.com
* Archive: https://groups.google.com/forum/#!forum/loofah-talk

Consider subscribing to [Tidelift][tidelift] which provides license assurances and timely security notifications for your open source dependencies, including Loofah. [Tidelift][tidelift] subscriptions also help the Loofah maintainers fund our [automated testing](https://ci.nokogiri.org) which in turn allows us to ship releases, bugfixes, and security updates more often.

  [tidelift]: https://tidelift.com/subscription/pkg/rubygems-loofah?utm_source=undefined&utm_medium=referral&utm_campaign=enterprise


## Security

See [`SECURITY.md`](SECURITY.md) for vulnerability reporting details.


## Related Links

* loofah-activerecord: https://github.com/flavorjones/loofah-activerecord
* Nokogiri: http://nokogiri.org
* libxml2: http://xmlsoft.org
* html5lib: https://github.com/html5lib/


## Authors

* [Mike Dalessio](http://mike.daless.io) ([@flavorjones](https://twitter.com/flavorjones))
* Bryan Helmkamp

Featuring code contributed by:

* [@flavorjones](https://github.com/flavorjones)
* [@brynary](https://github.com/brynary)
* [@olleolleolle](https://github.com/olleolleolle)
* [@JuanitoFatas](https://github.com/JuanitoFatas)
* [@kaspth](https://github.com/kaspth)
* [@tenderlove](https://github.com/tenderlove)
* [@ktdreyer](https://github.com/ktdreyer)
* [@orien](https://github.com/orien)
* [@asok](https://github.com/asok)
* [@junaruga](https://github.com/junaruga)
* [@MothOnMars](https://github.com/MothOnMars)
* [@nick-desteffen](https://github.com/nick-desteffen)
* [@NikoRoberts](https://github.com/NikoRoberts)
* [@trans](https://github.com/trans)
* [@andreynering](https://github.com/andreynering)
* [@aried3r](https://github.com/aried3r)
* [@baopham](https://github.com/baopham)
* [@batter](https://github.com/batter)
* [@brendon](https://github.com/brendon)
* [@cjba7](https://github.com/cjba7)
* [@christiankisssner](https://github.com/christiankisssner)
* [@dacort](https://github.com/dacort)
* [@danfstucky](https://github.com/danfstucky)
* [@david-a-wheeler](https://github.com/david-a-wheeler)
* [@dharamgollapudi](https://github.com/dharamgollapudi)
* [@georgeclaghorn](https://github.com/georgeclaghorn)
* [@gogainda](https://github.com/gogainda)
* [@jaredbeck](https://github.com/jaredbeck)
* [@ThatHurleyGuy](https://github.com/ThatHurleyGuy)
* [@jstorimer](https://github.com/jstorimer)
* [@jbarnette](https://github.com/jbarnette)
* [@queso](https://github.com/queso)
* [@technicalpickles](https://github.com/technicalpickles)
* [@kyoshidajp](https://github.com/kyoshidajp)
* [@kristianfreeman](https://github.com/kristianfreeman)
* [@louim](https://github.com/louim)
* [@mrpasquini](https://github.com/mrpasquini)
* [@olivierlacan](https://github.com/olivierlacan)
* [@pauldix](https://github.com/pauldix)
* [@sampokuokkanen](https://github.com/sampokuokkanen)
* [@stefannibrasil](https://github.com/stefannibrasil)
* [@tastycode](https://github.com/tastycode)
* [@vipulnsward](https://github.com/vipulnsward)
* [@joncalhoun](https://github.com/joncalhoun)
* [@ahorek](https://github.com/ahorek)
* [@rmacklin](https://github.com/rmacklin)
* [@y-yagi](https://github.com/y-yagi)
* [@lazyatom](https://github.com/lazyatom)

And a big shout-out to Corey Innis for the name, and feedback on the API.


## Thank You

The following people have generously funded Loofah with financial sponsorship:

* Bill Harding
* [Sentry](https://sentry.io/) @getsentry


## Historical Note

This library was once named "Dryopteris", which was a very bad name that nobody could spell properly.


## License

Distributed under the MIT License. See `MIT-LICENSE.txt` for details.
