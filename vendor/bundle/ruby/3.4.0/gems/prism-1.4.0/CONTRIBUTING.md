# Contributing

Thank you for your interest in contributing to prism! Below are a couple of ways that you can help out.

## Discussions

The discussions page on the GitHub repository are open. If you have a question or want to discuss the project, feel free to open a new discussion or comment on an existing one. This is the best place to ask questions about the project.

## Code

If you want to contribute code, please first open or contribute to a discussion. A lot of the project is in flux, and we want to make sure that you are contributing to the right place. Once you have a discussion going, you can open a pull request with your changes. We will review your code and get it merged in.

## Tests

We could always use more tests! One of the biggest challenges of this project is building up a big test suite. If you want to contribute tests, feel free to open a pull request. These will get merged in as soon as possible.

The `test` Rake task will not compile libraries or the C extension, and this is intentional (to make testing against an installed version easier). If you want to test your changes, please make sure you're also running either the task:

``` sh
bundle exec rake
```

or explicitly running the `compile` task:

``` sh
bundle exec rake compile test
# or to just compile the C extension ...
bundle exec rake compile:prism test
```

To test the rust bindings (with caveats about setting up your Rust environment properly first):

``` sh
bundle exec rake compile test:rust
```


## Documentation

We could always use more documentation! If you want to contribute documentation, feel free to open a pull request. These will get merged in as soon as possible. Documenting functions or methods is always useful, but we also need more guides and tutorials. If you have an idea for a guide or tutorial, feel free to open an issue and we can discuss it.

## Developing

To get `clangd` support in the editor for development, generate the compilation database. This command will
create an ignored `compile_commands.json` file at the project root, which is used by clangd to provide functionality.

You will need `bear` which can be installed on macOS with `brew install bear`.

```sh
bundle exec rake bear
```

## Debugging

Some useful rake tasks:

- `test:valgrind` runs the test suite under valgrind to look for illegal memory access or memory leaks
- `test:gdb` and `test:lldb` run the test suite under those debuggers
