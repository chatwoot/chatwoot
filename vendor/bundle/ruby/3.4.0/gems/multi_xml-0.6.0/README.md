# MultiXML

[![Gem Version](http://img.shields.io/gem/v/multi_xml.svg)][gem]
[![Build Status](http://img.shields.io/travis/sferik/multi_xml.svg)][travis]
[![Dependency Status](http://img.shields.io/gemnasium/sferik/multi_xml.svg)][gemnasium]
[![Code Climate](http://img.shields.io/codeclimate/github/sferik/multi_xml.svg)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/sferik/multi_xml.svg)][coveralls]

[gem]: https://rubygems.org/gems/multi_xml
[travis]: http://travis-ci.org/sferik/multi_xml
[gemnasium]: https://gemnasium.com/sferik/multi_xml
[codeclimate]: https://codeclimate.com/github/sferik/multi_xml
[coveralls]: https://coveralls.io/r/sferik/multi_xml

A generic swappable back-end for XML parsing

## Installation
    gem install multi_xml

## Documentation
[http://rdoc.info/gems/multi_xml][documentation]

[documentation]: http://rdoc.info/gems/multi_xml

## Usage Examples
Lots of Ruby libraries utilize XML parsing in some form, and everyone has their
favorite XML library. In order to best support multiple XML parsers and
libraries, `multi_xml` is a general-purpose swappable XML backend library. You
use it like so:
```ruby
require 'multi_xml'

MultiXml.parser = :ox
MultiXml.parser = MultiXml::Parsers::Ox # Same as above
MultiXml.parse('<tag>This is the contents</tag>') # Parsed using Ox

MultiXml.parser = :libxml
MultiXml.parser = MultiXml::Parsers::Libxml # Same as above
MultiXml.parse('<tag>This is the contents</tag>') # Parsed using LibXML

MultiXml.parser = :nokogiri
MultiXml.parser = MultiXml::Parsers::Nokogiri # Same as above
MultiXml.parse('<tag>This is the contents</tag>') # Parsed using Nokogiri

MultiXml.parser = :rexml
MultiXml.parser = MultiXml::Parsers::Rexml # Same as above
MultiXml.parse('<tag>This is the contents</tag>') # Parsed using REXML

MultiXml.parser = :oga
MultiXml.parser = MultiXml::Parsers::Oga # Same as above
MultiXml.parse('<tag>This is the contents</tag>') # Parsed using Oga
```
The `parser` setter takes either a symbol or a class (to allow for custom XML
parsers) that responds to `.parse` at the class level.

MultiXML tries to have intelligent defaulting. That is, if you have any of the
supported parsers already loaded, it will utilize them before attempting to
load any. When loading, libraries are ordered by speed: first Ox, then LibXML,
then Nokogiri, and finally REXML.

## Supported Ruby Versions
This library aims to support and is [tested against][travis] the following Ruby
implementations:

* Ruby 1.9.3
* Ruby 2.0.0
* Ruby 2.1
* Ruby 2.2
* Ruby 2.3
* [JRuby 9000][jruby]

[jruby]: http://jruby.org/

If something doesn't work on one of these interpreters, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby
implementations, however support will only be provided for the versions listed
above.

If you would like this library to support another Ruby version, you may
volunteer to be a maintainer. Being a maintainer entails making sure all tests
run and pass on that implementation. When something breaks on your
implementation, you will be responsible for providing patches in a timely
fashion. If critical issues for a particular implementation exist at the time
of a major release, support for that Ruby version may be dropped.

## Inspiration
MultiXML was inspired by [MultiJSON][].

[multijson]: https://github.com/intridea/multi_json/

## Copyright
Copyright (c) 2010-2013 Erik Michaels-Ober. See [LICENSE][] for details.

[license]: LICENSE.md
