# PostHog Browser JS Library

[![npm package](https://img.shields.io/npm/v/posthog-js?style=flat-square)](https://www.npmjs.com/package/posthog-js)
[![MIT License](https://img.shields.io/badge/License-MIT-red.svg?style=flat-square)](https://opensource.org/licenses/MIT)

For information on using this library in your app, [see PostHog Docs](https://posthog.com/docs/libraries/js).
This README is intended for developing the library itself.

## Dependencies

we use pnpm.

it's best to install using `npm install -g pnpm@latest-9`
and then `pnpm` commands as usual

### Optional Dependencies

This package has the following optional peer dependencies:

- `@rrweb/types` (2.0.0-alpha.17): Only required if you're using Angular Compiler and need type definitions for the rrweb integration.
- `rrweb-snapshot` (2.0.0-alpha.17): Only required if you're using Angular Compiler and need type definitions for the rrweb integration.

These dependencies are marked as optional to reduce installation size for users who don't need these specific features.

##

## Testing

> [!NOTE]
> Run `pnpm build` at least once before running tests.


- Unit tests: run `pnpm test`.
- Cypress: run `pnpm start` to have a test server running and separately `pnpm cypress` to launch Cypress test engine.
- Playwright: run e.g. `pnpm exec playwright test --ui --project webkit --project firefox` to run with UI and in webkit and firefox

### Running TestCafe E2E tests with BrowserStack

Testing on IE11 requires a bit more setup. TestCafe tests will use the
playground application to test the locally built array.full.js bundle. It will
also verify that the events emitted during the testing of playground are loaded
into the PostHog app. By default it uses https://us.i.posthog.com and the
project with ID 11213. See the testcafe tests to see how to override these if
needed. For PostHog internal users ask @benjackwhite or @hazzadous to invite you
to the Project. You'll need to set `POSTHOG_API_KEY` to your personal API key, and
`POSTHOG_PROJECT_KEY` to the key for the project you are using.

You'll also need to sign up to [BrowserStack](https://www.browserstack.com/).
Note that if you are using CodeSpaces, these variables will already be available
in your shell env variables.

After all this, you'll be able to run through the below steps:

1. Optional: rebuild array.js on changes: `nodemon -w src/ --exec bash -c "pnpm build-rollup"`.
1. Export browserstack credentials: `export BROWSERSTACK_USERNAME=xxx BROWSERSTACK_ACCESS_KEY=xxx`.
1. Run tests: `npx testcafe "browserstack:ie" testcafe/e2e.spec.js`.

### Running local create react app example

You can use the create react app setup in `packages/browser/playground/nextjs` to test posthog-js as an npm module in a Nextjs application.

1. Run `posthog` locally on port 8000 (`DEBUG=1 TEST=1 ./bin/start`).
1. Run `python manage.py setup_dev --no-data` on posthog repo, which sets up a demo account.
1. Copy Project API key found in `http://localhost:8000/project/settings` and save it for the last step.
1. Run `cd packages/browser/playground/nextjs`.
1. Run `pnpm install-deps` to install dependencies.
1. Run `NEXT_PUBLIC_POSTHOG_KEY='<your-local-api-key>' NEXT_PUBLIC_POSTHOG_HOST='http://localhost:8000' pnpm dev` to start the application.

### Tiers of testing

1. Unit tests - this verifies the behavior of the library in bite-sized chunks. Keep this coverage close to 100%, test corner cases and internal behavior here
2. Browser tests - run in real browsers and so capable of testing timing, browser requests, etc. Useful for testing high-level library behavior, ordering and verifying requests. We shouldn't aim for 100% coverage here as it's impossible to test all possible combinations.
3. TestCafe E2E tests - integrates with a real posthog instance sends data to it. Hardest to write and maintain - keep these very high level

## Developing together with another project

Install pnpm to link a local version of `posthog-js` in another JS project: `npm install -g pnpm`

### Run this to link the local version

We have 2 options for linking this project to your local version: via [pnpm link](https://docs.npmjs.com/cli/v8/commands/npm-link) or via [local paths](https://docs.npmjs.com/cli/v9/configuring-npm/package-json#local-paths)

#### local paths (preferred)

- from whichever repo needs to require `posthog-js`, go to the `package.json` of that file, and replace the `posthog-js` dependency version number with `file:<relative_or_absolute_path_to_local_module>`
- e.g. from the `package.json` within `posthog`, replace `"posthog-js": "1.131.4"` with `"posthog-js": "file:../posthog-js"`
- run `pnpm install` from the root of the project in which you just created a local path

Then, once this link has been created, any time you need to make a change to `posthog-js`, you can run `pnpm build` from the `posthog-js` root and the changes will appear in the other repo.

#### `pnpm link`

- In the `posthog-js` directory: `pnpm link --global`
- (for `posthog` this means: `pnpm link --global posthog-js && pnpm i && pnpm copy-scripts`)
- You can then remove the link by, e.g., running `pnpm link --global posthog-js` from within `posthog`
