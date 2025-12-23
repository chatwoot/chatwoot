# CommonMarker

![Build Status](https://github.com/gjtorikian/commonmarker/workflows/CI/badge.svg) [![Gem Version](https://badge.fury.io/rb/commonmarker.svg)](http://badge.fury.io/rb/commonmarker)

Ruby wrapper for [libcmark-gfm](https://github.com/github/cmark),
GitHub's fork of the reference parser for CommonMark. It passes all of the C tests, and is therefore spec-complete. It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

For more information on available extensions, see [the documentation below](#extensions).

## Installation

Add this line to your application's Gemfile:

    gem 'commonmarker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install commonmarker

## Usage

### Converting to HTML

Call `render_html` on a string to convert it to HTML:

``` ruby
require 'commonmarker'
CommonMarker.render_html('Hi *there*', :DEFAULT)
# <p>Hi <em>there</em></p>\n
```

The second argument is optional--[see below](#options) for more information.

### Generating a document

You can also parse a string to receive a `Document` node. You can then print that node to HTML, iterate over the children, and other fun node stuff. For example:

``` ruby
require 'commonmarker'

doc = CommonMarker.render_doc('*Hello* world', :DEFAULT)
puts(doc.to_html) # <p>Hi <em>there</em></p>\n

doc.walk do |node|
  puts node.type # [:document, :paragraph, :text, :emph, :text]
end
```

The second argument is optional--[see below](#options) for more information.

#### Example: walking the AST

You can use `walk` or `each` to iterate over nodes:

- `walk` will iterate on a node and recursively iterate on a node's children.
- `each` will iterate on a node and its children, but no further.

``` ruby
require 'commonmarker'

# parse the files specified on the command line
doc = CommonMarker.render_doc("# The site\n\n [GitHub](https://www.github.com)")

# Walk tree and print out URLs for links
doc.walk do |node|
  if node.type == :link
    printf("URL = %s\n", node.url)
  end
end

# Capitalize all regular text in headers
doc.walk do |node|
  if node.type == :header
    node.each do |subnode|
      if subnode.type == :text
        subnode.string_content = subnode.string_content.upcase
      end
    end
  end
end

# Transform links to regular text
doc.walk do |node|
  if node.type == :link
    node.insert_before(node.first_child)
    node.delete
  end
end
```

### Creating a custom renderer

You can also derive a class from CommonMarker's `HtmlRenderer` class. This produces slower output, but is far more customizable. For example:

``` ruby
class MyHtmlRenderer < CommonMarker::HtmlRenderer
  def initialize
    super
    @headerid = 1
  end

  def header(node)
    block do
      out("<h", node.header_level, " id=\"", @headerid, "\">",
               :children, "</h", node.header_level, ">")
      @headerid += 1
    end
  end
end

myrenderer = MyHtmlRenderer.new
puts myrenderer.render(doc)

# Print any warnings to STDERR
renderer.warnings.each do |w|
  STDERR.write("#{w}\n")
end
```

## Options

CommonMarker accepts the same options that CMark does, as symbols. Note that there is a distinction in CMark for "parse" options and "render" options, which are represented in the tables below.

### Parse options

| Name                          | Description
| ----------------------------- | -----------
| `:DEFAULT`                    | The default parsing system.
| `:SOURCEPOS`                  | Include source position in nodes
| `:UNSAFE`                     | Allow raw/custom HTML and unsafe links.
| `:VALIDATE_UTF8`              | Replace illegal sequences with the replacement character `U+FFFD`.
| `:SMART`                      | Use smart punctuation (curly quotes, etc.).
| `:LIBERAL_HTML_TAG`           | Support liberal parsing of inline HTML tags.
| `:FOOTNOTES`                  | Parse footnotes.
| `:STRIKETHROUGH_DOUBLE_TILDE` | Parse strikethroughs by double tildes (compatibility with [redcarpet](https://github.com/vmg/redcarpet))

### Render options

| Name                             | Description                                                     |
| ------------------               | -----------                                                     |
| `:DEFAULT`                       | The default rendering system.                                   |
| `:SOURCEPOS`                     | Include source position in rendered HTML.                       |
| `:HARDBREAKS`                    | Treat `\n` as hardbreaks (by adding `<br/>`).                   |
| `:UNSAFE`                        | Allow raw/custom HTML and unsafe links.                         |
| `:NOBREAKS`                      | Translate `\n` in the source to a single whitespace.            |
| `:VALIDATE_UTF8`                 | Replace illegal sequences with the replacement character `U+FFFD`. |
| `:SMART`                         | Use smart punctuation (curly quotes, etc.).                     |
| `:GITHUB_PRE_LANG`               | Use GitHub-style `<pre lang>` for fenced code blocks.           |
| `:LIBERAL_HTML_TAG`              | Support liberal parsing of inline HTML tags.                    |
| `:FOOTNOTES`                     | Render footnotes.                                               |
| `:STRIKETHROUGH_DOUBLE_TILDE`    | Parse strikethroughs by double tildes (compatibility with [redcarpet](https://github.com/vmg/redcarpet)) |
| `:TABLE_PREFER_STYLE_ATTRIBUTES` | Use `style` insted of `align` for table cells.                  |
| `:FULL_INFO_STRING`              | Include full info strings of code blocks in separate attribute. |

### Passing options

To apply a single option, pass it in as a symbol argument:

``` ruby
CommonMarker.render_doc("\"Hello,\" said the spider.", :SMART)
# <p>“Hello,” said the spider.</p>\n
```

To have multiple options applied, pass in an array of symbols:

``` ruby
CommonMarker.render_html("\"'Shelob' is my name.\"", [:HARDBREAKS, :SOURCEPOS])
```

For more information on these options, see [the CMark documentation](https://git.io/v7nh1).

## Extensions

Both `render_html` and `render_doc` take an optional third argument defining the extensions you want enabled as your CommonMark document is being processed. The documentation for these extensions are [defined in this spec](https://github.github.com/gfm/), and the rationale is provided [in this blog post](https://githubengineering.com/a-formal-spec-for-github-markdown/).

The available extensions are:

* `:table` - This provides support for tables.
* `:tasklist` - This provides support for task list items.
* `:strikethrough` - This provides support for strikethroughs.
* `:autolink` - This provides support for automatically converting URLs to anchor tags.
* `:tagfilter` - This escapes [several "unsafe" HTML tags](https://github.github.com/gfm/#disallowed-raw-html-extension-), causing them to not have any effect.

## Output formats

Like CMark, CommonMarker can generate output in several formats: HTML, XML, plaintext, and commonmark are currently supported.

### HTML

The default output format, HTML, will be generated when calling `to_html` or using `--to=html` on the command line.

```ruby
doc = CommonMarker.render_doc('*Hello* world!', :DEFAULT)
puts(doc.to_html)

<p><em>Hello</em> world!</p>
```

### XML

XML will be generated when calling `to_xml` or using `--to=xml` on the command line.

```ruby
doc = CommonMarker.render_doc('*Hello* world!', :DEFAULT)
puts(doc.to_xml)

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE document SYSTEM "CommonMark.dtd">
<document xmlns="http://commonmark.org/xml/1.0">
  <paragraph>
    <emph>
      <text xml:space="preserve">Hello</text>
    </emph>
    <text xml:space="preserve"> world!</text>
  </paragraph>
</document>
```

### Plaintext

Plaintext will be generated when calling `to_plaintext` or using `--to=plaintext` on the command line.

```ruby
doc = CommonMarker.render_doc('*Hello* world!', :DEFAULT)
puts(doc.to_plaintext)

Hello world!
```

### Commonmark

Commonmark will be generated when calling `to_commonmark` or using `--to=commonmark` on the command line.

``` ruby
text = <<-TEXT
1. I am a numeric list.
2. I continue the list.
* Suddenly, an unordered list!
* What fun!
TEXT

doc = CommonMarker.render_doc(text, :DEFAULT)
puts(doc.to_commonmark)

1.  I am a numeric list.
2.  I continue the list.

<!-- end list -->

  - Suddenly, an unordered list\!
  - What fun\!
```

## Developing locally

After cloning the repo:

```
script/bootstrap
bundle exec rake compile
```

If there were no errors, you're done! Otherwise, make sure to follow the CMark dependency instructions.

## Benchmarks

Some rough benchmarks:

```
$ bundle exec rake benchmark

input size = 11063727 bytes

redcarpet
  0.070000   0.020000   0.090000 (  0.079641)
github-markdown
  0.070000   0.010000   0.080000 (  0.083535)
commonmarker with to_html
  0.100000   0.010000   0.110000 (  0.111947)
commonmarker with ruby HtmlRenderer
  1.830000   0.030000   1.860000 (  1.866203)
kramdown
  4.610000   0.070000   4.680000 (  4.678398)
```
