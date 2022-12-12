import * as ts from 'typescript';
export interface TypeScriptPatchConfig {
    /**
     * Ususally, the compilerHost created with typescript.createWatchCompilerHost will bail out of diagnostics collection if there has been any syntactic error.
     * (see [`emitFilesAndReportErrors`](https://github.com/Microsoft/TypeScript/blob/89386ddda7dafc63cb35560e05412487f47cc267/src/compiler/watch.ts#L141) )
     * If this plugin is running with `checkSyntacticErrors: false`, this might lead to situations where no syntactic errors are reported within webpack
     * (because the file causing a syntactic error might not get processed by ts-loader), but there are semantic errors that would be missed due to this behavior.
     * This ensures that the compilerHost always assumes that there were no syntactic errors to be found and continues to check for semantic errors.
     */
    skipGetSyntacticDiagnostics: boolean;
}
/**
 * While it is often possible to pass a wrapped or modified copy of `typescript` or `typescript.sys` as a function argument to override/extend some typescript-internal behavior,
 * sometimes the typescript-internal code ignores these passed objects and directly references the internal `typescript` object reference.
 * In these situations, the only way of consistently overriding some behavior is to directly replace methods on the `typescript` object.
 *
 * So beware, this method directly modifies the passed `typescript` object!
 * @param typescript TypeScript instance to patch
 * @param config
 */
export declare function patchTypescript(typescript: typeof ts, config: TypeScriptPatchConfig): void;
