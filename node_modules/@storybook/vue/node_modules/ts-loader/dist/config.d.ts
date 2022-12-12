import { Chalk } from 'chalk';
import type * as typescript from 'typescript';
import * as webpack from 'webpack';
import { LoaderOptions, WebpackError } from './interfaces';
import * as logger from './logger';
interface ConfigFile {
    config?: any;
    error?: typescript.Diagnostic;
}
export declare function getConfigFile(compiler: typeof typescript, colors: Chalk, loader: webpack.loader.LoaderContext, loaderOptions: LoaderOptions, compilerCompatible: boolean, log: logger.Logger, compilerDetailsLogMessage: string): {
    configFilePath: string | undefined;
    configFile: ConfigFile;
    configFileError: WebpackError | undefined;
};
export declare function getConfigParseResult(compiler: typeof typescript, configFile: ConfigFile, basePath: string, configFilePath: string | undefined, loaderOptions: LoaderOptions): typescript.ParsedCommandLine;
export declare function getParsedCommandLine(compiler: typeof typescript, loaderOptions: LoaderOptions, configFilePath: string): typescript.ParsedCommandLine | undefined;
export {};
//# sourceMappingURL=config.d.ts.map