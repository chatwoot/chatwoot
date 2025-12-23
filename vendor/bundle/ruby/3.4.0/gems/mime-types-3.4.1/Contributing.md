# Contributing

I value any contribution to mime-types you can provide: a bug report, a feature
request, or code contributions.

There are a few guidelines for contributing to mime-types:

- Code changes _will_ _not_ be accepted without tests. The test suite is
  written with [minitest].
- Match my coding style.
- Use a thoughtfully-named topic branch that contains your change. Rebase your
  commits into logical chunks as necessary.
- Use [quality commit messages].
- Do not change the version number; when your patch is accepted and a release
  is made, the version will be updated at that point.
- Submit a GitHub pull request with your changes.
- New or changed behaviours require new or updated documentation.

## Adding or Modifying MIME Types

The mime-types registry is no longer contained in mime-types, but in
[mime-types-data]. Please see that project for contributions there.

### Test Dependencies

mime-types uses Ryan Davis’s [Hoe] to manage the release process, and it adds
a number of rake tasks. You will mostly be interested in `rake`, which runs
the tests the same way that `rake test` or `rake travis` will do.

To assist with the installation of the development dependencies for
mime-types, I have provided the simplest possible Gemfile pointing to the
(generated) `mime-types.gemspec` file. This will permit you to do `bundle
install` to get the development dependencies. If you aleady have `hoe`
installed, you can accomplish the same thing with `rake newb`.

This task will install any missing dependencies, run the tests/specs, and
generate the RDoc.

You can run tests with code coverage analysis by running `rake
test:coverage`.

## Benchmarks

mime-types offers several benchmark tasks to measure different measures of
performance.

There is a repeated load test, measuring how long it takes to start and load
mime-types with its full registry. By default, it runs fifty loops and uses the
built-in benchmark library:

- `rake benchmark:load`

There are two allocation tracing benchmarks (for normal and columnar loads).
These can only be run on Ruby 2.1 or better and requires the
[allocation\_tracer] gem (not installed by default).

- `rake benchmark:allocations`
- `rake benchmark:allocations:columnar`

There are two loaded object count benchmarks (for normal and columnar loads).
These use `ObjectSpace.count_objects`.

- `rake benchmark:objects`
- `rake benchmark:objects:columnar`

## Workflow

Here's the most direct way to get your work merged into the project:

- Fork the project.
- Clone down your fork (`git clone git://github.com/<username>/ruby-mime-types.git`).
- Create a topic branch to contain your change (`git checkout -b my_awesome_feature`).
- Hack away, add tests. Not necessarily in that order.
- Make sure everything still passes by running `rake`.
- If necessary, rebase your commits into logical chunks, without errors.
- Push the branch up (`git push origin my_awesome_feature`).
- Create a pull request against mime-types/ruby-mime-types and describe what
  your change does and the why you think it should be merged.

## Contributors

- Austin Ziegler created mime-types.

Thanks to everyone else who has contributed to mime-types over the years:

- Aaron Patterson
- Aggelos Avgerinos
- Al Snow
- Andre Pankratz
- Andy Brody
- Arnaud Meuret
- Brandon Galbraith
- Burke Libbey
- Chris Gat
- David Genord
- Dillon Welch
- Eric Marden
- Edward Betts
- Garret Alfert
- Godfrey Chan
- Greg Brockman
- Hans de Graaff
- Henrik Hodne
- Igor Victor
- Janko Marohnić
- Jean Boussier
- Jeremy Evans
- Juanito Fatas
- Jun Aruga
- Łukasz Śliwa
- Keerthi Siva
- Ken Ip
- Kevin Menard
- Koichi ITO
- Martin d'Allens
- Mauricio Linhares
- Nicolas Leger
- Nicholas La Roux
- nycvotes-dev
- Olle Jonsson
- Postmodern
- Richard Hirner
- Richard Hurt
- Richard Schneeman
- Tibor Szolár
- Todd Carrico

[minitest]: https://github.com/seattlerb/minitest
[quality commit messages]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[mime-types-data]: https://github.com/mime-types/mime-types-data
[hoe]: https://github.com/seattlerb/hoe
[allocation\_tracer]: https://github.com/ko1/allocation_tracer
