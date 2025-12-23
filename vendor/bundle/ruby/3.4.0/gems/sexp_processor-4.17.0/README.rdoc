= SexpProcessor

home :: https://github.com/seattlerb/sexp_processor
rdoc :: http://docs.seattlerb.org/sexp_processor

== DESCRIPTION:

sexp_processor branches from ParseTree bringing all the generic sexp
processing tools with it. Sexp, SexpProcessor, Environment, etc... all
for your language processing pleasure.

== FEATURES/PROBLEMS:

* Includes SexpProcessor and CompositeSexpProcessor.

  * Allows you to write very clean filters.

* Includes MethodBasedSexpProcessor

  * Makes writing language processors even easier!

* Sexp provides a simple and clean interface to creating and manipulating ASTs.

  * Includes new pattern matching system.

== SYNOPSIS:

You can use SexpProcessor to do all kinds of language processing. Here
is a simple example of a simple documentation printer:

  class ArrrDoc < MethodBasedSexpProcessor
    def process_class exp
      super do
        puts "#{self.klass_name}: #{exp.comments}"
      end
    end

    def process_defn exp
      super do
        args, *_body = exp

        puts "#{self.method_name}(#{process_args args}): #{exp.comments}"
      end
    end
  end

Sexp provides a lot of power with the new pattern matching system.
Here is an example that parses all the test files using RubyParser and
then quickly finds all the test methods and prints their names:

  >> require "ruby_parser";
  >> rp = RubyParser.new;
  >> matcher = Sexp::Matcher.parse "(defn [m /^test_/] ___)"
  => q(:defn, m(/^test_/), ___)
  >> paths = Dir["test/**/*.rb"];
  >> sexps = s(:block, *paths.map { |path| rp.process File.read(path), path });
  >> (sexps / matcher).size
  => 189
  ?> (sexps / matcher).map { |(_, name, *_rest)| name }.sort
  => [:test_all, :test_amp, :test_and_satisfy_eh, :test_any_search, ...]

== REQUIREMENTS:

* rubygems

== INSTALL:

* sudo gem install sexp_processor

== LICENSE:

(The MIT License)

Copyright (c) Ryan Davis, seattle.rb

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
