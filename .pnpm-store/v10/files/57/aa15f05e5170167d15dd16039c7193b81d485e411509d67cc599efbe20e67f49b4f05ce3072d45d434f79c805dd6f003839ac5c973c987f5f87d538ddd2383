'use strict'

/**
 * @see https://github.com/vitest-dev/vitest/blob/main/packages/vitest/src/constants.ts
 */
module.exports = {
	rules: {},
	configs: {
		base: require('./configs/base'),
		recommended: require('./configs/recommended')
	},
	environments: {
		env: {
			globals: {
				// suite
				suite: true,
				test: true,
				describe: true,
				it: true,
				// chai
				chai: true,
				expect: true,
				assert: true,
				// typecheck
				expectTypeOf: true,
				assertType: true,
				// utils
				vitest: true,
				vi: true,
				// hooks
				beforeAll: true,
				afterAll: true,
				beforeEach: true,
				afterEach: true,
				onTestFinished: true,
				onTestFailed: true
			}
		}
	}
}
