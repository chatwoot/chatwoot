import * as ts from 'typescript';
export declare type ResolveModuleName = (typescript: typeof ts, moduleName: string, containingFile: string, compilerOptions: ts.CompilerOptions, moduleResolutionHost: ts.ModuleResolutionHost) => ts.ResolvedModuleWithFailedLookupLocations;
export declare type ResolveTypeReferenceDirective = (typescript: typeof ts, typeDirectiveName: string, containingFile: string, compilerOptions: ts.CompilerOptions, moduleResolutionHost: ts.ModuleResolutionHost) => ts.ResolvedTypeReferenceDirectiveWithFailedLookupLocations;
export declare function makeResolutionFunctions(resolveModuleName: ResolveModuleName | undefined, resolveTypeReferenceDirective: ResolveTypeReferenceDirective | undefined): {
    resolveModuleName: ResolveModuleName;
    resolveTypeReferenceDirective: ResolveTypeReferenceDirective;
};
