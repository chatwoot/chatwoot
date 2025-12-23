# Rackup

`rackup` provides a command line interface for running a Rack-compatible application. It also provides a generic interface for starting a `rack`-compatible server: `Rackup::Handler`. It is not designed for production use.

[![Development Status](https://github.com/rack/rackup/workflows/Test/badge.svg)](https://github.com/rack/rackup/actions?workflow=Test)

## Installation

``` bash
-- For Puma
$ gem install rackup puma

-- For Falcon
$ gem install rackup falcon
```

## Usage

In a directory with your `config.ru` simply run the command:

``` bash
$ rackup
```

Your application should now be available locally, typically `http://localhost:9292`.

## (Soft) Deprecation

For a long time, `rackup` (the executable and implementation) was part of `rack`, and `webrick` was the default server, included with Ruby. It made it easy to run a Rack application without having to worry about the details of the server - great for documentation and demos.

When `webrick` was removed from the Ruby standard library, `rack` started depending on `webrick` as a default server. Every web application and server would pull in `webrick` as a dependency, even if it was not used. To avoid this, the `rackup` component of `rack` was moved to this gem, which depended on `webrick`.

However, many libraries (e.g. `rails`) still depend on `rackup` and end up pulling in `webrick` as a dependency. To avoid this, the decision was made to cut `webrick` as a dependency of `rackup`. This means that `rackup` no longer depends on `webrick`, and you need to install it separately if you want to use it.

As a consequence of this, the value of the `rackup` gem is further diminished. In other words, why would you do this:

``` bash
$ gem install rackup puma
$ rackup ...
```

when you can do this:

``` bash
$ gem install puma
$ puma ...
```

In summary, the maintainers of `rack` recommend the following:

  - Libraries should not depend on `rackup` if possible. `rackup` as an executable made sense when webrick shipped with Ruby, so there was always a fallback. But that hasn't been true since Ruby 3.0.
  - Frameworks and applications should focus on providing `config.ru` files, so that users can use the webserver program of their choice directly (e.g. puma, falcon).
  - There is still some value in the generic `rackup` and `Rackup::Handler` interfaces, but we encourage users to invoke the server command directly if possible.
  - Webrick should be avoided if possible.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.
