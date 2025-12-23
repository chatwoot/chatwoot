HighLine
========

[![Tests](https://github.com/JEG2/highline/actions/workflows/ci.yml/badge.svg)](https://github.com/JEG2/highline/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/highline.svg)](https://badge.fury.io/rb/highline)
[![Code Climate](https://codeclimate.com/github/JEG2/highline/badges/gpa.svg)](https://codeclimate.com/github/JEG2/highline)
[![Test Coverage](https://codeclimate.com/github/JEG2/highline/badges/coverage.svg)](https://codeclimate.com/github/JEG2/highline/coverage)
[![Inline docs](http://inch-ci.org/github/JEG2/highline.svg?branch=master)](http://inch-ci.org/github/JEG2/highline)

Description
-----------

Welcome to HighLine.

HighLine was designed to ease the tedious tasks of doing console input and
output with low-level methods like ```gets``` and ```puts```. HighLine provides a
robust system for requesting data from a user, without needing to code all the
error checking and validation rules and without needing to convert the typed
Strings into what your program really needs.  Just tell HighLine what you're
after, and let it do all the work.

Documentation
-------------

See: [Rubydoc.info for HighLine](http://www.rubydoc.info/github/JEG2/highline/master).
Specially [HighLine](http://www.rubydoc.info/github/JEG2/highline/master/HighLine) and [HighLine::Question](http://www.rubydoc.info/github/JEG2/highline/master/HighLine/Question).

Usage
-----

```ruby

require 'highline'

# Basic usage

cli = HighLine.new
answer = cli.ask "What do you think?"
puts "You have answered: #{answer}"


# Default answer

cli.ask("Company?  ") { |q| q.default = "none" }


# Validation

cli.ask("Age?  ", Integer) { |q| q.in = 0..105 }
cli.ask("Name?  (last, first)  ") { |q| q.validate = /\A\w+, ?\w+\Z/ }


# Type conversion for answers:

cli.ask("Birthday?  ", Date)
cli.ask("Interests?  (comma sep list)  ", lambda { |str| str.split(/,\s*/) })


# Reading passwords:

cli.ask("Enter your password:  ") { |q| q.echo = false }
cli.ask("Enter your password:  ") { |q| q.echo = "x" }


# ERb based output (with HighLine's ANSI color tools):

cli.say("This should be <%= color('bold', BOLD) %>!")


# Menus:

cli.choose do |menu|
  menu.prompt = "Please choose your favorite programming language?  "
  menu.choice(:ruby) { cli.say("Good choice!") }
  menu.choices(:python, :perl) { cli.say("Not from around here, are you?") }
  menu.default = :ruby
end

## Using colored indices on Menus

HighLine::Menu.index_color   = :rgb_77bbff # set default index color

cli.choose do |menu|
  menu.index_color  = :rgb_999999      # override default color of index
                                       # you can also use constants like :blue
  menu.prompt = "Please choose your favorite programming language?  "
  menu.choice(:ruby) { cli.say("Good choice!") }
  menu.choices(:python, :perl) { cli.say("Not from around here, are you?") }
end
```

If you want to save some characters, you can inject/import HighLine methods on Kernel by doing the following. Just be sure to avoid name collisions in the top-level namespace.


```ruby
require 'highline/import'

say "Now you can use #say directly"
```

For more examples see the examples/ directory of this project.

Requirements
------------

HighLine from version >= 1.7.0 requires ruby >= 1.9.3

Installing
----------

To install HighLine, use the following command:

```sh
$ gem install highline
```

(Add `sudo` if you're installing under a POSIX system as root)

If you're using [Bundler](http://bundler.io/), add this to your Gemfile:

```ruby
source "https://rubygems.org"
gem 'highline'
```

And then run:

```sh
$ bundle
```

If you want to build the gem locally, use the following command from the root of the sources:

```sh
$ rake package
```

You can also build and install directly:

```sh
$ rake install
```

Contributing
------------

1. Open an issue
  - https://github.com/JEG2/highline/issues

2. Fork the repository
  - https://github.com/JEG2/highline/fork

3. Clone it locally
  - ```git clone git@github.com:YOUR-USERNAME/highline.git```

4. Add the main HighLine repository as the __upstream__ remote
  - ```cd highline``` # to enter the cloned repository directory.
  - ```git remote add upstream https://github.com/JEG2/highline```

5. Keep your fork in sync with __upstream__
  - ```git fetch upstream```
  - ```git checkout master```
  - ```git merge upstream/master```

6. Create your feature branch
  - ```git checkout -b your_branch```

7. Hack the source code, run the tests and __pronto__
  - ```rake test```
  - ```rake acceptance```
  - ```pronto run```

8. Commit your changes
  - ```git commit -am "Your commit message"```

9. Push it
  - ```git push```

10. Open a pull request
  - https://github.com/JEG2/highline/pulls

Details on:

* GitHub Guide to Contributing to Open Source - https://guides.github.com/activities/contributing-to-open-source/
* GitHub issues - https://guides.github.com/features/issues/
* Forking - https://help.github.com/articles/fork-a-repo/
* Cloning - https://help.github.com/articles/cloning-a-repository/
* Adding upstream - https://help.github.com/articles/configuring-a-remote-for-a-fork/
* Syncing your fork - https://help.github.com/articles/syncing-a-fork/
* Branching - https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
* Commiting - https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
* Pushing - https://git-scm.com/book/en/v2/Git-Basics-Working-with-Remotes

The Core HighLine Team
----------------------

* [James Edward Gray II](https://github.com/JEG2) - Author
* [Gregory Brown](https://github.com/practicingruby) - Core contributor
* [Abinoam P. Marques Jr.](https://github.com/abinoam) - Core contributor

_For a list of people who have contributed to the codebase, see [GitHub's list of contributors](https://github.com/JEG2/highline/contributors)._
