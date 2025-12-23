# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [7.3.1] - 2024-10-15

### Fixed

- Fix 404 error when using Client#embeddings with Azure - thanks to [@ymtdzzz](https://github.com/ymtdzzz) for raising this in a really clear issue.

## [7.3.0] - 2024-10-11

### Added

- Add ability to (with the right incantations) retrieve the chunks used by an Assistant file search - thanks to [@agamble](https://github.com/agamble) for the addition!

## [7.2.0] - 2024-10-10

### Added

- Add ability to pass parameters to Files#list endpoint - thanks to [@parterburn](https://github.com/parterburn)!
- Add Velvet observability platform to README - thanks to [@philipithomas](https://github.com/philipithomas)
- Add Assistants::Messages#delete endpoint - thanks to [@mochetts](https://github.com/mochetts)!

## [7.1.0] - 2024-06-10

### Added

- Add new Vector Store endpoints - thanks to [@willywg](https://github.com/willywg) for this PR!
- Add parameters to batches.list endpoint so you can for example use `after` - thanks to [@marckohlbrugge](https://github.com/marckohlbrugge)!
- Add vision as permitted purpose for files - thanks again to [@willywg](https://github.com/willywg) for the PR.
- Add improved README example of tool calling - thanks [@krschacht](https://github.com/krschacht) - check out his project [HostedGPT](https://github.com/AllYourBot/hostedgpt)!

### Fixed

- Fix broken link in README table of contents - thanks to [@garrettgsb](https://github.com/garrettgsb)!
- Skip sending nil headers - thanks to [@drnic](https://github.com/drnic)!

## [7.0.1] - 2024-04-30

### Fixed

- Update to v2 of Assistants in Messages, Runs, RunSteps and Threads - thanks to [@willywg](https://github.com/willywg) and others for pointing this out.

## [7.0.0] - 2024-04-27

### Added

- Add support for Batches, thanks to [@simonx1](https://github.com/simonx1) for the PR!
- Allow use of local LLMs like Ollama! Thanks to [@ThomasSevestre](https://github.com/ThomasSevestre)
- Update to v2 of the Assistants beta & add documentation on streaming from an Assistant.
- Add Assistants endpoint to create and run a thread in one go, thank you [@quocphien90](https://github.com/
  quocphien90)
- Add missing parameters (order, limit, etc) to Runs, RunSteps and Messages - thanks to [@shalecraig](https://github.com/shalecraig) and [@coezbek](https://github.com/coezbek)
- Add missing Messages#list spec - thanks [@adammeghji](https://github.com/adammeghji)
- Add Messages#modify to README - thanks to [@nas887](https://github.com/nas887)
- Don't add the api_version (`/v1/`) to base_uris that already include it - thanks to [@kaiwren](https://github.com/kaiwren) for raising this issue
- Allow passing a `StringIO` to Files#upload - thanks again to [@simonx1](https://github.com/simonx1)
- Add Ruby 3.3 to CI

### Security

- [BREAKING] ruby-openai will no longer log out API errors by default - you can reenable by passing `log_errors: true` to your client. This will help to prevent leaking secrets to logs. Thanks to [@lalunamel](https://github.com/lalunamel) for this PR.

### Removed

- [BREAKING] Remove deprecated edits endpoint.

### Fixed

- Fix README DALL·E 3 error - thanks to [@clayton](https://github.com/clayton)
- Fix README tool_calls error and add missing tool_choice info - thanks to [@Jbrito6492](https://github.com/Jbrito6492)

## [6.5.0] - 2024-03-31

### Added

- Add back the deprecated Completions endpoint that I removed a bit prematurely. Thanks, [@mishranant](https://github.com/
  mishranant) and everyone who requested this.

## [6.4.0] - 2024-03-27

### Added

- Add DALL·E 3 to specs and README - thanks to [@Gary-H9](https://github.com/Gary-H9)
- Add Whisper transcription language selection parameter to README - thanks to [@nfedyashev](https://github.com/nfedyashev)
- Add bundle exec rake lint and bundle exec rake test to make development easier - thanks to [@ignacio-chiazzo](https://github.com/ignacio-chiazzo)
- Add link to [https://github.com/sponsors/alexrudall](https://github.com/sponsors/alexrudall) when users run `bundle fund`

### Fixed

- Update README and spec to use tool calls instead of functions - thanks to [@mpallenjr](https://github.com/mpallenjr)
- Remove nonexistent Thread#list method - thanks again! to [@ignacio-chiazzo](https://github.com/ignacio-chiazzo)
- Update finetunes docs in README to use chat instead of completions endpoint - thanks to [@blefev](https://github.com/blefev)

## [6.3.1] - 2023-12-04

### Fixed

- Allow any kind of file (eg. PDFs) to be uploaded to the API, not just JSONL files. Thank you [@stefan-kp](https://github.com/stefan-kp) for the PR!

## [6.3.0] - 2023-11-26

### Added

- Add ability to pass [Faraday middleware](https://lostisland.github.io/faraday/#/middleware/index) to the client in a block, eg. to enable verbose logging - shout out to [@obie](https://github.com/obie) for pushing for this.
- Add better error logging to the client by default.
- Bump Event Source to v1, thank you [@atesgoral](https://github.com/atesgoral) @ Shopify!

## [6.2.0] - 2023-11-15

### Added

- Add text-to-speech! Thank you [@codergeek121](https://github.com/codergeek121)

## [6.1.0] - 2023-11-14

### Added

- Add support for Assistants, Threads, Messages and Runs. Thank you [@Haegin](https://github.com/Haegin) for the excellent work on this PR, and many reviewers for their contributions!

## [6.0.1] - 2023-11-07

### Fix

- Gracefully handle the case where an HTTP error response may not have valid JSON in its body. Thank you [@atesgoral](https://github.com/atesgoral)!

## [6.0.0] - 2023-11-06

### Added

- [BREAKING] HTTP errors will now be raised by ruby-openai as Faraday:Errors, including when streaming! Implemented by [@atesgoral](https://github.com/atesgoral)
- [BREAKING] Switch from legacy Finetunes to the new Fine-tune-jobs endpoints. Implemented by [@lancecarlson](https://github.com/lancecarlson)
- [BREAKING] Remove deprecated Completions endpoints - use Chat instead.

### Fixed

- [BREAKING] Fix issue where :stream parameters were replaced by a boolean in the client application. Thanks to [@martinjaimem](https://github.com/martinjaimem), [@vickymadrid03](https://github.com/vickymadrid03) and [@nicastelo](https://github.com/nicastelo) for spotting and fixing this issue.

## [5.2.0] - 2023-10-30

### Fixed

- Added more spec-compliant SSE parsing: see here https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation
- Fixes issue where OpenAI or an intermediary returns only partial JSON per chunk of streamed data
- Huge thanks to [@atesgoral](https://github.com/atesgoral) for this important fix!

## [5.1.0] - 2023-08-20

### Added

- Added rough_token_count to estimate tokens in a string according to OpenAI's "rules of thumb". Thank you to [@jamiemccarthy](https://github.com/jamiemccarthy) for the idea and implementation!

## [5.0.0] - 2023-08-14

### Added

- Support multi-tenant use of the gem! Each client now holds its own config, so you can create unlimited clients in the same project, for example to Azure and OpenAI, or for different headers, access keys, etc.
- [BREAKING-ish] This change should only break your usage of ruby-openai if you are directly calling class methods like `OpenAI::Client.get` for some reason, as they are now instance methods. Normal usage of the gem should be unaffected, just you can make new clients and they'll keep their own config if you want, overriding the global config.
- Huge thanks to [@petergoldstein](https://github.com/petergoldstein) for his original work on this, [@cthulhu](https://github.com/cthulhu) for testing and many others for reviews and suggestions.

### Changed

- [BREAKING] Move audio related method to Audio model from Client model. You will need to update your code to handle this change, changing `client.translate` to `client.audio.translate` and `client.transcribe` to `client.audio.transcribe`.

## [4.3.2] - 2023-08-14

### Fixed

- Don't overwrite config extra-headers when making a client without different ones. Thanks to [@swistaczek](https://github.com/swistaczek) for raising this!
- Include extra-headers for Azure requests.

## [4.3.1] - 2023-08-13

### Fixed

- Tempfiles can now be sent to the API as well as Files, eg for Whisper. Thanks to [@codergeek121](https://github.com/codergeek121) for the fix!

## [4.3.0] - 2023-08-12

### Added

- Add extra-headers to config to allow setting openai-caching-proxy-worker TTL, Helicone Auth and anything else ya need. Ty to [@deltaguita](https://github.com/deltaguita) and [@marckohlbrugge](https://github.com/marckohlbrugge) for the PR!

## [4.2.0] - 2023-06-20

### Added

- Add Azure OpenAI Service support. Thanks to [@rmachielse](https://github.com/rmachielse) and [@steffansluis](https://github.com/steffansluis) for the PR and to everyone who requested this feature!

## [4.1.0] - 2023-05-15

### Added

- Add the ability to trigger any callable object as stream chunks come through, not just Procs. Big thanks to [@obie](https://github.com/obie) for this change.

## [4.0.0] - 2023-04-25

### Added

- Add the ability to stream Chat responses from the API! Thanks to everyone who requested this and made suggestions.
- Added instructions for streaming to the README.

### Changed

- Switch HTTP library from HTTParty to Faraday to allow streaming and future feature and performance improvements.
- [BREAKING] Endpoints now return JSON rather than HTTParty objects. You will need to update your code to handle this change, changing `JSON.parse(response.body)["key"]` and `response.parsed_response["key"]` to just `response["key"]`.

## [3.7.0] - 2023-03-25

### Added

- Allow the usage of proxy base URIs like https://www.helicone.ai/. Thanks to [@mmmaia](https://github.com/mmmaia) for the PR!

## [3.6.0] - 2023-03-22

### Added

- Add much-needed ability to increase HTTParty timeout, and set default to 120 seconds. Thanks to [@mbackermann](https://github.com/mbackermann) for the PR and to everyone who requested this!

## [3.5.0] - 2023-03-02

### Added

- Add Client#transcribe and Client translate endpoints - Whisper over the wire! Thanks to [@Clemalfroy](https://github.com/Clemalfroy)

## [3.4.0] - 2023-03-01

### Added

- Add Client#chat endpoint - ChatGPT over the wire!

## [3.3.0] - 2023-02-15

### Changed

- Replace ::Ruby::OpenAI namespace with ::OpenAI - thanks [@kmcphillips](https://github.com/kmcphillips) for this work!
- To upgrade, change `require 'ruby/openai'` to `require 'openai'` and change all references to `Ruby::OpenAI` to `OpenAI`.

## [3.2.0] - 2023-02-13

### Added

- Add Files#content endpoint - thanks [@unixneo](https://github.com/unixneo) for raising!

## [3.1.0] - 2023-02-13

### Added

- Add Finetunes#delete endpoint - thanks [@lancecarlson](https://github.com/lancecarlson) for flagging this.
- Add VCR header and body matching - thanks [@petergoldstein](https://github.com/petergoldstein)!

### Fixed

- Update File#upload specs to remove deprecated `answers` purpose.

## [3.0.3] - 2023-01-07

### Added

- Add ability to run the specs without VCR cassettes using `NO_VCR=true bundle exec rspec`.
- Add Ruby 3.2 to CircleCI config - thanks [@petergoldstein](https://github.com/petergoldstein)!
- A bit of detail added to the README on DALLE image sizes - thanks [@ndemianc](https://github.com/ndemianc)!

### Fixed

- Fix finetunes and files uploads endpoints - thanks [@chaadow](https://github.com/chaadow) for your PR on this and [@petergoldstein](https://github.com/petergoldstein) for the PR we ultimately went with.

## [3.0.2] - 2022-12-27

### Fixed

- Fixed Images#generate and Finetunes#create which were broken by a double call of to_json.
- Thanks [@konung](https://github.com/konung) for spotting this!

## [3.0.1] - 2022-12-26

### Removed

- [BREAKING] Remove deprecated answers, classifications, embeddings, engines and search endpoints.
- [BREAKING] Remove ability to pass engine to completions and embeddings outside of the parameters hash.

## [3.0.0] - 2022-12-26

### Added

- Add ability to set access_token via gem configuration.
- Thanks [@grjones](https://github.com/grjones) and [@aquaflamingo](https://github.com/aquaflamingo) for raising this and [@feministy](https://github.com/feministy) for the [excellent guide](https://github.com/feministy/lizabinante.com/blob/stable/source/2016-01-30-creating-a-configurable-ruby-gem.markdown#configuration-block-the-end-goal) to adding config to a gem.

### Removed

- [BREAKING] Remove ability to include access_token directly via ENV vars.
- [BREAKING] Remove ability to pass API version directly to endpoints.

## [2.3.0] - 2022-12-23

### Added

- Add Images#edit and Images#variations endpoint to modify images with DALL·E.

## [2.2.0] - 2022-12-15

### Added

- Add Organization ID to headers so users can charge credits to the correct organization.
- Thanks [@mridul911](https://github.com/mridul911) for raising this and [@maks112v](https://github.com/maks112v) for adding it!

## [2.1.0] - 2022-11-13

### Added

- Add Images#generate endpoint to generate images with DALL·E!

## [2.0.1] - 2022-10-22

### Removed

- Deprecate Client#answers endpoint.
- Deprecate Client#classifications endpoint.

## [2.0.0] - 2022-09-19

### Removed

- [BREAKING] Remove support for Ruby 2.5.
- [BREAKING] Remove support for passing `query`, `documents` or `file` as top-level parameters to `Client#search`.
- Deprecate Client#search endpoint.
- Deprecate Client#engines endpoints.

### Added

- Add Client#models endpoints to list and query available models.

## [1.5.0] - 2022-09-18

### Added

- Add Client#moderations endpoint to check OpenAI's Content Policy.
- Add Client#edits endpoints to transform inputs according to instructions.

## [1.4.0] - 2021-12-11

### Added

- Add Client#engines endpoints to list and query available engines.
- Add Client#finetunes endpoints to create and use fine-tuned models.
- Add Client#embeddings endpoint to get vector representations of inputs.
- Add tests and examples for more engines.

## [1.3.1] - 2021-07-14

### Changed

- Add backwards compatibility from Ruby 2.5+.

## [1.3.0] - 2021-04-18

### Added

- Add Client#classifications to predict the most likely labels based on examples or a file.

### Fixed

- Fixed Files#upload which was previously broken by the validation code!

## [1.2.2] - 2021-04-18

### Changed

- Add Client#search(parameters:) to allow passing `max_rerank` or `return_metadata`.
- Deprecate Client#search with query, file or document parameters at the top level.
- Thanks [@stevegeek](https://github.com/stevegeek) for pointing this issue out!

## [1.2.1] - 2021-04-11

### Added

- Add validation of JSONL files to make it easier to debug during upload.

## [1.2.0] - 2021-04-08

### Added

- Add Client#answers endpoint for question/answer response on documents or a file.

## [1.1.0] - 2021-04-07

### Added

- Add Client#files to allow file upload.
- Add Client#search(file:) so you can search a file.

## [1.0.0] - 2021-02-01

### Removed

- Remove deprecated method Client#call - use Client#completions instead.

### Changed

- Rename 'master' branch to 'main' branch.
- Bump dependencies.

## [0.3.0] - 2020-11-22

### Added

- Add Client#completions to allow all parameters.

### Changed

- Deprecate Client#call.
- Update README.

## [0.2.0] - 2020-11-22

### Added

- Add method to use the search endpoint.

## [0.1.4] - 2020-10-18

### Changed

- Bump Rubocop to 3.9.2.
- Bump Webmock to 3.9.1.

## [0.1.3] - 2020-09-09

### Changed

- Add ability to change API version in the future.
- Fix README typos.

## [0.1.2] - 2020-09-09

### Added

- Add tests and cached responses for the different engines.
- Add issue templates.

### Changed

- Add README instructions for using the gem without dotenv.
- Add list of engines to README.

## [0.1.1] - 2020-09-08

### Added

- Run Rubocop on pulls using CircleCI.

### Changed

- Clean up CircleCI config file.

## [0.1.0] - 2020-09-06

### Added

- Initialise repository.
- Add OpenAI::Client to connect to OpenAI API using user credentials.
- Add spec for Client with a cached response using VCR.
- Add CircleCI to run the specs on pull requests.
