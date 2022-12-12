import * as t from '@babel/types';
interface Meta {
    id?: string;
    title?: string;
    component?: string;
    includeStories?: string[] | RegExp;
    excludeStories?: string[] | RegExp;
}
interface Story {
    id: string;
    name: string;
    parameters: Record<string, any>;
}
export interface CsfOptions {
    fileName?: string;
    makeTitle: (userTitle: string) => string;
}
export declare class NoMetaError extends Error {
    constructor(ast: t.Node, fileName?: string);
}
export declare class CsfFile {
    _ast: t.File;
    _fileName: string;
    _makeTitle: (title: string) => string;
    _meta?: Meta;
    _stories: Record<string, Story>;
    _metaAnnotations: Record<string, t.Node>;
    _storyExports: Record<string, t.VariableDeclarator | t.FunctionDeclaration>;
    _storyAnnotations: Record<string, Record<string, t.Node>>;
    _templates: Record<string, t.Expression>;
    _namedExportsOrder?: string[];
    constructor(ast: t.File, { fileName, makeTitle }: CsfOptions);
    _parseTitle(value: t.Node): string;
    _parseMeta(declaration: t.ObjectExpression, program: t.Program): void;
    parse(): this;
    get meta(): Meta;
    get stories(): Story[];
}
export declare const loadCsf: (code: string, options: CsfOptions) => CsfFile;
export declare const formatCsf: (csf: CsfFile) => string;
export declare const readCsf: (fileName: string, options: CsfOptions) => Promise<CsfFile>;
export declare const writeCsf: (csf: CsfFile, fileName?: string) => Promise<void>;
export {};
