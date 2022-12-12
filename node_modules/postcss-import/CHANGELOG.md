# 12.0.1 / 2018-10-22

- Add `plugin` property to dependency messages ([#379](https://github.com/postcss/postcss-import/issues/379), [#380](https://github.com/postcss/postcss-import/pull/380))

# 12.0.0 - 2018-08-04

- Removed: Support for Node.js v4
- Changed: Uses PostCSS v7 (https://github.com/postcss/postcss/releases/tag/7.0.0)

# 11.1.0 - 2018-02-10

- Added: `filter` option

# 11.0.0 - 2017-09-16

- Changed: A syntax error in an imported file now throws an error instead of just warning ([#264](https://github.com/postcss/postcss-import/issues/264))
- Changed: Symlink handling to be consistent with Node.js `require` ([#300](https://github.com/postcss/postcss-import/pull/300))

# 10.0.0 - 2017-05-12

- Removed: Support for Node.js versions less than 4.5.x ([#283](https://github.com/postcss/postcss-import/pull/283))
- Changed: Upgraded to Postcss v6 ([#283](https://github.com/postcss/postcss-import/pull/283))
- Removed: jspm support ([#283](https://github.com/postcss/postcss-import/pull/283))
- Removed: deprecated `addDependencyTo` option
- Removed: `onImport` option
- Changed: Doesn't depend on promise-each ([#281](https://github.com/postcss/postcss-import/pull/281))

# 9.1.0 - 2017-01-10

- Added: `addModulesDirectories` option ([#256](https://github.com/postcss/postcss-import/pull/256))

# 9.0.0 - 2016-12-02

- Removed: `transform` option
  ([#250](https://github.com/postcss/postcss-import/pull/250))
- Removed: `pkg-resolve` is no longer a dependency; this should fix some issues
  with webpack. jspm users must manually install `pkg-resolve` if they want to
  load jspm modules (see https://github.com/postcss/postcss-import#jspm-usage
  for more info) ([#243](https://github.com/postcss/postcss-import/pull/243))
- Changed: If a file is not found, it will now throw an error instead of just
  raising a warning ([#247](https://github.com/postcss/postcss-import/pull/247))
- Changed: If a custom resolver does not return an absolute path, the default
  resolver will be applied to the returned path.
  ([#249](https://github.com/postcss/postcss-import/pull/249))
- Changed: postcss-import will try to guess the correct parser for imported
  files, based on the file extension.
  ([#245](https://github.com/postcss/postcss-import/pull/245))
- Changed: Deprecated `addDependencyTo` option, it is not needed if using
  postcss-loader >= v1.0.0
  ([#251](https://github.com/postcss/postcss-import/pull/251))

# 8.2.0 - 2016-11-09

- Fixed: Warn about all `@import`s after other CSS declarations
  ([#240](https://github.com/postcss/postcss-import/pull/240))
- Added: `dependency` message
  ([#241](https://github.com/postcss/postcss-import/pull/241))

# 8.1.3 - 2016-11-03

- Fixed: Nested import ordering
  ([#236](https://github.com/postcss/postcss-import/pull/236) - @RyanZim)

# 8.1.2 - 2016-05-07

- Fixed: prevent JSPM to throw unrecoverable error
  ([#205](https://github.com/postcss/postcss-import/pull/205))

# 8.1.1 - 2016-05-04

- Fixed: JSPM support
  ([#194](https://github.com/postcss/postcss-import/pull/194))

# 8.1.0 - 2016-04-04

- Added: JSPM browser field
  ([#186](https://github.com/postcss/postcss-import/pull/186))

# 8.0.2 - 2015-01-27

- Fixed: Comments between imports statements are ignored
([#164](https://github.com/postcss/postcss-import/pull/164))

# 8.0.1 - 2015-01-27

- Fixed: missing "lib" folder
([#161](https://github.com/postcss/postcss-import/issues/161))

# 8.0.0 - 2015-01-27

**All imports statements must be at the top of your file now, per CSS specification.**  
You should use [postcss-reporter](https://github.com/postcss/postcss-reporter) to see the warnings raised.

- Removed: async mode/option (now async by default)
([#107](https://github.com/postcss/postcss-import/pull/107))
- Removed: "bower_components" not supported by default anymore,
use "path" option to add it back
- Removed: `encoding` option. Encoding can be specified in custom `load` option

```js
postcssImport({
  load: function(filename) {
    return fs.readFileSync(filename, "utf-8")
  }
})
```
([#144](https://github.com/postcss/postcss-import/pull/144))

- Removed: glob support
([#146](https://github.com/postcss/postcss-import/pull/146))

Globs can be implemented with custom `resolve` option

```js
postcssImport({
  resolve: function(id, base) {
    return glob.sync(path.join(base, id))
  }
})
```

([#116](https://github.com/postcss/postcss-import/pull/116))
- Changed: custom resolve has more responsibility for paths resolving.
See [resolve option](https://github.com/postcss/postcss-import#resolve)
for more information about this change
([#116](https://github.com/postcss/postcss-import/pull/116))
- Changed: support promise in `transform` option and `undefined` result will be
skipped
([#147](https://github.com/postcss/postcss-import/pull/147))
- Changed: `options.plugins` are applied to unprocessed ast before imports
detecting
([157](https://github.com/postcss/postcss-import/pull/157))
- Added: custom resolve function can return array of paths
([#120](https://github.com/postcss/postcss-import/pull/120))
- Added: custom syntax in imported files support
([#130](https://github.com/postcss/postcss-import/pull/130))
- Added: support custom `load` option
([#144](https://github.com/postcss/postcss-import/pull/144))
- Added: detect css extension in package.json `main` field
([153](https://github.com/postcss/postcss-import/pull/153))

**Note:**
_If you miss options/default behavior (glob etc), a new plugin will handle all
those things.
Please follow issue [#145](https://github.com/postcss/postcss-import/issues/145)
_

# 7.1.3 - 2015-11-05

- Fixed: ensure node 0.12 compatibility, round 2
([#93](https://github.com/postcss/postcss-import/pull/93))

# 7.1.2 - 2015-11-05

- Fixed: performance issue because of cloned options
([#90](https://github.com/postcss/postcss-import/pull/90))

# 7.1.1 - 2015-11-05

- Added: ensure node 0.12 compatibility

# 7.0.0 - 2015-08-25

- Removed: compatibility with postcss v4.x
([#75](https://github.com/postcss/postcss-import/pull/75))
- Added: compatibility with postcss v5.x
([#76](https://github.com/postcss/postcss-import/pull/76))
- Added: lighter package by upgrading some dependencies
([#73](https://github.com/postcss/postcss-import/issues/73))

# 6.2.0 - 2015-07-21

- Added: `skipDuplicates` option now allows you to **not** skip duplicated files
([#67](https://github.com/postcss/postcss-import/issues/67))

# 6.1.1 - 2015-07-07

- Fixed: Prevent mutability issue, round 2
([#44](https://github.com/postcss/postcss-import/issues/44))
- Added: `plugins` option, to run some postcss plugin on imported files
([#55](https://github.com/postcss/postcss-import/issues/55))
- Added: `bower_components` is now part of the default paths
([#66](https://github.com/postcss/postcss-import/issues/66))
- Added: `async` option allow to use enable PostCSS async API usage.
Note that it's not enabling async fs read yet. It has been added to fix breaking
change introduced by 6.1.0.

# 6.1.0 - 2015-07-07 **YANKED**

_This release was not respecting semver and introduced a major breaking change.
It has been unpublished for now._

# 6.0.0 - 2015-06-17

- Changed: warnings messages are now using postcss message api (4.1.x)
- Added: warning when a import statement has not been closed correctly
([#42](https://github.com/postcss/postcss-import/issues/42))

# 5.2.2 - 2015-04-19

- Fixed: globbed imports work for module directories ([#37](https://github.com/postcss/postcss-import/pull/37))

# 5.2.1 - 2015-04-17

- Fixed: glob import now works with single quote `@import` ([#36](https://github.com/postcss/postcss-import/pull/36))

# 5.2.0 - 2015-04-15

- Added: [glob](https://www.npmjs.com/package/glob) pattern are now supported if `glob` option is set to true ([#34](https://github.com/postcss/postcss-import/pull/34))
- Added: plugin can now be added to PostCSS without calling it as a function ([#27](https://github.com/postcss/postcss-import/pull/27))

# 5.1.1 - 2015-04-10

- Fixed: regression of 5.1.0: files which only contain same @import rules were skip ([#31](https://github.com/postcss/postcss-import/issues/31))

# 5.1.0 - 2015-03-27

- Added: files with the same content will only be imported once. Previously, only the full path was used to determine if a file has already been imported in a given scope.
Now, we also test create a hash with the content of the file to check if a file with the same content has not already been imported.
This might be usefull if some modules you import are importing the same library from different places (eg: normalize might be as dep for several modules located in different places in `node_modules`)
([#29](https://github.com/postcss/postcss-import/pull/28))

# 5.0.3 - 2015-02-16

- Fixed: regression of 5.0.2: AST parent references were not updated ([#25](https://github.com/postcss/postcss-import/issues/25))

# 5.0.2 - 2015-02-14

- Fixed: indentation and code style are now preserved ([#20](https://github.com/postcss/postcss-import/issues/20))

# 5.0.1 - 2015-02-13

- Fixed: breaking bug with remote stylesheets ([#21](https://github.com/postcss/postcss-import/issues/21) & [#22](https://github.com/postcss/postcss-import/issues/22))

# 5.0.0 - 2015-01-26

- Added: compatibility with postcss v4.x
- Removed: compatibility with postcss v3.x
- Fixed: relative imports (./ and ../) should work using `path` option only (no need for `from`) ([#14](https://github.com/postcss/postcss-import/issues/14))

# 4.1.1 - 2015-01-05

- Fixed: irregular whitespace that throw syntax error in some environnements

# 4.1.0 - 2014-12-12

- Added: `web_modules` is now in module directories that are used to resolve `@import` ([#13](https://github.com/postcss/postcss-import/issues/13)).

# 4.0.0 - 2014-12-11

- Added: windows compatibility (by building on AppVeyor)
- Added: `root` option

# 3.2.0 - 2014-11-24

- Added: `onImport` callback offers a way to get list of imported files ([ref](https://github.com/postcss/postcss-import/issues/9))

# 3.1.0 - 2014-11-24

- Added: ability to consume local modules (fix [#12](https://github.com/postcss/postcss-import/issues/12))

# 3.0.0 - 2014-11-21

- Added: ability to consume node modules ([ref](https://github.com/postcss/postcss-import/issues/7)).
This means you don't have to add `node_modules` in the path anymore (or using `@import "../node_modules/..."`).
Also, `index.css` can be ommited.

This means something like this

```css
@import "../node_modules/my-css-on-npm/index.css";
```

can be written like this

```css
@import "my-css-on-npm";
```

Dependencies of dependencies should be resolved as well.

_Note that npm resolution is done after the default local behavior._

- Changed: When importing a file multiple times in the same scope (same level of media queries), file will only be imported the first time.
This is done to avoid having multiples outputs of a npm dep used multiples times in different modules.

# 2.0.0 - 2014-11-12

- Added: compatibility with postcss v3.x
- Removed: compatibility with postcss v2.x

# 1.0.3 - 2014-10-29

- Fixed: relative import path stack

# 1.0.2 - 2014-09-16

- Added: Move ignored import at top & adjust related media queries, to make them work (fix [#2](https://github.com/postcss/postcss-import/issues/2))
- Added: Ignore scheme-relative absolute URLs
- Removed: `parse-import` module dependency

# 1.0.1 - 2014-08-26

- Fixed: GNU message format
- Added: Support empty files ([cssnext/#24](https://github.com/putaindecode/cssnext/issues/24))

# 1.0.0 - 2014-08-10

✨ First release based on [rework-import](https://github.com/reworkcss/rework-import) v1.2.0 (mainly for fixtures)
