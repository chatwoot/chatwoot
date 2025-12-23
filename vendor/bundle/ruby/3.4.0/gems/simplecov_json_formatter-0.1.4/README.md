# JSON formatter for SimpleCov

***Note: To learn more about SimpleCov, check out the main repo at [https://github.com/simplecov-ruby/simplecov](https://github.com/colszowka/simplecov***)***

Generates a formatted JSON report of your [SimpleCov](https://github.com/simplecov-ruby/simplecov) ruby code coverage results on ruby 2.4+. Originally intended to add `simplecov`'s results reading capacity to CI tools.

## Overview

You can expect for this gem to produce a `coverage.json` file, located at the `coverage` folder.

Depending on your `SimpleCoV`'s settings you will experiment different outcomes. Particularly depending on which type of coverage are you running `SimpleCov` with:

- If you configure `SimpleCov` to run with `branch` coverage you should expect an output formatted like [sample_with_branch.json](https://github.com/fede-moya/simplecov_json_formatter/blob/master/spec/fixtures/sample_with_branch.json)
- Otherwise you should expect an output formatted like [sample.json](https://github.com/fede-moya/simplecov_json_formatter/blob/master/spec/fixtures/sample.json)

## Development

We encourage you to use docker for common operations like running tests, or debugging your code. Running `make sh` will start a new container instance based on the `Dockerfile` provided at root, finally a shell prompt will be displayed on your terminal. Also, syncronization with your local files will be already set.

### Tests
`make test` will trigger the excution of both running tests and running rubocop as linter, by simply running `rake`, this actions will be run inside a new container but using your local files.

### Format

`make format` will run `rubocop -a` which stands for _autocorrect_ and format your code according to the `.rubocop.yml` config file.

## Copyright

See [License](https://github.com/codeclimate-community/simplecov_json_formatter/blob/master/LICENSE)
