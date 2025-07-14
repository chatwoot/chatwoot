import { w as ResolvedConfig, s as VitestRunMode, z as VitestOptions, V as Vitest, v as UserConfig$1, A as ApiConfig, E as TestProject, F as TestSequencer, G as TestSpecification, L as Logger, H as TestModule, M as ModuleDiagnostic } from './chunks/reporters.6vxQttCV.js';
export { B as BaseCoverageOptions, y as BenchmarkUserOptions, ad as BrowserBuiltinProvider, ae as BrowserCommand, af as BrowserCommandContext, n as BrowserConfigOptions, ag as BrowserInstanceOption, ah as BrowserOrchestrator, ai as BrowserProvider, aj as BrowserProviderInitializationOptions, ak as BrowserProviderModule, al as BrowserProviderOptions, m as BrowserScript, am as BrowserServerState, an as BrowserServerStateSession, o as BuiltinEnvironment, ao as CDPSession, r as CSSModuleScopeStrategy, j as CoverageIstanbulOptions, i as CoverageOptions, b as CoverageProvider, c as CoverageProviderModule, g as CoverageReporter, d as CoverageV8Options, k as CustomProviderOptions, D as DepsOptimizationOptions, Z as HTMLOptions, I as InlineConfig, $ as JUnitOptions, _ as JsonOptions, O as OnServerRestartHandler, J as OnTestsRerunHandler, ap as ParentProjectBrowser, P as Pool, q as PoolOptions, N as ProcessPool, aq as ProjectBrowser, x as ProjectConfig, a as ReportContext, aw as ReportedHookContext, l as Reporter, at as ResolveSnapshotPathHandler, au as ResolveSnapshotPathHandlerContext, ar as ResolvedBrowserOptions, R as ResolvedCoverageOptions, as as ResolvedProjectConfig, Y as SerializedTestProject, a0 as TaskOptions, a1 as TestCase, a2 as TestCollection, a3 as TestDiagnostic, a4 as TestModuleState, a5 as TestResult, a6 as TestResultFailed, a7 as TestResultPassed, a8 as TestResultSkipped, ax as TestRunEndReason, av as TestRunResult, ac as TestSequencerConstructor, a9 as TestState, aa as TestSuite, ab as TestSuiteState, t as TransformModePatterns, u as TypecheckConfig, U as UserWorkspaceConfig, p as VitestEnvironment, K as VitestPackageInstaller, Q as WorkspaceSpec, X as getFilePoolName } from './chunks/reporters.6vxQttCV.js';
import { UserConfig, Plugin, ResolvedConfig as ResolvedConfig$1, LogLevel, LoggerOptions, Logger as Logger$1, createServer as createServer$1 } from 'vite';
import * as vite from 'vite';
export { vite as Vite };
export { esbuildVersion, isFileServingAllowed, parseAst, parseAstAsync, rollupVersion, version as viteVersion } from 'vite';
import { IncomingMessage } from 'node:http';
import { R as RuntimeRPC } from './chunks/worker.CIpff8Eg.js';
import { Writable } from 'node:stream';
export { W as WorkerContext } from './chunks/worker.B1y96qmv.js';
export { C as TypeCheckCollectLineNumbers, a as TypeCheckCollectLines, c as TypeCheckContext, T as TypeCheckErrorInfo, R as TypeCheckRawErrorsMap, b as TypeCheckRootAndTarget } from './chunks/global.CnI8_G5V.js';
import { Debugger } from 'debug';
export { Task as RunnerTask, TaskResult as RunnerTaskResult, TaskResultPack as RunnerTaskResultPack, Test as RunnerTestCase, File as RunnerTestFile, Suite as RunnerTestSuite, SequenceHooks, SequenceSetupFiles } from '@vitest/runner';
export { f as EnvironmentOptions, H as HappyDOMOptions, J as JSDOMOptions } from './chunks/environment.d8YfPkTm.js';
export { SerializedError } from '@vitest/utils';
export { b as RuntimeConfig } from './chunks/config.BRtC-JeT.js';
import './chunks/vite.Cu7NWuBa.js';
export { generateFileHash } from '@vitest/runner/utils';
import '@vitest/utils/source-map';
import '@vitest/pretty-format';
import '@vitest/snapshot';
import '@vitest/utils/diff';
import 'vite-node';
import 'chai';
import './chunks/benchmark.CFFwLv-O.js';
import 'tinybench';
import '@vitest/snapshot/manager';
import 'node:fs';
import 'node:worker_threads';
import '@vitest/expect';
import '@vitest/snapshot/environment';

declare function isValidApiRequest(config: ResolvedConfig, req: IncomingMessage): boolean;

interface CliOptions extends UserConfig$1 {
    /**
     * Override the watch mode
     */
    run?: boolean;
    /**
     * Removes colors from the console output
     */
    color?: boolean;
    /**
     * Output collected tests as JSON or to a file
     */
    json?: string | boolean;
    /**
     * Output collected test files only
     */
    filesOnly?: boolean;
}
/**
 * Start Vitest programmatically
 *
 * Returns a Vitest instance if initialized successfully.
 */
declare function startVitest(mode: VitestRunMode, cliFilters?: string[], options?: CliOptions, viteOverrides?: UserConfig, vitestOptions?: VitestOptions): Promise<Vitest>;

interface CliParseOptions {
    allowUnknownOptions?: boolean;
}
declare function parseCLI(argv: string | string[], config?: CliParseOptions): {
    filter: string[];
    options: CliOptions;
};

declare function resolveApiServerConfig<Options extends ApiConfig & UserConfig$1>(options: Options, defaultPort: number): ApiConfig | undefined;

declare function createVitest(mode: VitestRunMode, options: UserConfig$1, viteOverrides?: UserConfig, vitestOptions?: VitestOptions): Promise<Vitest>;

declare class FilesNotFoundError extends Error {
    code: string;
    constructor(mode: 'test' | 'benchmark');
}
declare class GitNotFoundError extends Error {
    code: string;
    constructor();
}

/** @deprecated use `TestProject` instead */
type GlobalSetupContext = TestProject;

declare function VitestPlugin(options?: UserConfig$1, ctx?: Vitest): Promise<Plugin[]>;

declare function resolveConfig(options?: UserConfig$1, viteOverrides?: UserConfig): Promise<{
    vitestConfig: ResolvedConfig;
    viteConfig: ResolvedConfig$1;
}>;

declare function resolveFsAllow(projectRoot: string, rootConfigFile: string | false | undefined): string[];

interface MethodsOptions {
    cacheFs?: boolean;
    collect?: boolean;
}
declare function createMethodsRPC(project: TestProject, options?: MethodsOptions): RuntimeRPC;

declare class BaseSequencer implements TestSequencer {
    protected ctx: Vitest;
    constructor(ctx: Vitest);
    shard(files: TestSpecification[]): Promise<TestSpecification[]>;
    sort(files: TestSpecification[]): Promise<TestSpecification[]>;
}

declare function registerConsoleShortcuts(ctx: Vitest, stdin: NodeJS.ReadStream | undefined, stdout: NodeJS.WriteStream | Writable): () => void;

declare function createViteLogger(console: Logger, level?: LogLevel, options?: LoggerOptions): Logger$1;

declare const rootDir: string;
declare const distDir: string;

declare function createDebugger(namespace: `vitest:${string}`): Debugger | undefined;

declare const version: string;

/** @deprecated use `createViteServer` instead */
declare const createServer: typeof createServer$1;
declare const createViteServer: typeof createServer$1;

/**
 * @deprecated Use `TestModule` instead
 */
declare const TestFile: typeof TestModule;

/**
 * @deprecated Use `ModuleDiagnostic` instead
 */
type FileDiagnostic = ModuleDiagnostic;

export { ApiConfig, BaseSequencer, type CliParseOptions, type FileDiagnostic, GitNotFoundError, type GlobalSetupContext, ModuleDiagnostic, ResolvedConfig, TestFile, TestModule, TestProject, TestSequencer, TestSpecification, FilesNotFoundError as TestsNotFoundError, UserConfig$1 as UserConfig, Vitest, VitestOptions, VitestPlugin, VitestRunMode, TestProject as WorkspaceProject, createDebugger, createMethodsRPC, createServer, createViteLogger, createViteServer, createVitest, distDir, isValidApiRequest, parseCLI, registerConsoleShortcuts, resolveApiServerConfig, resolveConfig, resolveFsAllow, rootDir, startVitest, version };
