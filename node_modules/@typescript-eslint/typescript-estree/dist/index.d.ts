export { AST, parse, parseAndGenerateServices, parseWithNodeMaps, ParseAndGenerateServicesResult, ParseWithNodeMapsResult, clearProgramCache, } from './parser';
export { ParserServices, TSESTreeOptions } from './parser-options';
export { simpleTraverse } from './simple-traverse';
export * from './ts-estree';
export { clearWatchCaches as clearCaches } from './create-program/createWatchProgram';
export { createProgramFromConfigFile as createProgram } from './create-program/useProvidedPrograms';
export * from './create-program/getScriptKind';
export { visitorKeys } from '@typescript-eslint/visitor-keys';
export declare const version: string;
//# sourceMappingURL=index.d.ts.map