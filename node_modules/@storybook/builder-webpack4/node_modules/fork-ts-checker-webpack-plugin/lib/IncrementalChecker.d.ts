import * as ts from 'typescript';
import { CancellationToken } from './CancellationToken';
import { IncrementalCheckerInterface, IncrementalCheckerParams } from './IncrementalCheckerInterface';
import { Issue } from './issue';
export declare class IncrementalChecker implements IncrementalCheckerInterface {
    private files;
    protected program?: ts.Program;
    protected programConfig?: ts.ParsedCommandLine;
    private readonly typescript;
    private readonly programConfigFile;
    private readonly compilerOptions;
    private readonly eslinter;
    private readonly vue;
    private readonly checkSyntacticErrors;
    private readonly resolveModuleName;
    private readonly resolveTypeReferenceDirective;
    constructor({ typescript, programConfigFile, compilerOptions, eslinter, vue, checkSyntacticErrors, resolveModuleName, resolveTypeReferenceDirective }: IncrementalCheckerParams);
    static loadProgramConfig(typescript: typeof ts, configFile: string, compilerOptions: object): ts.ParsedCommandLine;
    private static createProgram;
    hasEsLinter(): boolean;
    static isFileExcluded(filePath: string): boolean;
    nextIteration(): void;
    private loadVueProgram;
    private loadDefaultProgram;
    getTypeScriptIssues(cancellationToken: CancellationToken): Promise<Issue[]>;
    getEsLintIssues(cancellationToken: CancellationToken): Promise<Issue[]>;
}
