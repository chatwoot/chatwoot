[![Cult Of Martians](http://cultofmartians.com/assets/badges/badge.svg)](https://cultofmartians.com)
[![Gem Version](https://badge.fury.io/rb/test-prof.svg)](https://rubygems.org/gems/test-prof) [![Build](https://github.com/test-prof/test-prof/workflows/Build/badge.svg)](https://github.com/test-prof/test-prof/actions)
[![JRuby Build](https://github.com/test-prof/test-prof/workflows/JRuby%20Build/badge.svg)](https://github.com/test-prof/test-prof/actions)
[![Code Triagers Badge](https://www.codetriage.com/test-prof/test-prof/badges/users.svg)](https://www.codetriage.com/test-prof/test-prof)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://test-prof.evilmartians.io)

# Ruby Tests Profiling Toolbox

<img align="right" height="150" width="129"
     title="TestProf logo" src="./docs/assets/images/logo.svg">

TestProf is a collection of different tools to analyze your test suite performance.

Why does test suite performance matter? First of all, testing is a part of a developer's feedback loop (see [@searls](https://github.com/searls) [talk](https://vimeo.com/145917204)) and, secondly, it is a part of a deployment cycle.

Simply speaking, slow tests waste your time making you less productive.

TestProf toolbox aims to help you identify bottlenecks in your test suite. It contains:

- Plug'n'Play integrations for general Ruby profilers ([`ruby-prof`](https://github.com/ruby-prof/ruby-prof), [`stackprof`](https://github.com/tmm1/stackprof))

- Factories usage analyzers and profilers

- ActiveSupport-backed profilers

- RSpec and minitest [helpers](https://test-prof.evilmartians.io/#/?id=recipes) to write faster tests

- RuboCop cops

- etc.

📑 [Documentation](https://test-prof.evilmartians.io)

<p align="center">
  <a href="http://bit.ly/test-prof-map-v1">
    <img src="./docs/assets/images/coggle.png" alt="TestProf map" width="738">
  </a>
</p>

<p align="center">
  <a href="https://evilmartians.com/?utm_source=test-prof">
    <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg"
         alt="Sponsored by Evil Martians" width="236" height="54">
  </a>
</p>

## Who uses TestProf

- [Discourse](https://github.com/discourse/discourse) reduced [~27% of their test suite time](https://twitter.com/samsaffron/status/1125602558024699904)
- [Gitlab](https://gitlab.com/gitlab-org/gitlab-ce) reduced [39% of their API tests time](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14370) and [improved factories usage](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26810)
- [CodeTriage](https://github.com/codetriage/codetriage)
- [Dev.to](https://github.com/thepracticaldev/dev.to)
- [Open Project](https://github.com/opf/openproject)
- [...and others](https://github.com/test-prof/test-prof/issues/73)

## Resources

- [TestProf: a good doctor for slow Ruby tests](https://evilmartians.com/chronicles/testprof-a-good-doctor-for-slow-ruby-tests)

- [TestProf II: Factory therapy for your Ruby tests](https://evilmartians.com/chronicles/testprof-2-factory-therapy-for-your-ruby-tests-rspec-minitest)

- Paris.rb, 2018, "99 Problems of Slow Tests" talk [[video](https://www.youtube.com/watch?v=eDMZS_fkRtk), [slides](https://speakerdeck.com/palkan/paris-dot-rb-2018-99-problems-of-slow-tests)]

- BalkanRuby, 2018, "Take your slow tests to the doctor" talk [[video](https://www.youtube.com/watch?v=rOcrme82vC8)], [slides](https://speakerdeck.com/palkan/balkanruby-2018-take-your-slow-tests-to-the-doctor)]

- RailsClub, Moscow, 2017, "Faster Tests" talk [[video](https://www.youtube.com/watch?v=8S7oHjEiVzs) (RU), [slides](https://speakerdeck.com/palkan/railsclub-moscow-2017-faster-tests)]

- RubyConfBy, 2017, "Run Test Run" talk [[video](https://www.youtube.com/watch?v=q52n4p0wkIs), [slides](https://speakerdeck.com/palkan/rubyconfby-minsk-2017-run-test-run)]

- [Tips to improve speed of your test suite](https://medium.com/appaloosa-store-engineering/tips-to-improve-speed-of-your-test-suite-8418b485205c) by [Benoit Tigeot](https://github.com/benoittgt)

## Installation

Add `test-prof` gem to your application:

```ruby
group :test do
  gem "test-prof", "~> 1.0"
end
```

And that's it)

Supported Ruby versions:

- Ruby (MRI) >= 2.5.0 (**NOTE:** for Ruby 2.2 use TestProf < 0.7.0, Ruby 2.3 use TestProf ~> 0.7.0, Ruby 2.4 use TestProf <0.12.0)

- JRuby >= 9.1.0.0 (**NOTE:** refinements-dependent features might require 9.2.7+)

Supported RSpec version (for RSpec features only): >= 3.5.0 (for older RSpec versions use TestProf < 0.8.0).

## Usage

Check out our [docs][].

## What's next?

Have an idea? [Propose](https://github.com/test-prof/test-prof/issues/new) a feature request!

Already using TestProf? [Share your story!](https://github.com/test-prof/test-prof/issues/73)

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[docs]: https://test-prof.evilmartians.io
