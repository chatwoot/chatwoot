# Summary

Transform html into markdown. Useful for example if you want to import html into your markdown based application.

[![Build Status](https://secure.travis-ci.org/xijo/reverse_markdown.svg?branch=master)](https://travis-ci.org/xijo/reverse_markdown) [![Gem Version](https://badge.fury.io/rb/reverse_markdown.svg)](http://badge.fury.io/rb/reverse_markdown) [![Code Climate](https://codeclimate.com/github/xijo/reverse_markdown.svg)](https://codeclimate.com/github/xijo/reverse_markdown) [![Code Climate](https://codeclimate.com/github/xijo/reverse_markdown/coverage.png)](https://codeclimate.com/github/xijo/reverse_markdown)

## Changelog

See [Change Log](CHANGELOG.md)

## Requirements

1. [Nokogiri](http://nokogiri.org/)
2. Ruby 2.0.0 or higher

## Installation

Install the gem

```sh
[sudo] gem install reverse_markdown
```

or add it to your Gemfile

```ruby
gem 'reverse_markdown'
```

## Features

- Supports all the established html tags like `h1`, `h2`, `h3`, `h4`, `h5`, `h6`, `p`, `em`, `strong`, `i`, `b`, `blockquote`, `code`, `img`, `a`, `hr`, `li`, `ol`, `ul`, `table`, `tr`, `th`, `td`, `br`, `figure`
- Module based - if you miss a tag, just add it
- Can deal with nested lists
- Inline and block code is supported
- Supports blockquote


# Usage

## Ruby

You can convert html content as string or Nokogiri document:

```ruby
input  = '<strong>feelings</strong>'
result = ReverseMarkdown.convert input
result.inspect # " **feelings** "
````

## Commandline

It's also possible to convert html files to markdown using the binary:

```sh
$ reverse_markdown file.html > file.md
$ cat file.html | reverse_markdown > file.md
````

## Configuration

The following options are available:

- `unknown_tags` (default `pass_through`) - how to handle unknown tags. Valid options are:
  - `pass_through` - Include the unknown tag completely into the result
  - `drop` - Drop the unknown tag and its content
  - `bypass` - Ignore the unknown tag but try to convert its content
  - `raise` - Raise an error to let you know
- `github_flavored` (default `false`) - use [github flavored markdown](https://help.github.com/articles/github-flavored-markdown) (yet only code blocks are supported)
- `tag_border` (default `' '`) - how to handle tag borders. valid options are:
  - `' '` - Add whitespace if there is none at tag borders.
  - `''` - Do not not add whitespace.

### As options

Just pass your chosen configuration options in after the input. The given options will last for this operation only.

```ruby
ReverseMarkdown.convert(input, unknown_tags: :raise, github_flavored: true)
```

### Preconfigure

Or configure it block style on a initializer level. These configurations will last for all conversions until they are set to something different.

```ruby
ReverseMarkdown.config do |config|
  config.unknown_tags     = :bypass
  config.github_flavored  = true
  config.tag_border  = ''
end
```


# Related stuff

- [Write custom converters](https://github.com/xijo/reverse_markdown/wiki/Write-your-own-converter) - Wiki entry about how to write your own converter
- [html_massage](https://github.com/harlantwood/html_massage) - A gem by Harlan T. Wood to convert regular sites into markdown using reverse_markdown
- [word-to-markdown](https://github.com/benbalter/word-to-markdown) - Convert word docs into markdown while using reverse_markdown, by Ben Balter
- [markdown syntax](http://daringfireball.net/projects/markdown) - The markdown syntax specification
- [github flavored markdown](https://help.github.com/articles/github-flavored-markdown) - Githubs extension to markdown
- [wmd-editor](http://wmd-editor.com) - Markdown flavored text editor


# Thanks

Thanks to all [contributors](https://github.com/xijo/reverse_markdown/graphs/contributors) and all other helpers:

- [Empact](https://github.com/Empact) Ben Woosley
- [harlantwood](https://github.com/harlantwood) Harlan T. Wood
- [aprescott](https://github.com/aprescott) Adam Prescott
- [danschultzer](https://github.com/danschultzer) Dan Schultzer
- [Benjamin-Dobell](https://github.com/Benjamin-Dobell) Benjamin Dobell
- [schkovich](https://github.com/schkovich) Goran Miskovic
- [craig-day](https://github.com/craig-day) Craig Day
- [grmartin](https://github.com/grmartin) Glenn R. Martin
- [willglynn](https://github.com/willglynn) Will Glynn
