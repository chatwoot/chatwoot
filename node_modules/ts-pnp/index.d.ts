import * as ts from 'typescript';

export declare function resolveModuleName(
  moduleName: string,
  containingFile: string,
  options: ts.CompilerOptions,
  moduleResolutionHost: ts.ModuleResolutionHost,

  realResolveModuleName: (
    moduleName: string,
    containingFile: string,
    options: ts.CompilerOptions,
    moduleResolutionHost: ts.ResolvedModuleWithFailedLookupLocations,
  ) => ts.ResolvedModuleWithFailedLookupLocations,
): ts.ResolvedModuleWithFailedLookupLocations;

export declare function resolveModuleName(
  moduleName: string,
  containingFile: string,
  options: ts.CompilerOptions,
  moduleResolutionHost: ts.ModuleResolutionHost,

  realResolveModuleName: (
    moduleName: string,
    containingFile: string,
    options: ts.CompilerOptions,
    moduleResolutionHost: ts.ModuleResolutionHost,
  ) => ts.ResolvedTypeReferenceDirectiveWithFailedLookupLocations,
): ts.ResolvedTypeReferenceDirectiveWithFailedLookupLocations;
