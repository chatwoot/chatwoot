## Contributing

I value any contribution to Diff::LCS you can provide: a bug report, a
feature request, or code contributions. Code contributions to Diff::LCS are
especially <del>welcome</del>encouraged. Because Diff::LCS is a complex
codebase, there are a few guidelines:

- Code changes _will not_ be accepted without tests. The test suite is
  written with [RSpec][].
- Match my coding style.
- Use a thoughtfully-named topic branch that contains your change. Rebase
  your commits into logical chunks as necessary.
- Use [quality commit messages][].
- Do not change the version number; when your patch is accepted and a release
  is made, the version will be updated at that point.
- Submit a GitHub pull request with your changes.
- New or changed behaviours require appropriate documentation.

### Test Dependencies

Diff::LCS uses Ryan Davis’s [Hoe][] to manage the release process, and it
adds a number of rake tasks. You will mostly be interested in:

```sh
$ rake
```

which runs the tests the same way that:

```sh
$ rake spec
```

will do.

To assist with the installation of the development dependencies, I have
provided a Gemfile pointing to the (generated) `diff-lcs.gemspec` file. This
will permit you to do:

```sh
$ bundle install
```

to get the development dependencies. If you aleady have `hoe` installed, you
can accomplish the same thing with:

```sh
$ rake newb
```

This task will install any missing dependencies, run the tests/specs, and
generate the RDoc.

You can run tests with code coverage analysis by running:

```sh
$ rake spec:coverage
```

### Workflow

Here's the most direct way to get your work merged into the project:

- Fork the project.
- Clone down your fork (`git clone git://github.com/<username>/diff-lcs.git`).
- Create a topic branch to contain your change (`git checkout -b my_awesome_feature`).
- Hack away, add tests. Not necessarily in that order.
- Make sure everything still passes by running `rake`.
- If necessary, rebase your commits into logical chunks, without errors.
- Push the branch up (`git push origin my_awesome_feature`).
- Create a pull request against halostatue/diff-lcs and describe what your
  change does and the why you think it should be merged.

### Contributors

- Austin Ziegler created Diff::LCS.

Thanks to everyone else who has contributed code or bug reports to Diff::LCS:

- @ginriki
- @joshbronson
- @kevinmook
- @mckaz
- Akinori Musha
- Artem Ignatyev
- Brandon Fish
- Camille Drapier
- Cédric Boutillier
- Gregg Kellogg
- Jagdeep Singh
- Jason Gladish
- Jon Rowe
- Josef Strzibny
- Josep (@apuratepp)
- Josh Bronson
- Jun Aruga
- Justin Steele
- Kenichi Kamiya
- Kensuke Nagae
- Kevin Ansfield
- Koichi Ito
- Mark Friedgan
- Michael Granger
- Myron Marston
- Nicolas Leger
- Oleg Orlov
- Paul Kunysch
- Pete Higgins
- Peter Goldstein
- Peter Wagenet
- Philippe Lafoucrière
- Ryan Lovelett
- Scott Steele
- Simon Courtois
- Tien (@tiendo1011)
- Tomas Jura
- Vít Ondruch

[rspec]: http://rspec.info/documentation/
[quality commit messages]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[hoe]: https://github.com/seattlerb/hoe
