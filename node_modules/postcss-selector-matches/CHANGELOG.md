# 4.0.0 - 2018-09-17

- Added: compatibility with postcss v7.x
- Added: compatibility with node v6.x

# 3.0.1 - 2017-05-15

- Fixed: incorrect export

# 3.0.0 - 2017-05-11

- Added: compatibility with postcss v6.x

# 2.0.5 - 2016-09-13

- Fixed: another regression of 2.0.2
  (don't mangle selector parts that don't contain `:matches`)
  ([#13](https://github.com/postcss/postcss-selector-matches/pull/13) - @rgrove)

# 2.0.4 - 2016-09-06

- Fixed: another regression of 2.0.2
  ([#10](https://github.com/postcss/postcss-selector-matches/pull/10) - @MoOx)

# 2.0.3 - 2016-09-06

- Fixed: regression of 2.0.2 due to a transpilation upgrade
  (@MoOx)

# 2.0.2 - 2016-09-06

- Fixed: .class:matches(element) now produce element.class
  ([#8](https://github.com/postcss/postcss-selector-matches/pull/8) - @yordis)

# 2.0.1 - 2015-10-26

- Fixed: pseudo selectors with multiple matches in a selector

# 2.0.0 - 2015-08-25

- Removed: compatibility with postcss v4.x
- Added: compatibility with postcss v5.x

# 1.2.1 - 2015-07-14

- Fixed: plugin is correctly exposed for normal commonjs environments (!babel)
([#5](https://github.com/postcss/postcss-selector-matches/issues/5))

# 1.2.0 - 2015-07-14

- Fixed: indentation adjustment doesn't contain useless new lines
- Fixed: transformation doesn't add some useless whitespace
- Added: plugin now expose `replaceRuleSelector` to make it easy to reuse in
some others plugins (like `postcss-custom-selectors`).

# 1.1.2 - 2015-06-29

- Fixed: support pseudo-element that might be collapsed to :matches()
([#4](https://github.com/postcss/postcss-selector-matches/issues/4))
- Fixed: doesn't drop selectors parts that do not have :matches() in them

# 1.1.1 - 2015-06-17

- Fixed: no more duplicates in generated selector
([#3](https://github.com/postcss/postcss-selector-matches/issues/3))

# 1.1.0 - 2015-06-13

- Added: `lineBreak` option
([#1](https://github.com/postcss/postcss-selector-matches/issues/1))

# 1.0.2 - 2015-06-13

- Fixed: support of pseudo classes that use parenthesis
([#2](https://github.com/postcss/postcss-selector-matches/issues/2))

# 1.0.1 - 2015-04-30

- Fixed: the module now works in non babel environments

# 1.0.0 - 2015-04-30

✨ First release
