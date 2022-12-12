import * as ts from 'typescript';
import { IncrementalCheckerInterface, IncrementalCheckerParams } from './IncrementalCheckerInterface';
import { CancellationToken } from './CancellationToken';
import { CompilerHost } from './CompilerHost';
export declare class ApiIncrementalChecker implements IncrementalCheckerInterface {
    protected readonly tsIncrementalCompiler: CompilerHost;
    protected readonly typescript: typeof ts;
    private currentEsLintErrors;
    private lastUpdatedFiles;
    private lastRemovedFiles;
    private readonly eslinter;
    constructor({ typescript, programConfigFile, compilerOptions, eslinter, vue, checkSyntacticErrors, resolveModuleName, resolveTypeReferenceDirective }: IncrementalCheckerParams);
    hasEsLinter(): boolean;
    isFileExcluded(filePath: string): boolean;
    nextIteration(): void;
    getTypeScriptIssues(): Promise<import("./issue/Issue").Issue[]>;
    getEsLintIssues(cancellationToken: CancellationToken): Promise<import("./issue/Issue").Issue[]>;
}
