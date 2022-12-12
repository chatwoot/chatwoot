import * as ts from 'typescript';
import { CancellationToken } from './CancellationToken';
import { ResolveTypeReferenceDirective, ResolveModuleName } from './resolution';
import { createEslinter } from './createEslinter';
import { Issue } from './issue';
import { VueOptions } from './types/vue-options';
export interface IncrementalCheckerInterface {
    nextIteration(): void;
    hasEsLinter(): boolean;
    getTypeScriptIssues(cancellationToken: CancellationToken): Promise<Issue[]>;
    getEsLintIssues(cancellationToken: CancellationToken): Promise<Issue[]>;
}
export interface IncrementalCheckerParams {
    typescript: typeof ts;
    context: string;
    programConfigFile: string;
    compilerOptions: ts.CompilerOptions;
    eslinter: ReturnType<typeof createEslinter> | undefined;
    checkSyntacticErrors: boolean;
    resolveModuleName: ResolveModuleName | undefined;
    resolveTypeReferenceDirective: ResolveTypeReferenceDirective | undefined;
    vue: VueOptions;
}
