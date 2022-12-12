/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
import type { Config } from '@jest/types';
export declare function check(argv: Config.Argv): true;
export declare const usage = "Usage: $0 [--config=<pathToConfigFile>] [TestPathPattern]";
export declare const docs = "Documentation: https://jestjs.io/";
export declare const options: {
    readonly all: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly automock: {
        readonly default: undefined;
        readonly description: "Automock all files by default.";
        readonly type: "boolean";
    };
    readonly bail: {
        readonly alias: "b";
        readonly default: undefined;
        readonly description: "Exit the test suite immediately after `n` number of failing tests.";
        readonly type: "boolean";
    };
    readonly browser: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly cache: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly cacheDirectory: {
        readonly description: string;
        readonly type: "string";
    };
    readonly changedFilesWithAncestor: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly changedSince: {
        readonly description: string;
        readonly nargs: 1;
        readonly type: "string";
    };
    readonly ci: {
        readonly default: boolean;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly clearCache: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly clearMocks: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly collectCoverage: {
        readonly default: undefined;
        readonly description: "Alias for --coverage.";
        readonly type: "boolean";
    };
    readonly collectCoverageFrom: {
        readonly description: string;
        readonly type: "string";
    };
    readonly collectCoverageOnlyFrom: {
        readonly description: "Explicit list of paths coverage will be restricted to.";
        readonly string: true;
        readonly type: "array";
    };
    readonly color: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly colors: {
        readonly default: undefined;
        readonly description: "Alias for `--color`.";
        readonly type: "boolean";
    };
    readonly config: {
        readonly alias: "c";
        readonly description: string;
        readonly type: "string";
    };
    readonly coverage: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly coverageDirectory: {
        readonly description: "The directory where Jest should output its coverage files.";
        readonly type: "string";
    };
    readonly coveragePathIgnorePatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly coverageProvider: {
        readonly choices: readonly ["babel", "v8"];
        readonly description: "Select between Babel and V8 to collect coverage";
    };
    readonly coverageReporters: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly coverageThreshold: {
        readonly description: string;
        readonly type: "string";
    };
    readonly debug: {
        readonly default: undefined;
        readonly description: "Print debugging info about your jest config.";
        readonly type: "boolean";
    };
    readonly detectLeaks: {
        readonly default: false;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly detectOpenHandles: {
        readonly default: false;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly env: {
        readonly description: string;
        readonly type: "string";
    };
    readonly errorOnDeprecated: {
        readonly default: false;
        readonly description: "Make calling deprecated APIs throw helpful error messages.";
        readonly type: "boolean";
    };
    readonly expand: {
        readonly alias: "e";
        readonly default: undefined;
        readonly description: "Use this flag to show full diffs instead of a patch.";
        readonly type: "boolean";
    };
    readonly filter: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "string";
    };
    readonly findRelatedTests: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly forceExit: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly globalSetup: {
        readonly description: "The path to a module that runs before All Tests.";
        readonly type: "string";
    };
    readonly globalTeardown: {
        readonly description: "The path to a module that runs after All Tests.";
        readonly type: "string";
    };
    readonly globals: {
        readonly description: string;
        readonly type: "string";
    };
    readonly haste: {
        readonly description: "A JSON string with map of variables for the haste module system";
        readonly type: "string";
    };
    readonly init: {
        readonly description: "Generate a basic configuration file";
        readonly type: "boolean";
    };
    readonly injectGlobals: {
        readonly description: "Should Jest inject global variables or not";
        readonly type: "boolean";
    };
    readonly json: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly lastCommit: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly listTests: {
        readonly default: false;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly logHeapUsage: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly mapCoverage: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly maxConcurrency: {
        readonly default: 5;
        readonly description: string;
        readonly type: "number";
    };
    readonly maxWorkers: {
        readonly alias: "w";
        readonly description: string;
        readonly type: "string";
    };
    readonly moduleDirectories: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly moduleFileExtensions: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly moduleNameMapper: {
        readonly description: string;
        readonly type: "string";
    };
    readonly modulePathIgnorePatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly modulePaths: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly noStackTrace: {
        readonly default: undefined;
        readonly description: "Disables stack trace in test results output";
        readonly type: "boolean";
    };
    readonly notify: {
        readonly default: undefined;
        readonly description: "Activates notifications for test results.";
        readonly type: "boolean";
    };
    readonly notifyMode: {
        readonly default: "failure-change";
        readonly description: "Specifies when notifications will appear for test results.";
        readonly type: "string";
    };
    readonly onlyChanged: {
        readonly alias: "o";
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly onlyFailures: {
        readonly alias: "f";
        readonly default: undefined;
        readonly description: "Run tests that failed in the previous execution.";
        readonly type: "boolean";
    };
    readonly outputFile: {
        readonly description: string;
        readonly type: "string";
    };
    readonly passWithNoTests: {
        readonly default: false;
        readonly description: "Will not fail if no tests are found (for example while using `--testPathPattern`.)";
        readonly type: "boolean";
    };
    readonly preset: {
        readonly description: "A preset that is used as a base for Jest's configuration.";
        readonly type: "string";
    };
    readonly prettierPath: {
        readonly default: undefined;
        readonly description: "The path to the \"prettier\" module used for inline snapshots.";
        readonly type: "string";
    };
    readonly projects: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly reporters: {
        readonly description: "A list of custom reporters for the test suite.";
        readonly string: true;
        readonly type: "array";
    };
    readonly resetMocks: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly resetModules: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly resolver: {
        readonly description: "A JSON string which allows the use of a custom resolver.";
        readonly type: "string";
    };
    readonly restoreMocks: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly rootDir: {
        readonly description: string;
        readonly type: "string";
    };
    readonly roots: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly runInBand: {
        readonly alias: "i";
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly runTestsByPath: {
        readonly default: false;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly runner: {
        readonly description: "Allows to use a custom runner instead of Jest's default test runner.";
        readonly type: "string";
    };
    readonly selectProjects: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly setupFiles: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly setupFilesAfterEnv: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly showConfig: {
        readonly default: undefined;
        readonly description: "Print your jest config and then exits.";
        readonly type: "boolean";
    };
    readonly silent: {
        readonly default: undefined;
        readonly description: "Prevent tests from printing messages through the console.";
        readonly type: "boolean";
    };
    readonly skipFilter: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly snapshotSerializers: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly testEnvironment: {
        readonly description: "Alias for --env";
        readonly type: "string";
    };
    readonly testEnvironmentOptions: {
        readonly description: string;
        readonly type: "string";
    };
    readonly testFailureExitCode: {
        readonly description: "Exit code of `jest` command if the test run failed";
        readonly type: "string";
    };
    readonly testLocationInResults: {
        readonly default: false;
        readonly description: "Add `location` information to the test results";
        readonly type: "boolean";
    };
    readonly testMatch: {
        readonly description: "The glob patterns Jest uses to detect test files.";
        readonly string: true;
        readonly type: "array";
    };
    readonly testNamePattern: {
        readonly alias: "t";
        readonly description: "Run only tests with a name that matches the regex pattern.";
        readonly type: "string";
    };
    readonly testPathIgnorePatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly testPathPattern: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly testRegex: {
        readonly description: "A string or array of string regexp patterns that Jest uses to detect test files.";
        readonly string: true;
        readonly type: "array";
    };
    readonly testResultsProcessor: {
        readonly description: string;
        readonly type: "string";
    };
    readonly testRunner: {
        readonly description: string;
        readonly type: "string";
    };
    readonly testSequencer: {
        readonly description: string;
        readonly type: "string";
    };
    readonly testTimeout: {
        readonly description: "This option sets the default timeouts of test cases.";
        readonly type: "number";
    };
    readonly testURL: {
        readonly description: "This option sets the URL for the jsdom environment.";
        readonly type: "string";
    };
    readonly timers: {
        readonly description: string;
        readonly type: "string";
    };
    readonly transform: {
        readonly description: string;
        readonly type: "string";
    };
    readonly transformIgnorePatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly unmockedModulePathPatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly updateSnapshot: {
        readonly alias: "u";
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly useStderr: {
        readonly default: undefined;
        readonly description: "Divert all output to stderr.";
        readonly type: "boolean";
    };
    readonly verbose: {
        readonly default: undefined;
        readonly description: "Display individual test results with the test suite hierarchy.";
        readonly type: "boolean";
    };
    readonly version: {
        readonly alias: "v";
        readonly default: undefined;
        readonly description: "Print the version and exit";
        readonly type: "boolean";
    };
    readonly watch: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly watchAll: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
    readonly watchPathIgnorePatterns: {
        readonly description: string;
        readonly string: true;
        readonly type: "array";
    };
    readonly watchman: {
        readonly default: undefined;
        readonly description: string;
        readonly type: "boolean";
    };
};
