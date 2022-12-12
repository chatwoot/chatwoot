"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
/**
 * Overrides the [`typescript.createEmitAndSemanticDiagnosticsBuilderProgram`](https://github.com/Microsoft/TypeScript/blob/89386ddda7dafc63cb35560e05412487f47cc267/src/compiler/builder.ts#L1176)
 * method to return a `ts.Program` instance that does not emit syntactic errors,
 * to prevent the [`typescript.createWatchCompilerHost`](https://github.com/Microsoft/TypeScript/blob/89386ddda7dafc63cb35560e05412487f47cc267/src/compiler/watch.ts#L333)
 * method from bailing during diagnostic collection in the [`emitFilesAndReportErrors`](https://github.com/Microsoft/TypeScript/blob/89386ddda7dafc63cb35560e05412487f47cc267/src/compiler/watch.ts#L141) callback.
 *
 * See the description of TypeScriptPatchConfig.skipGetSyntacticDiagnostics and
 * [this github discussion](https://github.com/TypeStrong/fork-ts-checker-webpack-plugin/issues/257#issuecomment-485414182)
 * for further information on this problem & solution.
 */
function patchSkipGetSyntacticDiagnostics(typescript) {
    var originalCreateEmitAndSemanticDiagnosticsBuilderProgram = typescript.createEmitAndSemanticDiagnosticsBuilderProgram;
    var patchedMethods = {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        createEmitAndSemanticDiagnosticsBuilderProgram: function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            var program = originalCreateEmitAndSemanticDiagnosticsBuilderProgram.apply(typescript, 
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            args);
            program.getSyntacticDiagnostics = function () { return []; };
            return program;
        }
    };
    // directly patch the typescript object!
    Object.assign(typescript, patchedMethods);
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
function patchTypescript(typescript, config) {
    if (config.skipGetSyntacticDiagnostics) {
        patchSkipGetSyntacticDiagnostics(typescript);
    }
}
exports.patchTypescript = patchTypescript;
//# sourceMappingURL=patchTypescript.js.map