import type * as typescript from 'typescript';
import { LoaderOptions } from './interfaces';
import * as logger from './logger';
export declare function getCompiler(loaderOptions: LoaderOptions, log: logger.Logger): {
    compiler: typeof typescript | undefined;
    compilerCompatible: boolean;
    compilerDetailsLogMessage: string | undefined;
    errorMessage: string | undefined;
};
export declare function getCompilerOptions(configParseResult: typescript.ParsedCommandLine, compiler: typeof typescript): typescript.CompilerOptions;
//# sourceMappingURL=compilerSetup.d.ts.map