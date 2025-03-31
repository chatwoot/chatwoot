import { ImportSpecifier, ImportDefaultSpecifier, ImportNamespaceSpecifier, Program } from '@babel/types';
import MagicString, { SourceMap } from 'magic-string';
import { ParserPlugin } from '@babel/parser';

/**
 * @deprecated will be removed in 3.4
 */
export declare function shouldTransform(src: string): boolean;
export interface RefTransformOptions {
    filename?: string;
    sourceMap?: boolean;
    parserPlugins?: ParserPlugin[];
    importHelpersFrom?: string;
}
export interface RefTransformResults {
    code: string;
    map: SourceMap | null;
    rootRefs: string[];
    importedHelpers: string[];
}
export interface ImportBinding {
    local: string;
    imported: string;
    source: string;
    specifier: ImportSpecifier | ImportDefaultSpecifier | ImportNamespaceSpecifier;
}
/**
 * @deprecated will be removed in 3.4
 */
export declare function transform(src: string, { filename, sourceMap, parserPlugins, importHelpersFrom }?: RefTransformOptions): RefTransformResults;
/**
 * @deprecated will be removed in 3.4
 */
export declare function transformAST(ast: Program, s: MagicString, offset?: number, knownRefs?: string[], knownProps?: Record<string, // public prop key
{
    local: string;
    default?: any;
    isConst?: boolean;
}>): {
    rootRefs: string[];
    importedHelpers: string[];
};

