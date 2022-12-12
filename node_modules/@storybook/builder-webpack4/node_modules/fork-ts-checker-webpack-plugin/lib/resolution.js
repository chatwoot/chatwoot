"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
function makeResolutionFunctions(resolveModuleName, resolveTypeReferenceDirective) {
    resolveModuleName =
        resolveModuleName ||
            (function (typescript, moduleName, containingFile, compilerOptions, moduleResolutionHost) {
                return typescript.resolveModuleName(moduleName, containingFile, compilerOptions, moduleResolutionHost);
            });
    resolveTypeReferenceDirective =
        resolveTypeReferenceDirective ||
            (function (typescript, typeDirectiveName, containingFile, compilerOptions, moduleResolutionHost) {
                return typescript.resolveTypeReferenceDirective(typeDirectiveName, containingFile, compilerOptions, moduleResolutionHost);
            });
    return { resolveModuleName: resolveModuleName, resolveTypeReferenceDirective: resolveTypeReferenceDirective };
}
exports.makeResolutionFunctions = makeResolutionFunctions;
//# sourceMappingURL=resolution.js.map