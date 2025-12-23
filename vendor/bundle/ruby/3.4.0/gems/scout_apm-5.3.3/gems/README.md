# Gems

These gemfiles list specific configurations of gems that we use in travis testing.

## Travis Matrix

```yaml
matrix:
  include:
    - rvm: "1.8.7"
      gemfile: gems/rails3.gemfile
```

Using a gemfile controls the specific versions of the gems that are installed, and can be used to reproduce customer configurations for testing.

## Local Testing

To install the gems specified by a specific gemfile:

```
BUNDLE_GEMFILE=gems/rails5.gemfile bundle install
```

Then, to run tests using these gems:

```
BUNDLE_GEMFILE=gems/rails5.gemfile bundle exec rake
```
