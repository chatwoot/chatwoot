Contributions are welcomed. Please see the following site for guidelines:

[https://sass-lang.com/community#Contribute](https://sass-lang.com/community#Contribute)

* [Branches](#main-development-branches)
  * [Feature Branches](#feature-branches)
  * [Experimental Branches](#experimental-branches)
  * [Old Stable Branches](#old-stable-branches)
* [Versioning](#versioning)
  * [Making Breaking Changes](#making-breaking-changes)
  * [Exceptional Breakages](#exceptional-breakages)

## Branches

The Sass repository has three primary development branches, each of which tracks
a different line of releases (see [versioning](#versioning) below). Each branch
is regularly merged into the one below: `stable` into `next`, `next` into
`master`.

* The `stable` branch is the default—it's what GitHub shows if you go to
  [sass/ruby-sass](https://github.com/sass/ruby-sass), and it's the default place for pull
  requests to go. This branch is where we work on the next patch release. Bug
  fixes and documentation improvements belong here, but not new features.

* The `next` branch is where we work on the next minor release. It's where most
  new features go, as long as they're not breaking changes. Very occasionally
  breaking changes will go here as well—see
  [exceptional breakages](#exceptional-breakages) below for details.

* The `master` branch is where we work on the next major release. It's where
  breaking changes go. We also occasionally decide that a non-breaking feature
  is big enough to warrant saving until the next major release, in which case it
  will also be developed here.

Ideally, pull requests would be made against the appropriate
branch, but don't worry about it too much; if you make a request against the
wrong branch, the maintainer will take responsibility for rebasing it before
merging.

### Testing

Tests for changes to the Sass language go in
[sass-spec](https://github.com/sass/sass-spec) so that other
implementations (E.g. libSass) can be tested against the same test
suite. The sass-spec repo follows a "trunk development" model in that
the tests there test against different version of the Sass language (as
opposed to having branches that track different Sass versions). When
contributing changes to Sass, update the Gemfile to use sass-spec from a
branch or fork that has the new tests. When the feature lands in Sass,
the committer will also merge the corresponding sass-spec changes.

The [documentation of
sass-spec](https://github.com/sass/sass-spec/blob/master/README.md)
explains how to run sass-spec and contribute changes. In development,
Change the Gemfile(s) to use the `:path` option against the sass-spec gem
to link your local checkout of sass and sass-spec together in one or
both directions.

Changes to Sass internals or Ruby Sass specific features (E.g.
the `sass-convert` tool) should always have tests in the Sass `test`
directory following the conventions you see there.

### Feature Branches

Sometimes it won't be possible to merge a new feature into `next` or `master`
immediately. It may require longer-term work before it's complete, or we may not
want to release it as part of any alpha releases of the branch in question.
Branches like this are labeled `feature.#{name}` and stay on GitHub until
they're ready to be merged.

### Experimental Branches

Not all features pan out, and not all code is a good fit for merging into the
main codebase. Usually when this happens the code is just discarded, but every
so often it's interesting or promising enough that it's worth keeping around.
This is what experimental branches (labeled `experimental.#{name}`) are for.
While they're not currently in use, they contain code that might be useful in
the future.

### Old Stable Branches

Usually Sass doesn't have the development time to do long-term maintenance of
old release. But occasionally, very rarely, it becomes necessary. In cases like
that, a branch named `stable_#{version}` will be created, starting from the last
tag in that version series.

## Versioning

Starting with version 3.5.0, Sass uses [semantic versioning](http://semver.org/)
to indicate the evolution of its language semantics as much as possible. This
means that patch releases (such as 3.5.3) contain only bug fixes, minor releases
(such as 3.6.0) contain backwards-compatible features, and only major releases
(such as 4.0.0) are allowed to have backwards-incompatible behavior. There are
[exceptions](#exceptional-breakages), but we try to follow this rule as closely
as possible.

Note, however, that the semantic versioning applies only to the language's
semantics, not to the Ruby APIs. Although we try hard to keep widely-used APIs
like [`Sass::Engine`][Sass::Engine] stable, we don't have a strong distinction
between public and private APIs and we need to be able to freely refactor our
code.

[Sass::Engine]: https://sass-lang.com/documentation/Sass/Engine.html

### Making Breaking Changes

Sometimes the old way of doing something just isn't going to work anymore, and
the new way just can't be made backwards-compatible. In that case, a breaking
change is necessary. These changes are rarely pleasant, but they contribute to
making the language better in the long term.

Our breaking change process tries to make such changes as clear to users and as
easy to adapt to as possible. We want to ensure that there's a clear path
forward for users using functionality that will no longer exist, and that they
are able to understand what's changing and what they need to do. We've developed
the following process for this:

1. Deprecate the old behavior [in `stable`](#branches). At minimum, deprecating
   some behavior involves printing a warning when that behavior is used
   explaining that it's going to go away in the future. Ideally, this message
   will also include code that will do the same thing in a non-deprecated way.
   If there's a thorough prose explanation of the change available online, the
   message should link to that as well.

2. If possible, make `sass-convert` (also in `stable`) convert the deprecated
   behavior into a non-deprecated form. This allows users to run `sass-convert
   -R -i` to automatically update their stylesheets.

3. Implement the new behavior in `master`. The sooner this happens, the better:
   it may be unclear exactly what needs to be deprecated until the new
   implementation exists.

4. Release an alpha version of `master` that includes the new behavior. This
   allows users who are dissatisfied with the workaround to use the new
   behavior early. Normally a maintainer will take care of this.

### Exceptional Breakages

Because Sass's syntax and semantics are closely tied to those of CSS, there are
occasionally times when CSS syntax is introduced that overlaps with
previously-valid Sass. In this case in particular, we may introduce a breaking
change in a minor version to get back to CSS compatibility as soon as possible.

Exceptional breakages still require the full deprecation process; the only
change is that the new behavior is implemented in `next` rather than `master`.
Because there are no minor releases between the deprecation and the removal of
the old behavior, the deprecation warning should be introduced soon as it
becomes clear that an exceptional breakage is necessary.
