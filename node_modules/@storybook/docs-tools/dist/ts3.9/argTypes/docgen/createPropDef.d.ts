import { PropDef, TypeSystem, DocgenInfo } from './types';
import { JsDocParsingResult } from '../jsdocParser';
export declare type PropDefFactory = (propName: string, docgenInfo: DocgenInfo, jsDocParsingResult?: JsDocParsingResult) => PropDef;
export declare const javaScriptFactory: PropDefFactory;
export declare const tsFactory: PropDefFactory;
export declare const flowFactory: PropDefFactory;
export declare const unknownFactory: PropDefFactory;
export declare const getPropDefFactory: (typeSystem: TypeSystem) => PropDefFactory;
