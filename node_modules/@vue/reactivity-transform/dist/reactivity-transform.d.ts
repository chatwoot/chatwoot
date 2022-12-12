import MagicString from 'magic-string';
import { ParserPlugin } from '@babel/parser';
import { Program } from '@babel/types';
import { SourceMap } from 'magic-string';

export declare interface RefTransformOptions {
    filename?: string;
    sourceMap?: boolean;
    parserPlugins?: ParserPlugin[];
    importHelpersFrom?: string;
}

export declare interface RefTransformResults {
    code: string;
    map: SourceMap | null;
    rootRefs: string[];
    importedHelpers: string[];
}

export declare function shouldTransform(src: string): boolean;

export declare function transform(src: string, { filename, sourceMap, parserPlugins, importHelpersFrom }?: RefTransformOptions): RefTransformResults;

export declare function transformAST(ast: Program, s: MagicString, offset?: number, knownRefs?: string[], knownProps?: Record<string, // public prop key
    {
    local: string;
    default?: any;
}>): {
    rootRefs: string[];
    importedHelpers: string[];
};

export { }
