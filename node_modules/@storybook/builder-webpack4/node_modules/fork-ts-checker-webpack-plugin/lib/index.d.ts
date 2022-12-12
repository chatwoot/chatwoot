import { RpcProvider } from 'worker-rpc';
import { FormatterType, FormatterOptions } from './formatter';
import { VueOptions } from './types/vue-options';
import { Options as EslintOptions } from './types/eslint';
declare namespace ForkTsCheckerWebpackPlugin {
    interface Logger {
        error(message?: any): void;
        warn(message?: any): void;
        info(message?: any): void;
    }
    interface Options {
        typescript: string;
        tsconfig: string;
        compilerOptions: object;
        eslint: boolean;
        /** Options to supply to eslint https://eslint.org/docs/developer-guide/nodejs-api#cliengine */
        eslintOptions: EslintOptions;
        async: boolean;
        ignoreDiagnostics: number[];
        ignoreLints: string[];
        ignoreLintWarnings: boolean;
        reportFiles: string[];
        logger: Logger;
        formatter: FormatterType;
        formatterOptions: FormatterOptions;
        silent: boolean;
        checkSyntacticErrors: boolean;
        memoryLimit: number;
        vue: boolean | Partial<VueOptions>;
        useTypescriptIncrementalApi: boolean;
        measureCompilationTime: boolean;
        resolveModuleNameModule: string;
        resolveTypeReferenceDirectiveModule: string;
    }
}
/**
 * ForkTsCheckerWebpackPlugin
 * Runs typescript type checker and linter on separate process.
 * This speed-ups build a lot.
 *
 * Options description in README.md
 */
declare class ForkTsCheckerWebpackPlugin {
    static readonly DEFAULT_MEMORY_LIMIT = 2048;
    static getCompilerHooks(compiler: any): Record<import("./hooks").ForkTsCheckerHooks, import("tapable").SyncHook<any, any, any> | import("tapable").AsyncSeriesHook<any, any, any>>;
    readonly options: Partial<ForkTsCheckerWebpackPlugin.Options>;
    private tsconfig;
    private compilerOptions;
    private eslint;
    private eslintOptions;
    private ignoreDiagnostics;
    private ignoreLints;
    private ignoreLintWarnings;
    private reportFiles;
    private logger;
    private silent;
    private async;
    private checkSyntacticErrors;
    private memoryLimit;
    private formatter;
    private rawFormatter;
    private useTypescriptIncrementalApi;
    private resolveModuleNameModule;
    private resolveTypeReferenceDirectiveModule;
    private tsconfigPath;
    private compiler;
    private started;
    private elapsed;
    private cancellationToken;
    private isWatching;
    private checkDone;
    private compilationDone;
    private diagnostics;
    private lints;
    private emitCallback;
    private doneCallback;
    private typescriptPath;
    private typescript;
    private typescriptVersion;
    private eslintVersion;
    private service?;
    protected serviceRpc?: RpcProvider;
    private vue;
    private measureTime;
    private performance;
    private startAt;
    protected nodeArgs: string[];
    constructor(options?: Partial<ForkTsCheckerWebpackPlugin.Options>);
    private validateTypeScript;
    private validateEslint;
    private static prepareVueOptions;
    apply(compiler: any): void;
    private computeContextPath;
    private pluginStart;
    private pluginStop;
    private pluginCompile;
    private pluginEmit;
    private pluginDone;
    private spawnService;
    private killService;
    private handleServiceMessage;
    private handleServiceExit;
    private createEmitCallback;
    private createNoopEmitCallback;
    private printLoggerMessage;
    private createDoneCallback;
}
export = ForkTsCheckerWebpackPlugin;
