# Slim

[![Gem Version](https://img.shields.io/gem/v/slim.svg)](http://rubygems.org/gems/slim) [![Build Status](https://img.shields.io/travis/slim-template/slim.svg?branch=master)](http://travis-ci.org/slim-template/slim) [![Code Climate](https://codeclimate.com/github/slim-template/slim/badges/gpa.svg)](https://codeclimate.com/github/slim-template/slim) [![Test Coverage](https://codeclimate.com/github/slim-template/slim/badges/coverage.svg)](https://codeclimate.com/github/slim-template/slim/coverage)
[![Flattr donate button](https://raw.github.com/balupton/flattr-buttons/master/badge-89x18.gif)](https://flattr.com/submit/auto?user_id=min4d&url=http%3A%2F%2Fslim-lang.org%2F "Donate monthly to this project using Flattr")

Slim is a template language whose goal is to reduce the view syntax to the essential parts without becoming cryptic. It started as an exercise to see how much could be removed from a standard html template (<, >, closing tags, etc...). As more people took an interest in Slim, the functionality grew and so did the flexibility of the syntax.

A short list of the features...

* Elegant syntax
    * Short syntax without closing tags (Using indentation instead)
    * HTML style mode with closing tags
    * Configurable shortcut tags (`#` for `<div id="...">` and `.` for `<div class="...">` in the default configuration)
* Safety
    * Automatic HTML escaping by default
    * Support for Rails' `html_safe?`
* Highly configurable
* Extensible via the following plugins:
    * Logic less mode similar to Mustache
    * Includes
    * Translator/I18n
* High performance
    * Comparable speed to ERB/Erubis
    * Streaming support in Rails
* Supported by all major frameworks (Rails, Sinatra, ...)
* Full Unicode support for tags and attributes
* Embedded engines like Markdown and Textile

## Links

* Homepage: <http://slim-lang.com>
* Source: <http://github.com/slim-template/slim>
* Bugs:   <http://github.com/slim-template/slim/issues>
* List:   <http://groups.google.com/group/slim-template>
* API documentation:
    * Latest Gem: <http://rubydoc.info/gems/slim/frames> <https://www.omniref.com/ruby/gems/slim>
    * GitHub master: <http://rubydoc.info/github/slim-template/slim/master/frames> <https://www.omniref.com/github/slim-template/slim>

## Introduction

### What is Slim?

Slim is a fast, lightweight templating engine with support for __Rails 3 and later__. It has been heavily tested on all major ruby implementations. We use
continuous integration (travis-ci).

Slim's core syntax is guided by one thought: "What's the minimum required to make this work".

As more people have contributed to Slim, there have been syntax additions influenced from their use of [Haml](https://github.com/haml/haml) and [Jade](https://github.com/visionmedia/jade).  The Slim team is open to these additions because we know beauty is in the eye of the beholder.

Slim uses [Temple](https://github.com/judofyr/temple) for parsing/compilation and is also integrated into [Tilt](https://github.com/rtomayko/tilt), so it can be used together with [Sinatra](https://github.com/sinatra/sinatra) or plain [Rack](https://github.com/rack/rack).

The architecture of Temple is very flexible and allows the extension of the parsing and compilation process without monkey-patching. This is used
by the logic less plugin and the translator plugin which provides I18n. In logic-less mode you can use Slim if you like the Slim syntax to build your HTML but don't want to write Ruby in your templates.

### Why use Slim?

* Slim allows you to write very minimal templates which are easy to maintain and pretty much guarantees that you write well-formed HTML and XML
* The Slim syntax is aesthetic and makes it more fun to write templates. Since you can use Slim as a drop-in replacement in all the major frameworks it is easy to adopt.
* The Slim architecture is very flexible and allows you to write syntax extensions and plugins.

___Yes, Slim is speedy!___ Slim was developed right from the start with performance in mind.
Benchmarks are done for every commit at <http://travis-ci.org/slim-template/slim>.
Don't trust the numbers? That's as it should be. Please try the benchmark rake task yourself!

However in our opinion you should use Slim because of its features and syntax. We just ensure that Slim doesn't have a negative impact on the performance of your application.

### How to start?

Install Slim as a gem:

~~~
gem install slim
~~~

Include Slim in your Gemfile with `gem 'slim'` or require it with `require 'slim'`. That's it! Now, just use the .slim extension and you're good to go.

### Syntax example

Here's a quick example to demonstrate what a Slim template looks like:

~~~ slim
doctype html
html
  head
    title Slim Examples
    meta name="keywords" content="template language"
    meta name="author" content=author
    link rel="icon" type="image/png" href=file_path("favicon.png")
    javascript:
      alert('Slim supports embedded javascript!')

  body
    h1 Markup examples

    #content
      p This example shows you how a basic Slim file looks.

    == yield

    - if items.any?
      table#items
        - for item in items
          tr
            td.name = item.name
            td.price = item.price
    - else
      p No items found. Please add some inventory.
        Thank you!

    div id="footer"
      == render 'footer'
      | Copyright &copy; #{@year} #{@author}
~~~

Indentation matters, but the indentation depth can be chosen as you like. If you want to first indent 2 spaces, then 5 spaces, it's your choice. To nest markup you only need to indent by one space, the rest is gravy.

## Line indicators

### Verbatim text `|`

The pipe tells Slim to just copy the line. It essentially escapes any processing.
Each following line that is indented greater than the pipe is copied over.

~~~ slim
body
  p
    |
      This is a test of the text block.
~~~

  The parsed result of the above:

~~~ html
<body><p>This is a test of the text block.</p></body>
~~~

  If the text starts on the same line, the left margin is set at the indent of the pipe + one space.
  Any additional spaces will be copied over.

~~~ slim
body
  p
    | This line is on the left margin.
       This line will have one space in front of it.
         This line will have two spaces in front of it.
           And so on...
~~~

You can also embed html in the text line

~~~ slim
- articles.each do |a|
  | <tr><td>#{a.name}</td><td>#{a.description}</td></tr>
~~~

### Verbatim text with trailing white space `'`

The single quote tells Slim to copy the line (similar to `|`), but makes sure that a single trailing white space is appended.

### Inline html `<`

You can write html tags directly in Slim which allows you to write your templates in a more html like style with closing tags or mix html and Slim style.
The leading `<` works like an implicit `|`:

~~~ slim
<html>
  head
    title Example
  <body>
    - if articles.empty?
    - else
      table
        - articles.each do |a|
          <tr><td>#{a.name}</td><td>#{a.description}</td></tr>
  </body>
</html>
~~~

### Control code `-`

The dash denotes control code.  Examples of control code are loops and conditionals. `end` is forbidden behind `-`. Blocks are defined only by indentation.
If your ruby code needs to use multiple lines, append a backslash `\` at the end of the lines. If your line ends with comma `,` (e.g because of a method call) you don't need the additional backslash before the linebreak.

~~~ slim
body
  - if articles.empty?
    | No inventory
~~~

### Output `=`

The equals sign tells Slim it's a Ruby call that produces output to add to the buffer. If your ruby code needs to use multiple lines, append a backslash `\` at the end of the lines. For example:

~~~ slim
= javascript_include_tag \
   "jquery",
   "application"
~~~

If your line ends with comma `,` (e.g because of a method call) you don't need the additional backslash before the linebreak. For trailing or leading whitespace the modifiers `>` and `<` are supported.

* Output with trailing white space `=>`. Same as the single equals sign (`=`), except that it adds a trailing white space.
* Output with leading white space `=<`. Same as the single equals sign (`=`), except that it adds a leading white space.

### Output without HTML escaping `==`

Same as the single equals sign (`=`), but does not go through the `escape_html` method. For trailing or leading whitespace the modifiers `>` and `<` are supported.

* Output without HTML escaping and trailing white space `==>`. Same as the double equals sign (`==`), except that it adds a trailing white space.
* Output without HTML escaping and leading white space `==<`. Same as the double equals sign (`==`), except that it adds a leading white space.

### Code comment `/`

Use the forward slash for code comments - anything after it won't get displayed in the final render. Use `/` for code comments and `/!` for html comments

~~~ slim
body
  p
    / This line won't get displayed.
      Neither does this line.
    /! This will get displayed as html comments.
~~~

  The parsed result of the above:

~~~ html
<body><p><!--This will get displayed as html comments.--></p></body>
~~~

### HTML comment `/!`

Use the forward slash immediately followed by an exclamation mark for html comments (`<!-- ... -->`).

### IE conditional comment `/[...]`

~~~ slim
/[if IE]
    p Get a better browser.
~~~

This renders as:

~~~ html
<!--[if IE]><p>Get a better browser.</p><![endif]-->
~~~

## HTML tags

### <!DOCTYPE> declaration

The doctype keyword can be used to generate the complex doctypes in a very simple manner.

XML VERSION

~~~ slim
doctype xml
  <?xml version="1.0" encoding="utf-8" ?>

doctype xml ISO-8859-1
  <?xml version="1.0" encoding="iso-8859-1" ?>
~~~

XHTML DOCTYPES

~~~ slim
doctype html
  <!DOCTYPE html>

doctype 5
  <!DOCTYPE html>

doctype 1.1
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

doctype strict
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

doctype frameset
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">

doctype mobile
  <!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN"
    "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">

doctype basic
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN"
    "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">

doctype transitional
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
~~~

HTML 4 DOCTYPES

~~~ slim
doctype strict
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">

doctype frameset
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
    "http://www.w3.org/TR/html4/frameset.dtd">

doctype transitional
  <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
    "http://www.w3.org/TR/html4/loose.dtd">
~~~

### Closed tags (trailing `/`)

You can close tags explicitly by appending a trailing `/`.

~~~ slim
img src="image.png"/
~~~

Note, that this is usually not necessary since the standard html
tags (img, br, ...) are closed automatically.

### Trailing and leading whitespace (`<`, `>`)

You can force Slim to add a trailing whitespace after a tag by adding a `>`.

~~~ slim
a> href='url1' Link1
a> href='url2' Link2
~~~

You can add a leading whitespace by adding `<`.

~~~ slim
a< href='url1' Link1
a< href='url2' Link2
~~~

You can also combine both.

~~~ slim
a<> href='url1' Link1
~~~

### Inline tags

Sometimes you may want to be a little more compact and inline the tags.

~~~ slim
ul
  li.first: a href="/a" A link
  li: a href="/b" B link
~~~

For readability, don't forget you can wrap the attributes.

~~~ slim
ul
  li.first: a[href="/a"] A link
  li: a[href="/b"] B link
~~~

### Text content

Either start on the same line as the tag

~~~ slim
body
  h1 id="headline" Welcome to my site.
~~~

Or nest it.  You must use a pipe or an apostrophe to escape processing


~~~ slim
body
  h1 id="headline"
    | Welcome to my site.
~~~

Or enable and rely on smart text instead

~~~ slim
body
  h1 id="headline"
    Welcome to my site.
~~~

### Dynamic content (`=` and `==`)

Can make the call on the same line

~~~ slim
body
  h1 id="headline" = page_headline
~~~

Or nest it.

~~~ slim
body
  h1 id="headline"
    = page_headline
~~~

### Attributes

You write attributes directly after the tag. For normal text attributes you must use double `"` or single quotes `'` (Quoted attributes).

~~~ slim
a href="http://slim-lang.com" title='Slim Homepage' Goto the Slim homepage
~~~

You can use text interpolation in the quoted attributes.

#### Attributes wrapper

If a delimiter makes the syntax more readable for you,
you can use the characters `{...}`, `(...)`, `[...]` to wrap the attributes.
You can configure these symbols (See option `:attr_list_delims`).

~~~ slim
body
  h1(id="logo") = page_logo
  h2[id="tagline" class="small tagline"] = page_tagline
~~~

If you wrap the attributes, you can spread them across multiple lines:

~~~ slim
h2[id="tagline"
   class="small tagline"] = page_tagline
~~~

You may use spaces around the wrappers and assignments:

~~~ slim
h1 id = "logo" = page_logo
h2 [ id = "tagline" ] = page_tagline
~~~

#### Quoted attributes

Example:

~~~ slim
a href="http://slim-lang.com" title='Slim Homepage' Goto the Slim homepage
~~~

You can use text interpolation in the quoted attributes:

~~~ slim
a href="http://#{url}" Goto the #{url}
~~~

The attribute value will be escaped by default. Use == if you want to disable escaping in the attribute.

~~~ slim
a href=="&amp;"
~~~

You can break quoted attributes with backslash `\`

~~~ slim
a data-title="help" data-content="extremely long help text that goes on\
  and on and on and then starts over...."
~~~

#### Ruby attributes

Write the ruby code directly after the `=`. If the code contains spaces you have to wrap
the code into parentheses `(...)`. You can also directly write hashes `{...}` and arrays `[...]`.

~~~ slim
body
  table
    - for user in users
      td id="user_#{user.id}" class=user.role
        a href=user_action(user, :edit) Edit #{user.name}
        a href=(path_to_user user) = user.name
~~~

The attribute value will be escaped by default. Use == if you want to disable escaping in the attribute.

~~~ slim
a href==action_path(:start)
~~~

You can also break ruby attributes with backslash `\` or trailing `,` as described for control sections.

#### Boolean attributes

The attribute values `true`, `false` and `nil` are interpreted
as booleans. If you use the attribute wrapper you can omit the attribute assigment.

~~~ slim
input type="text" disabled="disabled"
input type="text" disabled=true
input(type="text" disabled)

input type="text"
input type="text" disabled=false
input type="text" disabled=nil
~~~

#### Attribute merging

You can configure attributes to be merged if multiple are given (See option `:merge_attrs`). In the default configuration
this is done for class attributes with the white space as delimiter.

~~~ slim
a.menu class="highlight" href="http://slim-lang.com/" Slim-lang.com
~~~

This renders as:

~~~ html
<a class="menu highlight" href="http://slim-lang.com/">Slim-lang.com</a>
~~~

You can also use an `Array` as attribute value and the array elements will be merged using the delimiter.

~~~ slim
a class=["menu","highlight"]
a class=:menu,:highlight
~~~

#### Splat attributes `*`

The splat shortcut allows you to turn a hash into attribute/value pairs.

~~~ slim
.card*{'data-url'=>place_path(place), 'data-id'=>place.id} = place.name
~~~

This renders as:

~~~ html
<div class="card" data-id="1234" data-url="/place/1234">Slim's house</div>
~~~

You can also use methods or instance variables which return a hash as shown here:

~~~ slim
.card *method_which_returns_hash = place.name
.card *@hash_instance_variable = place.name
~~~

The hash attributes which support attribute merging (see Slim option `:merge_attrs`) can be given as an `Array`

~~~ slim
.first *{class: [:second, :third]} Text
~~~

This renders as:

~~~ html
div class="first second third"
~~~

Splat attributes prefix may be configured via `splat_prefix` option. Default value is `'*'`

#### Dynamic tags `*`

You can create completely dynamic tags using the splat attributes. Just create a method which returns a hash
with the :tag key.

~~~ slim
ruby:
  def a_unless_current
    @page_current ? {tag: 'span'} : {tag: 'a', href: 'http://slim-lang.com/'}
  end
- @page_current = true
*a_unless_current Link
- @page_current = false
*a_unless_current Link
~~~

This renders as:

~~~ html
<span>Link</span><a href="http://slim-lang.com/">Link</a>
~~~

### Shortcuts

#### Tag shortcuts

You can define custom tag shortcuts by setting the option `:shortcut`. In Rails apps, you need to put this code for your shortcuts into an initializer like `config/initializers/slim.rb`. In Sinatra, you simply add the same configuration anywhere below the line where you `require 'slim'`.

~~~ ruby
Slim::Engine.set_options shortcut: {'c' => {tag: 'container'}, '#' => {attr: 'id'}, '.' => {attr: 'class'} }
~~~

We can use it in Slim code like this

~~~ slim
c.content Text
~~~

which renders to

~~~ html
<container class="content">Text</container>
~~~

#### Attribute shortcuts

You can define custom shortcuts (Similar to `#` for id and `.` for class).

In this example we add `&` to create a shortcut for the input elements with type attribute.

~~~ ruby
Slim::Engine.set_options shortcut: {'&' => {tag: 'input', attr: 'type'}, '#' => {attr: 'id'}, '.' => {attr: 'class'}}
~~~

We can use it in Slim code like this

~~~ slim
&text name="user"
&password name="pw"
&submit
~~~

which renders to

~~~ html
<input type="text" name="user" />
<input type="password" name="pw" />
<input type="submit" />
~~~

In another example we add `@` to create a shortcut for the role attribute.

~~~ ruby
Slim::Engine.set_options shortcut: {'@' => {attr: 'role'}, '#' => {attr: 'id'}, '.' => {attr: 'class'}}
~~~

We can use it in Slim code like this

~~~ slim
.person@admin = person.name
~~~

which renders to

~~~ html
<div class="person" role="admin">Daniel</div>
~~~

You can also set multiple attributes with same value at once using one shortcut.

~~~ ruby
Slim::Engine.set_options shortcut: {'@' => {attr: %w(data-role role)}}
~~~

We can use it in Slim code like this

~~~ slim
.person@admin = person.name
~~~

which renders to

~~~ html
<div class="person" role="admin" data-role="admin">Daniel</div>
~~~

You can also set additional fixed value attributes to a shortcut.

~~~ ruby
Slim::Engine.set_options shortcut: {'^' => {tag: 'script', attr: 'data-binding',
  additional_attrs: { type: "text/javascript" }}}
~~~

Then

~~~ slim
^products
  == @products.to_json
~~~

which renders to

~~~ html
<script data-binding="products" type="text/javascript">
[{"name": "product1", "price": "$100"},
 {"name": "prodcut2", "price": "$200"}]
</script>
~~~

#### ID shortcut `#` and class shortcut `.`

You can specify the `id` and `class` attributes in the following shortcut form

~~~ slim
body
  h1#headline
    = page_headline
  h2#tagline.small.tagline
    = page_tagline
  .content
    = show_content
~~~

This is the same as

~~~ slim
body
  h1 id="headline"
    = page_headline
  h2 id="tagline" class="small tagline"
    = page_tagline
  div class="content"
    = show_content
~~~

## Helpers, capturing and includes

If you use Slim you might want to extend your template with some helpers. Assume that you have the following helper

~~~ruby
module Helpers
  def headline(&block)
    if defined?(::Rails)
      # In Rails we have to use capture!
      "<h1>#{capture(&block)}</h1>"
    else
      # If we are using Slim without a framework (Plain Tilt),
      # this works directly.
      "<h1>#{yield}</h1>"
    end
  end
end
~~~

which is included in the scope that executes the Slim template code. The helper can then be used in the Slim template as follows

~~~ slim
p
  = headline do
    ' Hello
    = user.name
~~~

The content in the `do` block is then captured automatically and passed to the helper via `yield`. As a syntactic
sugar you can omit the `do` keyword and write only

~~~ slim
p
  = headline
    ' Hello
    = user.name
~~~

### Capturing to local variables

Using the `Binding` you can capture to local variables as follows:

~~~ruby
module Helpers
  def capture_to_local(var, &block)
    set_var = block.binding.eval("lambda {|x| #{var} = x }")
    # In Rails we have to use capture!
    # If we are using Slim without a framework (Plain Tilt),
    # you can just yield to get the captured block.
    set_var.call(defined?(::Rails) ? capture(&block) : yield)
  end
end
~~~

The helper can then be used in the Slim template as follows

~~~ slim
/ The captured_content variable must be known by the Binding beforehand.
= capture_to_local captured_content=:captured_content
  p This will be captured in the variable captured_content
= captured_content
~~~

Another interesting use case is to use an enumerable and capture for each element. The helper could look like this

~~~ ruby
module Capture
  def capture(var, enumerable = nil, &block)
    value = enumerable ? enumerable.map(&block) : yield
    block.binding.eval("lambda {|x| #{var} = x }").call(value)
    nil
  end
end
~~~

and it would be used as follows

~~~ slim
- links = { 'http://slim-lang.com' => 'The Slim Template Language' }
= capture link_list=:link_list, links do |url, text|
  a href=url = text
~~~

Afterwards, `link_list` contains the captured content.

### Include helper

If you want includes which are processed at compile time, you can take a look at [Include partials](doc/include.md).
However you can also execute subtemplates at runtime (similar to Rails' `#render`). You have to write your own include helper:

~~~ ruby
module Helpers
  def include_slim(name, options = {}, &block)
    Slim::Template.new("#{name}.slim", options).render(self, &block)
  end
end
~~~

This helper can then be used as follows

~~~ slim
nav = include_slim 'menu'
section = include_slim 'content'
~~~

However this helper doesn't do any caching. You should therefore implement a more intelligent version of the helper which
fits your purposes. You should also be aware that most frameworks already bring their own include helper, e.g. Rails has `render`.

## Text interpolation

Use standard Ruby interpolation. The text will be html escaped by default, but you can avoid escaping by using double braces.

~~~ slim
body
  h1 Welcome #{current_user.name} to the show.
  | Unescaped #{{content}} is also possible.
~~~

To escape the interpolation (i.e. render as is)

~~~ slim
body
  h1 Welcome \#{current_user.name} to the show.
~~~

## Embedded engines (Markdown, ...)

Thanks to [Tilt](https://github.com/rtomayko/tilt), Slim has extensive support for embedding other template engines.

Examples:

~~~ slim
coffee:
  square = (x) -> x * x

markdown:
  #Header
    Hello from #{"Markdown!"}
    Second Line!

p: markdown: Tag with **inline** markdown!
~~~

Supported engines:

| Filter | Required gems | Type | Description |
| ------ | ------------- | ---- | ----------- |
| ruby: | none | Shortcut | Shortcut to embed ruby code |
| javascript: | none | Shortcut | Shortcut to embed javascript code and wrap in script tag |
| css: | none | Shortcut | Shortcut to embed css code and wrap in style tag |
| sass: | sass | Compile time | Embed sass code and wrap in style tag |
| scss: | sass | Compile time | Embed scss code and wrap in style tag |
| less: | less | Compile time | Embed less css code and wrap in style tag |
| coffee: | coffee-script | Compile time | Compile coffee script code and wrap in script tag |
| markdown: | redcarpet/rdiscount/kramdown | Compile time + Interpolation | Compile markdown code and interpolate #\{variables} in text |
| textile: | redcloth | Compile time + Interpolation | Compile textile code and interpolate #\{variables} in text |
| rdoc: | rdoc | Compile time + Interpolation | Compile rdoc code and interpolate #\{variables} in text |

The embedded engines can be configured in Slim by setting the options directly on the `Slim::Embedded` filter. Example:

~~~ ruby
Slim::Embedded.options[:markdown] = {auto_ids: false}
~~~

You can also specify HTML attributes for the following embedded engines:
* Javascript
* CSS
* CoffeeScript
* LESS
* SASS
* SCSS

Example:

~~~ scss
scss class="myClass":
  $color: #f00;
  body { color: $color; }
~~~

This will generate the following HTML:

~~~ html
<style class="myClass" type="text/css">body{color:red}</style>
~~~

## Configuring Slim

Slim and the underlying [Temple](https://github.com/judofyr/temple) framework are highly configurable.
The way how you configure Slim depends a bit on the compilation mechanism (Rails or [Tilt](https://github.com/rtomayko/tilt)). It is always possible to set default options per `Slim::Engine` class. This can be done in Rails' environment files. For instance, in config/environments/development.rb you probably want:

### Default options

~~~ ruby
# Indent html for pretty debugging and do not sort attributes
Slim::Engine.set_options pretty: true, sort_attrs: false
~~~

You can also access the option hash directly:

~~~ ruby
Slim::Engine.options[:pretty] = true
~~~

### Setting options at runtime

There are two ways to set options at runtime. For Tilt templates (`Slim::Template`) you can set
the options when you instantiate the template:

~~~ ruby
Slim::Template.new('template.slim', optional_option_hash).render(scope)
~~~

The other possibility is to set the options per thread which is interesting mostly for Rails:

~~~ ruby
Slim::Engine.with_options(option_hash) do
  # Any Slim engines which are created here use the option_hash
  # For example in Rails:
  render :page, layout: true
end
~~~

You have to be aware that the compiled engine code and the options are cached per template in Rails and you cannot change the option afterwards.

~~~ ruby
# First render call
Slim::Engine.with_options(pretty: true) do
   render :page, layout: true
end

# Second render call
Slim::Engine.with_options(pretty: false) do
   render :page, layout: true # :pretty is still true because it is cached
end
~~~

### Available options

The following options are exposed by the `Slim::Engine` and can be set with `Slim::Engine.set_options`.
There are a lot of them but the good thing is, that Slim checks the configuration keys and reports an error if you try to use an invalid configuration key.


| Type | Name | Default | Purpose |
| ---- | ---- | ------- | ------- |
| String | :file | nil | Name of parsed file, set automatically by Slim::Template |
| Integer | :tabsize | 4 | Number of white spaces per tab (used by the parser) |
| String | :encoding | "utf-8" | Set encoding of template |
| String | :default_tag | "div" | Default tag to be used if tag name is omitted |
| Hash | :shortcut | \{'.' => {attr: 'class'}, '#' => {attr: 'id'}} | Attribute shortcuts |
| Hash | :code_attr_delims | \{'(' => ')', '[' => ']', '{' => '}'} | Attribute delimiters for Ruby code attributes |
| Hash | :attr_list_delims | \{'(' => ')', '[' => ']', '{' => '}'} | Attribute list delimiter |
| Array&lt;Symbol,String&gt; | :enable_engines | nil <i>(All enabled)</i> | List of enabled embedded engines (whitelist) |
| Array&lt;Symbol,String&gt; | :disable_engines | nil <i>(None disabled)</i> | List of disabled embedded engines (blacklist) |
| Boolean | :disable_capture | false (true in Rails) | Disable capturing in blocks (blocks write to the default buffer  |
| Boolean | :disable_escape | false | Disable automatic escaping of strings |
| Boolean | :use_html_safe | false (true in Rails) | Use String#html_safe? from ActiveSupport (Works together with :disable_escape) |
| Symbol | :format | :xhtml | HTML output format (Possible formats :html, :xhtml, :xml) |
| String | :attr_quote | '"' | Character to wrap attributes in html (can be ' or ") |
| Hash | :merge_attrs | \{'class' => ' '} | Joining character used if multiple html attributes are supplied (e.g. class="class1 class2") |
| Array&lt;String&gt; | :hyphen_attrs | %w(data) | Attributes which will be hyphenated if a Hash is given (e.g. data={a:1,b:2} will render as data-a="1" data-b="2") |
| Boolean | :sort_attrs | true | Sort attributes by name |
| Symbol | :js_wrapper | nil | Wrap javascript by :comment, :cdata or :both. You can also :guess the wrapper based on :format. |
| Boolean | :pretty | false | Pretty HTML indenting, only block level tags are indented <b>(This is slower!)</b> |
| String | :indent | '  ' | Indentation string |
| Boolean | :streaming | false (true in Rails, see below how to disable it!) | Enable output streaming, improves the perceived performance |
| Class | :generator | Temple::Generators::StringBuffer/ RailsOutputBuffer | Temple code generator (default generator generates string buffer) |
| String | :buffer | '_buf' ('@output_buffer' in Rails) | Variable used for buffer |
| String | :splat_prefix | '*' | Prefix used for splat attributes |

There are more options which are supported by the Temple filters but which are not exposed and are not officially supported. You
have to take a look at the Slim and Temple code for that.

### Option priority and inheritance

For developers who know more about Slim and Temple architecture it is possible to override default
options at different positions. Temple uses an inheritance mechanism to allow subclasses to override
options of the superclass. The option priorities are as follows:

1. `Slim::Template` options passed at engine instantiation
2. `Slim::Template.options`
3. `Slim::Engine.thread_options`, `Slim::Engine.options`
5. Parser/Filter/Generator `thread_options`, `options` (e.g `Slim::Parser`, `Slim::Compiler`)

It is also possible to set options for superclasses like `Temple::Engine`. But this will affect all temple template engines then.

~~~ ruby
Slim::Engine < Temple::Engine
Slim::Compiler < Temple::Filter
~~~

## Plugins

Slim currently provides plugins for logic less mode, includes and I18n. See the plugin documentation.

* [Logic less mode](doc/logic_less.md)
* [Include partials](doc/include.md)
* [Translator/I18n](doc/translator.md)
* [Smart text mode](doc/smart.md)

## Framework support

### Tilt

Slim uses [Tilt](https://github.com/rtomayko/tilt) to compile the generated code. If you want to use the Slim template directly, you can use the Tilt interface.

~~~ ruby
Tilt.new['template.slim'].render(scope)
Slim::Template.new('template.slim', optional_option_hash).render(scope)
Slim::Template.new(optional_option_hash) { source }.render(scope)
~~~

The optional option hash can have to options which were documented in the section above. The scope is the object in which the template
code is executed.

### Sinatra

~~~ ruby
require 'sinatra'
require 'slim'

get('/') { slim :index }

 __END__
@@ index
doctype html
html
  head
    title Sinatra With Slim
  body
    h1 Slim Is Fun!
~~~

### Rails

Rails generators are provided by [slim-rails](https://github.com/slim-template/slim-rails). slim-rails
is not necessary to use Slim in Rails though. Just install Slim and add it to your Gemfile with `gem 'slim'`.
Then just use the .slim extension and you're good to go.

#### Streaming

HTTP streaming is enabled by default if you use a Rails version which supports it. However you have to be aware that streaming only improves the perceived
performance. The rendering time in total will increase. If you want to disable it use:

~~~ ruby
Slim::RailsTemplate.set_options streaming: false
~~~

### Angular2

Slim now supports Angular2 syntax. But you need to set some configuration options:

#### `splat_prefix` option

This option tells parser what syntax to use for splat attributes.
Default value is asterisk: `splat_prefix: '*'`
Asterisk is also used in Angular2 for structural directives such as `*ngIf` and others, so default configuration causes a conflict between slim and angular2 syntax.

There are two ways to resolve it:

* Set `splat_prefix` to any custom value, double asterisk, for example: `splat_prefix: '**'`. Now structural directives should work as expected. Remember that now splat attributes should be written with new custom prefix before them.
* Use alternative directive syntax without asterisk.

#### Attribute delimeters

Angular and slim both uses brackets in their syntax. So there are also two ways:
* Use alternative syntax for binding (`bind-...` and so on)
* Limit attribute delimeters to curly braces only:
```
code_attr_delims: {
 '{' => '}',
},
attr_list_delims: {
 '{' => '}',
},
```

Now you can use something like this:
```
h1{ #var (bind1)="test" [bind2]="ok" [(bind3)]="works?" *ngIf="expr" *ngFor="expression" } {{it works}}
```

Will be compiled to:
```
<h1 #var="" (bind1)="test" [bind2]="ok" [(bind3)]="works?" *ngIf="expr" *ngFor="expression">
  {{it works}}
</h1>
```

## Tools

### Slim Command 'slimrb'

The gem 'slim' comes with the small tool 'slimrb' to test Slim from the command line.

<pre>
$ slimrb --help
Usage: slimrb [options]
    -s, --stdin                      Read input from standard input instead of an input file
        --trace                      Show a full traceback on error
    -c, --compile                    Compile only but do not run
    -e, --erb                        Convert to ERB
        --rails                      Generate rails compatible code (Implies --compile)
    -r, --require library            Load library or plugin with -r slim/plugin
    -p, --pretty                     Produce pretty html for debugging purposes
    -o, --option name=code           Set slim option
    -l, --locals Hash|YAML|JSON      Set local variables
    -h, --help                       Show this message
    -v, --version                    Print version
</pre>

Start 'slimrb', type your code and press Ctrl-d to send EOF. In Windows Command Prompt press Ctrl-z, Enter to send EOF.  Example usage:

<pre>
$ slimrb
markdown:
  First paragraph.

  Second paragraph.

  * one
  * two
  * three

//Enter Ctrl-d
&lt;p&gt;First paragraph &lt;/p&gt;

&lt;p&gt;Second paragraph &lt;/p&gt;

&lt;ul&gt;
&lt;li&gt;one&lt;/li&gt;
&lt;li&gt;two&lt;/li&gt;
&lt;li&gt;three&lt;/li&gt;
&lt;/ul&gt;
</pre>

### Syntax Highlighters

There are plugins for various text editors (including the most important ones - Vim, Emacs and Textmate):

* [Vim](https://github.com/slim-template/vim-slim)
* [Emacs](https://github.com/slim-template/emacs-slim)
* [Textmate / Sublime Text](https://github.com/slim-template/ruby-slim.tmbundle)
* [Espresso text editor](https://github.com/slim-template/Slim-Sugar)
* [Coda](https://github.com/slim-template/Coda-2-Slim.mode)
* [Atom](https://github.com/slim-template/language-slim)

### Template Converters (HAML, ERB, ...)

* Slim can be converted to ERB using `slimrb` or `Slim::ERBConverter' which are both included in the Slim gem
* [Haml2Slim converter](https://github.com/slim-template/haml2slim)
* [ERB2Slim, HTML2Slim converter](https://github.com/slim-template/html2slim)

## Testing

### Benchmarks

  *Yes, Slim is one of the fastest Ruby template engines out there!
   In production mode Slim is nearly as fast as Erubis (which is the fastest template engine).
   But we would be happy if you chose Slim also for any other reason, we assure
   you performance will not be an obstacle.*

Run the benchmarks with `rake bench`. You can add the option `slow` to
run the slow parsing benchmark which needs more time. You can also increase the number of iterations.

~~~
$ rake bench slow=1 iterations=1000
~~~

We run the benchmarks for every commit on Travis-CI. Take a look at the newest benchmarking results: <http://travis-ci.org/slim-template/slim>

### Test suite and continuous integration

Slim provides an extensive test-suite based on minitest. You can run the tests
with 'rake test' and the rails integration tests with 'rake test:rails'.

We are currently experimenting with human-readable literate tests which are written as markdown files: [TESTS.md](test/literate/TESTS.md)

Travis-CI is used for continuous integration testing: <http://travis-ci.org/slim-template/slim>

Slim is working well on all major Ruby implementations:

* Ruby 2.0, 2.1, 2.2 and 2.3
* JRuby 1.9 mode
* Rubinius 2.0

## Contributing

If you'd like to help improve Slim, clone the project with Git by running:

~~~
$ git clone git://github.com/slim-template/slim
~~~

Work your magic and then submit a pull request. We love pull requests!

Please remember to keep the compatibility with Ruby versions 2.0.0, 2.1.0, 2.2.0 and 2.3.0.

If you find the documentation lacking, help us out and update this README.md. If you don't have the time to work on Slim, but found something we should know about, please submit an issue.

## License

Slim is released under the [MIT license](http://www.opensource.org/licenses/MIT).

## Authors

* [Daniel Mendler](https://github.com/minad) (Lead developer)
* [Andrew Stone](https://github.com/stonean)
* [Fred Wu](https://github.com/fredwu)

## Donations and sponsoring

If you want to support this project please visit the Gittip and Flattr pages.

[![Gittip donate button](https://img.shields.io/gratipay/bevry.svg)](https://www.gittip.com/min4d/ "Donate weekly to this project using Gittip")
[![Flattr donate button](https://raw.github.com/balupton/flattr-buttons/master/badge-89x18.gif)](https://flattr.com/submit/auto?user_id=min4d&url=http%3A%2F%2Fslim-lang.org%2F "Donate monthly to this project using Flattr")

Currently the donations will be used to cover the hosting costs (domain name etc).

## Discuss

* [Google Group](http://groups.google.com/group/slim-template)

## Related projects

Template compilation framework:

* [Temple](https://github.com/judofyr/temple)

Framework support:

* [Rails generators (slim-rails)](https://github.com/slim-template/slim-rails)
  * [slimkeyfy - Translation string extraction](https://github.com/phrase/slimkeyfy)

Syntax highlighting:

* [Vim](https://github.com/slim-template/vim-slim)
* [Emacs](https://github.com/slim-template/emacs-slim)
* [Textmate / Sublime Text](https://github.com/slim-template/ruby-slim.tmbundle)
* [Espresso text editor](https://github.com/slim-template/Slim-Sugar)
* [Coda](https://github.com/slim-template/Coda-2-Slim.mode)
* [Atom](https://github.com/slim-template/language-slim)

Static code analysis:

* [Slim-Lint](https://github.com/sds/slim-lint)
* [SublimeLinter-slim-lint](https://github.com/elstgav/SublimeLinter-slim-lint)

Template Converters (HAML, ERB, ...):

* [ERB 2 Slim](http://erb2slim.com/)
* [Haml2Slim converter](https://github.com/slim-template/haml2slim)
* [ERB2Slim, HTML2Slim converter](https://github.com/slim-template/html2slim)

Language ports/Similar languages:

* [Sliq (Slim/Liquid integration)](https://github.com/slim-template/sliq)
* [Slm (Slim port to Javascript)](https://github.com/slm-lang/slm)
* [Coffee script plugin for Slim](https://github.com/yury/coffee-views)
* [Clojure port of Slim](https://github.com/chaslemley/slim.clj)
* [Hamlet.rb (Similar template language)](https://github.com/gregwebs/hamlet.rb)
* [Plim (Python port of Slim)](https://github.com/2nd/plim)
* [Skim (Slim for Javascript)](https://github.com/jfirebaugh/skim)
* [Emblem.js (Javascript, similar to Slim)](https://github.com/machty/emblem.js)
* [Hamlit (High performance Haml implementation, based on Temple like Slim)](https://github.com/k0kubun/hamlit)
* [Faml (Faster Haml implementation, also using Temple like Slim)](https://github.com/eagletmt/faml)
* [Haml (Older engine which inspired Slim)](https://github.com/haml/haml)
* [Jade (Similar engine for javascript)](https://github.com/visionmedia/jade)
* [Pug (Successor of Jade, Similar engine for javascript)](https://github.com/pugjs/pug)
* [Sweet (Similar engine which also allows to write classes and functions)](https://github.com/joaomdmoura/sweet)
* [Amber (Similar engine for Go)](https://github.com/eknkc/amber)
* [Slang (Slim-inspired templating language for Crystal)](https://github.com/jeromegn/slang)
