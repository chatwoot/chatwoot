import { CodegenResult } from '@vue/compiler-core';
import { CompilerError } from '@vue/compiler-core';
import { CompilerOptions } from '@vue/compiler-core';
import { DirectiveTransform } from '@vue/compiler-core';
import { NodeTransform } from '@vue/compiler-core';
import { ParserOptions } from '@vue/compiler-core';
import { RootNode } from '@vue/compiler-core';
import { SourceLocation } from '@vue/compiler-core';

export declare function compile(template: string, options?: CompilerOptions): CodegenResult;

export declare function createDOMCompilerError(code: DOMErrorCodes, loc?: SourceLocation): DOMCompilerError;

declare interface DOMCompilerError extends CompilerError {
    code: DOMErrorCodes;
}

export declare const DOMDirectiveTransforms: Record<string, DirectiveTransform>;

export declare const enum DOMErrorCodes {
    X_V_HTML_NO_EXPRESSION = 50,
    X_V_HTML_WITH_CHILDREN = 51,
    X_V_TEXT_NO_EXPRESSION = 52,
    X_V_TEXT_WITH_CHILDREN = 53,
    X_V_MODEL_ON_INVALID_ELEMENT = 54,
    X_V_MODEL_ARG_ON_ELEMENT = 55,
    X_V_MODEL_ON_FILE_INPUT_ELEMENT = 56,
    X_V_MODEL_UNNECESSARY_VALUE = 57,
    X_V_SHOW_NO_EXPRESSION = 58,
    X_TRANSITION_INVALID_CHILDREN = 59,
    X_IGNORED_SIDE_EFFECT_TAG = 60,
    __EXTEND_POINT__ = 61
}

export declare const DOMNodeTransforms: NodeTransform[];

export declare function parse(template: string, options?: ParserOptions): RootNode;

export declare const parserOptions: ParserOptions;

export declare const transformStyle: NodeTransform;

export declare const TRANSITION: unique symbol;

export declare const TRANSITION_GROUP: unique symbol;

export declare const V_MODEL_CHECKBOX: unique symbol;

export declare const V_MODEL_DYNAMIC: unique symbol;

export declare const V_MODEL_RADIO: unique symbol;

export declare const V_MODEL_SELECT: unique symbol;

export declare const V_MODEL_TEXT: unique symbol;

export declare const V_ON_WITH_KEYS: unique symbol;

export declare const V_ON_WITH_MODIFIERS: unique symbol;

export declare const V_SHOW: unique symbol;


export * from "@vue/compiler-core";

export { }
