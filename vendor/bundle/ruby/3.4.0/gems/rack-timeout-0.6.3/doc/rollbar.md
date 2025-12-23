### Rollbar

Because rack-timeout may raise at any point in the codepath of a timed-out request, the stack traces for similar requests may differ, causing rollbar to create separate entries for each timeout.

The recommended practice is to configure [Custom Fingerprints][rollbar-customfingerprint] on Rollbar.

[rollbar-customfingerprint]: https://docs.rollbar.com/docs/custom-grouping/

Example:

```json
[
  {
    "condition": {
      "eq": "Rack::Timeout::RequestTimeoutException",
      "path": "body.trace.exception.class"
    },
    "fingerprint": "Rack::Timeout::RequestTimeoutException {{context}}",
    "title": "Rack::Timeout::RequestTimeoutException {{context}}"
   }
]

```

This configuration will generate exceptions following the pattern: `Rack::Timeout::RequestTimeoutException controller#action
`

On previous versions this configuration was made using `Rack::Timeout::Rollbar` which was removed. [More details on the Issue #122][rollbar-removal-issue].

[rollbar-removal-issue]: https://github.com/heroku/rack-timeout/issues/122
