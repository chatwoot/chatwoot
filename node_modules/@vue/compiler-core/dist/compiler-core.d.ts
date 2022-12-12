import type { BlockStatement as BlockStatement_2 } from '@babel/types';
import type { Function as Function_2 } from '@babel/types';
import { generateCodeFrame } from '@vue/shared';
import type { Identifier } from '@babel/types';
import type { Node as Node_3 } from '@babel/types';
import type { ObjectProperty } from '@babel/types';
import { ParserPlugin } from '@babel/parser';
import type { Program } from '@babel/types';
import { RawSourceMap } from 'source-map';
import { SourceMapGenerator } from 'source-map';

export declare function advancePositionWithClone(pos: Position, source: string, numberOfCharacters?: number): Position;

export declare function advancePositionWithMutation(pos: Position, source: string, numberOfCharacters?: number): Position;

export declare interface ArrayExpression extends Node_2 {
    type: NodeTypes.JS_ARRAY_EXPRESSION;
    elements: Array<string | Node_2>;
}

export declare function assert(condition: boolean, msg?: string): void;

export declare interface AssignmentExpression extends Node_2 {
    type: NodeTypes.JS_ASSIGNMENT_EXPRESSION;
    left: SimpleExpressionNode;
    right: JSChildNode;
}

export declare interface AttributeNode extends Node_2 {
    type: NodeTypes.ATTRIBUTE;
    name: string;
    value: TextNode | undefined;
}

export declare const BASE_TRANSITION: unique symbol;

export declare function baseCompile(template: string | RootNode, options?: CompilerOptions): CodegenResult;

export declare interface BaseElementNode extends Node_2 {
    type: NodeTypes.ELEMENT;
    ns: Namespace;
    tag: string;
    tagType: ElementTypes;
    isSelfClosing: boolean;
    props: Array<AttributeNode | DirectiveNode>;
    children: TemplateChildNode[];
}

export declare function baseParse(content: string, options?: ParserOptions): RootNode;

export declare type BindingMetadata = {
    [key: string]: BindingTypes | undefined;
} & {
    __isScriptSetup?: boolean;
    __propsAliases?: Record<string, string>;
};

export declare const enum BindingTypes {
    /**
     * returned from data()
     */
    DATA = "data",
    /**
     * declared as a prop
     */
    PROPS = "props",
    /**
     * a local alias of a `<script setup>` destructured prop.
     * the original is stored in __propsAliases of the bindingMetadata object.
     */
    PROPS_ALIASED = "props-aliased",
    /**
     * a let binding (may or may not be a ref)
     */
    SETUP_LET = "setup-let",
    /**
     * a const binding that can never be a ref.
     * these bindings don't need `unref()` calls when processed in inlined
     * template expressions.
     */
    SETUP_CONST = "setup-const",
    /**
     * a const binding that does not need `unref()`, but may be mutated.
     */
    SETUP_REACTIVE_CONST = "setup-reactive-const",
    /**
     * a const binding that may be a ref.
     */
    SETUP_MAYBE_REF = "setup-maybe-ref",
    /**
     * bindings that are guaranteed to be refs
     */
    SETUP_REF = "setup-ref",
    /**
     * declared by other options, e.g. computed, inject
     */
    OPTIONS = "options"
}

export declare type BlockCodegenNode = VNodeCall | RenderSlotCall;

export declare interface BlockStatement extends Node_2 {
    type: NodeTypes.JS_BLOCK_STATEMENT;
    body: (JSChildNode | IfStatement)[];
}

export declare function buildDirectiveArgs(dir: DirectiveNode, context: TransformContext): ArrayExpression;

export declare function buildProps(node: ElementNode, context: TransformContext, props: (DirectiveNode | AttributeNode)[] | undefined, isComponent: boolean, isDynamicComponent: boolean, ssr?: boolean): {
    props: PropsExpression | undefined;
    directives: DirectiveNode[];
    patchFlag: number;
    dynamicPropNames: string[];
    shouldUseBlock: boolean;
};

export declare function buildSlots(node: ElementNode, context: TransformContext, buildSlotFn?: SlotFnBuilder): {
    slots: SlotsExpression;
    hasDynamicSlots: boolean;
};

export declare interface CacheExpression extends Node_2 {
    type: NodeTypes.JS_CACHE_EXPRESSION;
    index: number;
    value: JSChildNode;
    isVNode: boolean;
}

export declare interface CallExpression extends Node_2 {
    type: NodeTypes.JS_CALL_EXPRESSION;
    callee: string | symbol;
    arguments: (string | symbol | JSChildNode | SSRCodegenNode | TemplateChildNode | TemplateChildNode[])[];
}

export declare const CAMELIZE: unique symbol;

export declare const CAPITALIZE: unique symbol;

export declare function checkCompatEnabled(key: CompilerDeprecationTypes, context: ParserContext | TransformContext, loc: SourceLocation | null, ...args: any[]): boolean;

export declare interface CodegenContext extends Omit<Required<CodegenOptions>, 'bindingMetadata' | 'inline'> {
    source: string;
    code: string;
    line: number;
    column: number;
    offset: number;
    indentLevel: number;
    pure: boolean;
    map?: SourceMapGenerator;
    helper(key: symbol): string;
    push(code: string, node?: CodegenNode): void;
    indent(): void;
    deindent(withoutNewLine?: boolean): void;
    newline(): void;
}

declare type CodegenNode = TemplateChildNode | JSChildNode | SSRCodegenNode;

export declare interface CodegenOptions extends SharedTransformCodegenOptions {
    /**
     * - `module` mode will generate ES module import statements for helpers
     * and export the render function as the default export.
     * - `function` mode will generate a single `const { helpers... } = Vue`
     * statement and return the render function. It expects `Vue` to be globally
     * available (or passed by wrapping the code with an IIFE). It is meant to be
     * used with `new Function(code)()` to generate a render function at runtime.
     * @default 'function'
     */
    mode?: 'module' | 'function';
    /**
     * Generate source map?
     * @default false
     */
    sourceMap?: boolean;
    /**
     * SFC scoped styles ID
     */
    scopeId?: string | null;
    /**
     * Option to optimize helper import bindings via variable assignment
     * (only used for webpack code-split)
     * @default false
     */
    optimizeImports?: boolean;
    /**
     * Customize where to import runtime helpers from.
     * @default 'vue'
     */
    runtimeModuleName?: string;
    /**
     * Customize where to import ssr runtime helpers from/**
     * @default 'vue/server-renderer'
     */
    ssrRuntimeModuleName?: string;
    /**
     * Customize the global variable name of `Vue` to get helpers from
     * in function mode
     * @default 'Vue'
     */
    runtimeGlobalName?: string;
}

export declare interface CodegenResult {
    code: string;
    preamble: string;
    ast: RootNode;
    map?: RawSourceMap;
}

export declare interface CommentNode extends Node_2 {
    type: NodeTypes.COMMENT;
    content: string;
}

declare type CompilerCompatConfig = Partial<Record<CompilerDeprecationTypes, boolean | 'suppress-warning'>> & {
    MODE?: 2 | 3;
};

declare interface CompilerCompatOptions {
    compatConfig?: CompilerCompatConfig;
}

export declare const enum CompilerDeprecationTypes {
    COMPILER_IS_ON_ELEMENT = "COMPILER_IS_ON_ELEMENT",
    COMPILER_V_BIND_SYNC = "COMPILER_V_BIND_SYNC",
    COMPILER_V_BIND_PROP = "COMPILER_V_BIND_PROP",
    COMPILER_V_BIND_OBJECT_ORDER = "COMPILER_V_BIND_OBJECT_ORDER",
    COMPILER_V_ON_NATIVE = "COMPILER_V_ON_NATIVE",
    COMPILER_V_IF_V_FOR_PRECEDENCE = "COMPILER_V_IF_V_FOR_PRECEDENCE",
    COMPILER_NATIVE_TEMPLATE = "COMPILER_NATIVE_TEMPLATE",
    COMPILER_INLINE_TEMPLATE = "COMPILER_INLINE_TEMPLATE",
    COMPILER_FILTERS = "COMPILER_FILTER"
}

export declare interface CompilerError extends SyntaxError {
    code: number | string;
    loc?: SourceLocation;
}

export declare type CompilerOptions = ParserOptions & TransformOptions & CodegenOptions;

export declare interface ComponentNode extends BaseElementNode {
    tagType: ElementTypes.COMPONENT;
    codegenNode: VNodeCall | CacheExpression | MemoExpression | undefined;
    ssrCodegenNode?: CallExpression;
}

export declare interface CompoundExpressionNode extends Node_2 {
    type: NodeTypes.COMPOUND_EXPRESSION;
    children: (SimpleExpressionNode | CompoundExpressionNode | InterpolationNode | TextNode | string | symbol)[];
    /**
     * an expression parsed as the params of a function will track
     * the identifiers declared inside the function body.
     */
    identifiers?: string[];
    isHandlerKey?: boolean;
}

export declare interface ConditionalDynamicSlotNode extends ConditionalExpression {
    consequent: DynamicSlotNode;
    alternate: DynamicSlotNode | SimpleExpressionNode;
}

export declare interface ConditionalExpression extends Node_2 {
    type: NodeTypes.JS_CONDITIONAL_EXPRESSION;
    test: JSChildNode;
    consequent: JSChildNode;
    alternate: JSChildNode;
    newline: boolean;
}

/**
 * Static types have several levels.
 * Higher levels implies lower levels. e.g. a node that can be stringified
 * can always be hoisted and skipped for patch.
 */
export declare const enum ConstantTypes {
    NOT_CONSTANT = 0,
    CAN_SKIP_PATCH = 1,
    CAN_HOIST = 2,
    CAN_STRINGIFY = 3
}

export declare interface CoreCompilerError extends CompilerError {
    code: ErrorCodes;
}

export declare const CREATE_BLOCK: unique symbol;

export declare const CREATE_COMMENT: unique symbol;

export declare const CREATE_ELEMENT_BLOCK: unique symbol;

export declare const CREATE_ELEMENT_VNODE: unique symbol;

export declare const CREATE_SLOTS: unique symbol;

export declare const CREATE_STATIC: unique symbol;

export declare const CREATE_TEXT: unique symbol;

export declare const CREATE_VNODE: unique symbol;

export declare function createArrayExpression(elements: ArrayExpression['elements'], loc?: SourceLocation): ArrayExpression;

export declare function createAssignmentExpression(left: AssignmentExpression['left'], right: AssignmentExpression['right']): AssignmentExpression;

export declare function createBlockStatement(body: BlockStatement['body']): BlockStatement;

export declare function createCacheExpression(index: number, value: JSChildNode, isVNode?: boolean): CacheExpression;

export declare function createCallExpression<T extends CallExpression['callee']>(callee: T, args?: CallExpression['arguments'], loc?: SourceLocation): InferCodegenNodeType<T>;

export declare function createCompilerError<T extends number>(code: T, loc?: SourceLocation, messages?: {
    [code: number]: string;
}, additionalMessage?: string): InferCompilerError<T>;

export declare function createCompoundExpression(children: CompoundExpressionNode['children'], loc?: SourceLocation): CompoundExpressionNode;

export declare function createConditionalExpression(test: ConditionalExpression['test'], consequent: ConditionalExpression['consequent'], alternate: ConditionalExpression['alternate'], newline?: boolean): ConditionalExpression;

export declare function createForLoopParams({ value, key, index }: ForParseResult, memoArgs?: ExpressionNode[]): ExpressionNode[];

export declare function createFunctionExpression(params: FunctionExpression['params'], returns?: FunctionExpression['returns'], newline?: boolean, isSlot?: boolean, loc?: SourceLocation): FunctionExpression;

export declare function createIfStatement(test: IfStatement['test'], consequent: IfStatement['consequent'], alternate?: IfStatement['alternate']): IfStatement;

export declare function createInterpolation(content: InterpolationNode['content'] | string, loc: SourceLocation): InterpolationNode;

export declare function createObjectExpression(properties: ObjectExpression['properties'], loc?: SourceLocation): ObjectExpression;

export declare function createObjectProperty(key: Property['key'] | string, value: Property['value']): Property;

export declare function createReturnStatement(returns: ReturnStatement['returns']): ReturnStatement;

export declare function createRoot(children: TemplateChildNode[], loc?: SourceLocation): RootNode;

export declare function createSequenceExpression(expressions: SequenceExpression['expressions']): SequenceExpression;

export declare function createSimpleExpression(content: SimpleExpressionNode['content'], isStatic?: SimpleExpressionNode['isStatic'], loc?: SourceLocation, constType?: ConstantTypes): SimpleExpressionNode;

export declare function createStructuralDirectiveTransform(name: string | RegExp, fn: StructuralDirectiveTransform): NodeTransform;

export declare function createTemplateLiteral(elements: TemplateLiteral['elements']): TemplateLiteral;

export declare function createTransformContext(root: RootNode, { filename, prefixIdentifiers, hoistStatic, cacheHandlers, nodeTransforms, directiveTransforms, transformHoist, isBuiltInComponent, isCustomElement, expressionPlugins, scopeId, slotted, ssr, inSSR, ssrCssVars, bindingMetadata, inline, isTS, onError, onWarn, compatConfig }: TransformOptions): TransformContext;

export declare function createVNodeCall(context: TransformContext | null, tag: VNodeCall['tag'], props?: VNodeCall['props'], children?: VNodeCall['children'], patchFlag?: VNodeCall['patchFlag'], dynamicProps?: VNodeCall['dynamicProps'], directives?: VNodeCall['directives'], isBlock?: VNodeCall['isBlock'], disableTracking?: VNodeCall['disableTracking'], isComponent?: VNodeCall['isComponent'], loc?: SourceLocation): VNodeCall;

export declare interface DirectiveArgumentNode extends ArrayExpression {
    elements: [string] | [string, ExpressionNode] | [string, ExpressionNode, ExpressionNode] | [string, ExpressionNode, ExpressionNode, ObjectExpression];
}

export declare interface DirectiveArguments extends ArrayExpression {
    elements: DirectiveArgumentNode[];
}

export declare interface DirectiveNode extends Node_2 {
    type: NodeTypes.DIRECTIVE;
    name: string;
    exp: ExpressionNode | undefined;
    arg: ExpressionNode | undefined;
    modifiers: string[];
    /**
     * optional property to cache the expression parse result for v-for
     */
    parseResult?: ForParseResult;
}

export declare type DirectiveTransform = (dir: DirectiveNode, node: ElementNode, context: TransformContext, augmentor?: (ret: DirectiveTransformResult) => DirectiveTransformResult) => DirectiveTransformResult;

declare interface DirectiveTransformResult {
    props: Property[];
    needRuntime?: boolean | symbol;
    ssrTagParts?: TemplateLiteral['elements'];
}

export declare interface DynamicSlotEntries extends ArrayExpression {
    elements: (ConditionalDynamicSlotNode | ListDynamicSlotNode)[];
}

export declare interface DynamicSlotFnProperty extends Property {
    value: SlotFunctionExpression;
}

export declare interface DynamicSlotNode extends ObjectExpression {
    properties: [Property, DynamicSlotFnProperty];
}

export declare interface DynamicSlotsExpression extends CallExpression {
    callee: typeof CREATE_SLOTS;
    arguments: [SlotsObjectExpression, DynamicSlotEntries];
}

export declare type ElementNode = PlainElementNode | ComponentNode | SlotOutletNode | TemplateNode;

export declare const enum ElementTypes {
    ELEMENT = 0,
    COMPONENT = 1,
    SLOT = 2,
    TEMPLATE = 3
}

export declare const enum ErrorCodes {
    ABRUPT_CLOSING_OF_EMPTY_COMMENT = 0,
    CDATA_IN_HTML_CONTENT = 1,
    DUPLICATE_ATTRIBUTE = 2,
    END_TAG_WITH_ATTRIBUTES = 3,
    END_TAG_WITH_TRAILING_SOLIDUS = 4,
    EOF_BEFORE_TAG_NAME = 5,
    EOF_IN_CDATA = 6,
    EOF_IN_COMMENT = 7,
    EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT = 8,
    EOF_IN_TAG = 9,
    INCORRECTLY_CLOSED_COMMENT = 10,
    INCORRECTLY_OPENED_COMMENT = 11,
    INVALID_FIRST_CHARACTER_OF_TAG_NAME = 12,
    MISSING_ATTRIBUTE_VALUE = 13,
    MISSING_END_TAG_NAME = 14,
    MISSING_WHITESPACE_BETWEEN_ATTRIBUTES = 15,
    NESTED_COMMENT = 16,
    UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME = 17,
    UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE = 18,
    UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME = 19,
    UNEXPECTED_NULL_CHARACTER = 20,
    UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME = 21,
    UNEXPECTED_SOLIDUS_IN_TAG = 22,
    X_INVALID_END_TAG = 23,
    X_MISSING_END_TAG = 24,
    X_MISSING_INTERPOLATION_END = 25,
    X_MISSING_DIRECTIVE_NAME = 26,
    X_MISSING_DYNAMIC_DIRECTIVE_ARGUMENT_END = 27,
    X_V_IF_NO_EXPRESSION = 28,
    X_V_IF_SAME_KEY = 29,
    X_V_ELSE_NO_ADJACENT_IF = 30,
    X_V_FOR_NO_EXPRESSION = 31,
    X_V_FOR_MALFORMED_EXPRESSION = 32,
    X_V_FOR_TEMPLATE_KEY_PLACEMENT = 33,
    X_V_BIND_NO_EXPRESSION = 34,
    X_V_ON_NO_EXPRESSION = 35,
    X_V_SLOT_UNEXPECTED_DIRECTIVE_ON_SLOT_OUTLET = 36,
    X_V_SLOT_MIXED_SLOT_USAGE = 37,
    X_V_SLOT_DUPLICATE_SLOT_NAMES = 38,
    X_V_SLOT_EXTRANEOUS_DEFAULT_SLOT_CHILDREN = 39,
    X_V_SLOT_MISPLACED = 40,
    X_V_MODEL_NO_EXPRESSION = 41,
    X_V_MODEL_MALFORMED_EXPRESSION = 42,
    X_V_MODEL_ON_SCOPE_VARIABLE = 43,
    X_INVALID_EXPRESSION = 44,
    X_KEEP_ALIVE_INVALID_CHILDREN = 45,
    X_PREFIX_ID_NOT_SUPPORTED = 46,
    X_MODULE_MODE_NOT_SUPPORTED = 47,
    X_CACHE_HANDLER_NOT_SUPPORTED = 48,
    X_SCOPE_ID_NOT_SUPPORTED = 49,
    __EXTEND_POINT__ = 50
}

declare interface ErrorHandlingOptions {
    onWarn?: (warning: CompilerError) => void;
    onError?: (error: CompilerError) => void;
}

export declare type ExpressionNode = SimpleExpressionNode | CompoundExpressionNode;

export declare function extractIdentifiers(param: Node_3, nodes?: Identifier[]): Identifier[];

export declare function findDir(node: ElementNode, name: string | RegExp, allowEmpty?: boolean): DirectiveNode | undefined;

export declare function findProp(node: ElementNode, name: string, dynamicOnly?: boolean, allowEmpty?: boolean): ElementNode['props'][0] | undefined;

export declare interface ForCodegenNode extends VNodeCall {
    isBlock: true;
    tag: typeof FRAGMENT;
    props: undefined;
    children: ForRenderListExpression;
    patchFlag: string;
    disableTracking: boolean;
}

export declare interface ForIteratorExpression extends FunctionExpression {
    returns: BlockCodegenNode;
}

export declare interface ForNode extends Node_2 {
    type: NodeTypes.FOR;
    source: ExpressionNode;
    valueAlias: ExpressionNode | undefined;
    keyAlias: ExpressionNode | undefined;
    objectIndexAlias: ExpressionNode | undefined;
    parseResult: ForParseResult;
    children: TemplateChildNode[];
    codegenNode?: ForCodegenNode;
}

declare interface ForParseResult {
    source: ExpressionNode;
    value: ExpressionNode | undefined;
    key: ExpressionNode | undefined;
    index: ExpressionNode | undefined;
}

export declare interface ForRenderListExpression extends CallExpression {
    callee: typeof RENDER_LIST;
    arguments: [ExpressionNode, ForIteratorExpression];
}

export declare const FRAGMENT: unique symbol;

export declare interface FunctionExpression extends Node_2 {
    type: NodeTypes.JS_FUNCTION_EXPRESSION;
    params: ExpressionNode | string | (ExpressionNode | string)[] | undefined;
    returns?: TemplateChildNode | TemplateChildNode[] | JSChildNode;
    body?: BlockStatement | IfStatement;
    newline: boolean;
    /**
     * This flag is for codegen to determine whether it needs to generate the
     * withScopeId() wrapper
     */
    isSlot: boolean;
    /**
     * __COMPAT__ only, indicates a slot function that should be excluded from
     * the legacy $scopedSlots instance property.
     */
    isNonScopedSlot?: boolean;
}

export declare function generate(ast: RootNode, options?: CodegenOptions & {
    onContextCreated?: (context: CodegenContext) => void;
}): CodegenResult;

export { generateCodeFrame }

export declare function getBaseTransformPreset(prefixIdentifiers?: boolean): TransformPreset;

export declare function getConstantType(node: TemplateChildNode | SimpleExpressionNode, context: TransformContext): ConstantTypes;

export declare function getInnerRange(loc: SourceLocation, offset: number, length: number): SourceLocation;

export declare function getMemoedVNodeCall(node: BlockCodegenNode | MemoExpression): VNodeCall | RenderSlotCall;

export declare function getVNodeBlockHelper(ssr: boolean, isComponent: boolean): typeof CREATE_BLOCK | typeof CREATE_ELEMENT_BLOCK;

export declare function getVNodeHelper(ssr: boolean, isComponent: boolean): typeof CREATE_VNODE | typeof CREATE_ELEMENT_VNODE;

export declare const GUARD_REACTIVE_PROPS: unique symbol;

export declare function hasDynamicKeyVBind(node: ElementNode): boolean;

export declare function hasScopeRef(node: TemplateChildNode | IfBranchNode | ExpressionNode | undefined, ids: TransformContext['identifiers']): boolean;

export declare const helperNameMap: any;

export declare type HoistTransform = (children: TemplateChildNode[], context: TransformContext, parent: ParentNode_2) => void;

export declare interface IfBranchNode extends Node_2 {
    type: NodeTypes.IF_BRANCH;
    condition: ExpressionNode | undefined;
    children: TemplateChildNode[];
    userKey?: AttributeNode | DirectiveNode;
    isTemplateIf?: boolean;
}

export declare interface IfConditionalExpression extends ConditionalExpression {
    consequent: BlockCodegenNode | MemoExpression;
    alternate: BlockCodegenNode | IfConditionalExpression | MemoExpression;
}

export declare interface IfNode extends Node_2 {
    type: NodeTypes.IF;
    branches: IfBranchNode[];
    codegenNode?: IfConditionalExpression | CacheExpression;
}

export declare interface IfStatement extends Node_2 {
    type: NodeTypes.JS_IF_STATEMENT;
    test: ExpressionNode;
    consequent: BlockStatement;
    alternate: IfStatement | BlockStatement | ReturnStatement | undefined;
}

declare interface ImportItem {
    exp: string | ExpressionNode;
    path: string;
}

declare type InferCodegenNodeType<T> = T extends typeof RENDER_SLOT ? RenderSlotCall : CallExpression;

declare type InferCompilerError<T> = T extends ErrorCodes ? CoreCompilerError : CompilerError;

export declare function injectProp(node: VNodeCall | RenderSlotCall, prop: Property, context: TransformContext): void;

export declare interface InterpolationNode extends Node_2 {
    type: NodeTypes.INTERPOLATION;
    content: ExpressionNode;
}

export declare const IS_MEMO_SAME: unique symbol;

export declare const IS_REF: unique symbol;

export declare const isBuiltInType: (tag: string, expected: string) => boolean;

export declare function isCoreComponent(tag: string): symbol | void;

export declare const isFunctionType: (node: Node_3) => node is Function_2;

export declare function isInDestructureAssignment(parent: Node_3, parentStack: Node_3[]): boolean;

export declare const isMemberExpression: (path: string, context: TransformContext) => boolean;

/**
 * Simple lexer to check if an expression is a member expression. This is
 * lax and only checks validity at the root level (i.e. does not validate exps
 * inside square brackets), but it's ok since these are only used on template
 * expressions and false positives are invalid expressions in the first place.
 */
export declare const isMemberExpressionBrowser: (path: string) => boolean;

export declare const isMemberExpressionNode: (path: string, context: TransformContext) => boolean;

export declare function isReferencedIdentifier(id: Identifier, parent: Node_3 | null, parentStack: Node_3[]): boolean;

export declare const isSimpleIdentifier: (name: string) => boolean;

export declare function isSlotOutlet(node: RootNode | TemplateChildNode): node is SlotOutletNode;

export declare function isStaticArgOf(arg: DirectiveNode['arg'], name: string): boolean;

export declare const isStaticExp: (p: JSChildNode) => p is SimpleExpressionNode;

export declare const isStaticProperty: (node: Node_3) => node is ObjectProperty;

export declare const isStaticPropertyKey: (node: Node_3, parent: Node_3) => boolean;

export declare function isTemplateNode(node: RootNode | TemplateChildNode): node is TemplateNode;

export declare function isText(node: TemplateChildNode): node is TextNode | InterpolationNode;

export declare function isVSlot(p: ElementNode['props'][0]): p is DirectiveNode;

export declare type JSChildNode = VNodeCall | CallExpression | ObjectExpression | ArrayExpression | ExpressionNode | FunctionExpression | ConditionalExpression | CacheExpression | AssignmentExpression | SequenceExpression;

export declare const KEEP_ALIVE: unique symbol;

export declare interface ListDynamicSlotIterator extends FunctionExpression {
    returns: DynamicSlotNode;
}

export declare interface ListDynamicSlotNode extends CallExpression {
    callee: typeof RENDER_LIST;
    arguments: [ExpressionNode, ListDynamicSlotIterator];
}

export declare const locStub: SourceLocation;

export declare function makeBlock(node: VNodeCall, { helper, removeHelper, inSSR }: TransformContext): void;

export declare interface MemoExpression extends CallExpression {
    callee: typeof WITH_MEMO;
    arguments: [ExpressionNode, MemoFactory, string, string];
}

declare interface MemoFactory extends FunctionExpression {
    returns: BlockCodegenNode;
}

export declare const MERGE_PROPS: unique symbol;

declare type MergedParserOptions = Omit<Required<ParserOptions>, OptionalOptions> & Pick<ParserOptions, OptionalOptions>;

export declare type Namespace = number;

export declare const enum Namespaces {
    HTML = 0
}

declare interface Node_2 {
    type: NodeTypes;
    loc: SourceLocation;
}
export { Node_2 as Node }

export declare type NodeTransform = (node: RootNode | TemplateChildNode, context: TransformContext) => void | (() => void) | (() => void)[];

export declare const enum NodeTypes {
    ROOT = 0,
    ELEMENT = 1,
    TEXT = 2,
    COMMENT = 3,
    SIMPLE_EXPRESSION = 4,
    INTERPOLATION = 5,
    ATTRIBUTE = 6,
    DIRECTIVE = 7,
    COMPOUND_EXPRESSION = 8,
    IF = 9,
    IF_BRANCH = 10,
    FOR = 11,
    TEXT_CALL = 12,
    VNODE_CALL = 13,
    JS_CALL_EXPRESSION = 14,
    JS_OBJECT_EXPRESSION = 15,
    JS_PROPERTY = 16,
    JS_ARRAY_EXPRESSION = 17,
    JS_FUNCTION_EXPRESSION = 18,
    JS_CONDITIONAL_EXPRESSION = 19,
    JS_CACHE_EXPRESSION = 20,
    JS_BLOCK_STATEMENT = 21,
    JS_TEMPLATE_LITERAL = 22,
    JS_IF_STATEMENT = 23,
    JS_ASSIGNMENT_EXPRESSION = 24,
    JS_SEQUENCE_EXPRESSION = 25,
    JS_RETURN_STATEMENT = 26
}

export declare const noopDirectiveTransform: DirectiveTransform;

export declare const NORMALIZE_CLASS: unique symbol;

export declare const NORMALIZE_PROPS: unique symbol;

export declare const NORMALIZE_STYLE: unique symbol;

export declare interface ObjectExpression extends Node_2 {
    type: NodeTypes.JS_OBJECT_EXPRESSION;
    properties: Array<Property>;
}

export declare const OPEN_BLOCK: unique symbol;

declare type OptionalOptions = 'whitespace' | 'isNativeTag' | 'isBuiltInComponent' | keyof CompilerCompatOptions;

declare type ParentNode_2 = RootNode | ElementNode | IfBranchNode | ForNode;
export { ParentNode_2 as ParentNode }

declare interface ParserContext {
    options: MergedParserOptions;
    readonly originalSource: string;
    source: string;
    offset: number;
    line: number;
    column: number;
    inPre: boolean;
    inVPre: boolean;
    onWarn: NonNullable<ErrorHandlingOptions['onWarn']>;
}

export declare interface ParserOptions extends ErrorHandlingOptions, CompilerCompatOptions {
    /**
     * e.g. platform native elements, e.g. `<div>` for browsers
     */
    isNativeTag?: (tag: string) => boolean;
    /**
     * e.g. native elements that can self-close, e.g. `<img>`, `<br>`, `<hr>`
     */
    isVoidTag?: (tag: string) => boolean;
    /**
     * e.g. elements that should preserve whitespace inside, e.g. `<pre>`
     */
    isPreTag?: (tag: string) => boolean;
    /**
     * Platform-specific built-in components e.g. `<Transition>`
     */
    isBuiltInComponent?: (tag: string) => symbol | void;
    /**
     * Separate option for end users to extend the native elements list
     */
    isCustomElement?: (tag: string) => boolean | void;
    /**
     * Get tag namespace
     */
    getNamespace?: (tag: string, parent: ElementNode | undefined) => Namespace;
    /**
     * Get text parsing mode for this element
     */
    getTextMode?: (node: ElementNode, parent: ElementNode | undefined) => TextModes;
    /**
     * @default ['{{', '}}']
     */
    delimiters?: [string, string];
    /**
     * Whitespace handling strategy
     */
    whitespace?: 'preserve' | 'condense';
    /**
     * Only needed for DOM compilers
     */
    decodeEntities?: (rawText: string, asAttr: boolean) => string;
    /**
     * Whether to keep comments in the templates AST.
     * This defaults to `true` in development and `false` in production builds.
     */
    comments?: boolean;
}

export declare interface PlainElementNode extends BaseElementNode {
    tagType: ElementTypes.ELEMENT;
    codegenNode: VNodeCall | SimpleExpressionNode | CacheExpression | MemoExpression | undefined;
    ssrCodegenNode?: TemplateLiteral;
}

export declare const POP_SCOPE_ID: unique symbol;

export declare interface Position {
    offset: number;
    line: number;
    column: number;
}

export declare function processExpression(node: SimpleExpressionNode, context: TransformContext, asParams?: boolean, asRawStatements?: boolean, localVars?: Record<string, number>): ExpressionNode;

export declare function processFor(node: ElementNode, dir: DirectiveNode, context: TransformContext, processCodegen?: (forNode: ForNode) => (() => void) | undefined): (() => void) | undefined;

export declare function processIf(node: ElementNode, dir: DirectiveNode, context: TransformContext, processCodegen?: (node: IfNode, branch: IfBranchNode, isRoot: boolean) => (() => void) | undefined): (() => void) | undefined;

export declare function processSlotOutlet(node: SlotOutletNode, context: TransformContext): SlotOutletProcessResult;

export declare interface Property extends Node_2 {
    type: NodeTypes.JS_PROPERTY;
    key: ExpressionNode;
    value: JSChildNode;
}

export declare type PropsExpression = ObjectExpression | CallExpression | ExpressionNode;

export declare const PUSH_SCOPE_ID: unique symbol;

export declare function registerRuntimeHelpers(helpers: any): void;

export declare const RENDER_LIST: unique symbol;

export declare const RENDER_SLOT: unique symbol;

export declare interface RenderSlotCall extends CallExpression {
    callee: typeof RENDER_SLOT;
    arguments: [string, string | ExpressionNode] | [string, string | ExpressionNode, PropsExpression] | [
    string,
    string | ExpressionNode,
    PropsExpression | '{}',
    TemplateChildNode[]
    ];
}

export declare const RESOLVE_COMPONENT: unique symbol;

export declare const RESOLVE_DIRECTIVE: unique symbol;

export declare const RESOLVE_DYNAMIC_COMPONENT: unique symbol;

export declare const RESOLVE_FILTER: unique symbol;

export declare function resolveComponentType(node: ComponentNode, context: TransformContext, ssr?: boolean): string | symbol | CallExpression;

export declare interface ReturnStatement extends Node_2 {
    type: NodeTypes.JS_RETURN_STATEMENT;
    returns: TemplateChildNode | TemplateChildNode[] | JSChildNode;
}

export declare interface RootNode extends Node_2 {
    type: NodeTypes.ROOT;
    children: TemplateChildNode[];
    helpers: symbol[];
    components: string[];
    directives: string[];
    hoists: (JSChildNode | null)[];
    imports: ImportItem[];
    cached: number;
    temps: number;
    ssrHelpers?: symbol[];
    codegenNode?: TemplateChildNode | JSChildNode | BlockStatement;
    filters?: string[];
}

export declare interface SequenceExpression extends Node_2 {
    type: NodeTypes.JS_SEQUENCE_EXPRESSION;
    expressions: JSChildNode[];
}

export declare const SET_BLOCK_TRACKING: unique symbol;

declare interface SharedTransformCodegenOptions {
    /**
     * Transform expressions like {{ foo }} to `_ctx.foo`.
     * If this option is false, the generated code will be wrapped in a
     * `with (this) { ... }` block.
     * - This is force-enabled in module mode, since modules are by default strict
     * and cannot use `with`
     * @default mode === 'module'
     */
    prefixIdentifiers?: boolean;
    /**
     * Control whether generate SSR-optimized render functions instead.
     * The resulting function must be attached to the component via the
     * `ssrRender` option instead of `render`.
     *
     * When compiler generates code for SSR's fallback branch, we need to set it to false:
     *  - context.ssr = false
     *
     * see `subTransform` in `ssrTransformComponent.ts`
     */
    ssr?: boolean;
    /**
     * Indicates whether the compiler generates code for SSR,
     * it is always true when generating code for SSR,
     * regardless of whether we are generating code for SSR's fallback branch,
     * this means that when the compiler generates code for SSR's fallback branch:
     *  - context.ssr = false
     *  - context.inSSR = true
     */
    inSSR?: boolean;
    /**
     * Optional binding metadata analyzed from script - used to optimize
     * binding access when `prefixIdentifiers` is enabled.
     */
    bindingMetadata?: BindingMetadata;
    /**
     * Compile the function for inlining inside setup().
     * This allows the function to directly access setup() local bindings.
     */
    inline?: boolean;
    /**
     * Indicates that transforms and codegen should try to output valid TS code
     */
    isTS?: boolean;
    /**
     * Filename for source map generation.
     * Also used for self-recursive reference in templates
     * @default 'template.vue.html'
     */
    filename?: string;
}

export declare interface SimpleExpressionNode extends Node_2 {
    type: NodeTypes.SIMPLE_EXPRESSION;
    content: string;
    isStatic: boolean;
    constType: ConstantTypes;
    /**
     * Indicates this is an identifier for a hoist vnode call and points to the
     * hoisted node.
     */
    hoisted?: JSChildNode;
    /**
     * an expression parsed as the params of a function will track
     * the identifiers declared inside the function body.
     */
    identifiers?: string[];
    isHandlerKey?: boolean;
}

export declare type SlotFnBuilder = (slotProps: ExpressionNode | undefined, slotChildren: TemplateChildNode[], loc: SourceLocation) => FunctionExpression;

export declare interface SlotFunctionExpression extends FunctionExpression {
    returns: TemplateChildNode[];
}

export declare interface SlotOutletNode extends BaseElementNode {
    tagType: ElementTypes.SLOT;
    codegenNode: RenderSlotCall | CacheExpression | undefined;
    ssrCodegenNode?: CallExpression;
}

declare interface SlotOutletProcessResult {
    slotName: string | ExpressionNode;
    slotProps: PropsExpression | undefined;
}

export declare type SlotsExpression = SlotsObjectExpression | DynamicSlotsExpression;

export declare interface SlotsObjectExpression extends ObjectExpression {
    properties: SlotsObjectProperty[];
}

export declare interface SlotsObjectProperty extends Property {
    value: SlotFunctionExpression;
}

export declare interface SourceLocation {
    start: Position;
    end: Position;
    source: string;
}

export declare type SSRCodegenNode = BlockStatement | TemplateLiteral | IfStatement | AssignmentExpression | ReturnStatement | SequenceExpression;

export declare type StructuralDirectiveTransform = (node: ElementNode, dir: DirectiveNode, context: TransformContext) => void | (() => void);

export declare const SUSPENSE: unique symbol;

export declare const TELEPORT: unique symbol;

export declare type TemplateChildNode = ElementNode | InterpolationNode | CompoundExpressionNode | TextNode | CommentNode | IfNode | IfBranchNode | ForNode | TextCallNode;

export declare interface TemplateLiteral extends Node_2 {
    type: NodeTypes.JS_TEMPLATE_LITERAL;
    elements: (string | JSChildNode)[];
}

export declare interface TemplateNode extends BaseElementNode {
    tagType: ElementTypes.TEMPLATE;
    codegenNode: undefined;
}

export declare type TemplateTextChildNode = TextNode | InterpolationNode | CompoundExpressionNode;

export declare interface TextCallNode extends Node_2 {
    type: NodeTypes.TEXT_CALL;
    content: TextNode | InterpolationNode | CompoundExpressionNode;
    codegenNode: CallExpression | SimpleExpressionNode;
}

export declare const enum TextModes {
    DATA = 0,
    RCDATA = 1,
    RAWTEXT = 2,
    CDATA = 3,
    ATTRIBUTE_VALUE = 4
}

export declare interface TextNode extends Node_2 {
    type: NodeTypes.TEXT;
    content: string;
}

export declare const TO_DISPLAY_STRING: unique symbol;

export declare const TO_HANDLER_KEY: unique symbol;

export declare const TO_HANDLERS: unique symbol;

export declare function toValidAssetId(name: string, type: 'component' | 'directive' | 'filter'): string;

export declare const trackSlotScopes: NodeTransform;

export declare const trackVForSlotScopes: NodeTransform;

export declare function transform(root: RootNode, options: TransformOptions): void;

export declare const transformBind: DirectiveTransform;

export declare interface TransformContext extends Required<Omit<TransformOptions, 'filename' | keyof CompilerCompatOptions>>, CompilerCompatOptions {
    selfName: string | null;
    root: RootNode;
    helpers: Map<symbol, number>;
    components: Set<string>;
    directives: Set<string>;
    hoists: (JSChildNode | null)[];
    imports: ImportItem[];
    temps: number;
    cached: number;
    identifiers: {
        [name: string]: number | undefined;
    };
    scopes: {
        vFor: number;
        vSlot: number;
        vPre: number;
        vOnce: number;
    };
    parent: ParentNode_2 | null;
    childIndex: number;
    currentNode: RootNode | TemplateChildNode | null;
    inVOnce: boolean;
    helper<T extends symbol>(name: T): T;
    removeHelper<T extends symbol>(name: T): void;
    helperString(name: symbol): string;
    replaceNode(node: TemplateChildNode): void;
    removeNode(node?: TemplateChildNode): void;
    onNodeRemoved(): void;
    addIdentifiers(exp: ExpressionNode | string): void;
    removeIdentifiers(exp: ExpressionNode | string): void;
    hoist(exp: string | JSChildNode | ArrayExpression): SimpleExpressionNode;
    cache<T extends JSChildNode>(exp: T, isVNode?: boolean): CacheExpression | T;
    constantCache: Map<TemplateChildNode, ConstantTypes>;
    filters?: Set<string>;
}

export declare const transformElement: NodeTransform;

export declare const transformExpression: NodeTransform;

export declare const transformModel: DirectiveTransform;

export declare const transformOn: DirectiveTransform;

export declare interface TransformOptions extends SharedTransformCodegenOptions, ErrorHandlingOptions, CompilerCompatOptions {
    /**
     * An array of node transforms to be applied to every AST node.
     */
    nodeTransforms?: NodeTransform[];
    /**
     * An object of { name: transform } to be applied to every directive attribute
     * node found on element nodes.
     */
    directiveTransforms?: Record<string, DirectiveTransform | undefined>;
    /**
     * An optional hook to transform a node being hoisted.
     * used by compiler-dom to turn hoisted nodes into stringified HTML vnodes.
     * @default null
     */
    transformHoist?: HoistTransform | null;
    /**
     * If the pairing runtime provides additional built-in elements, use this to
     * mark them as built-in so the compiler will generate component vnodes
     * for them.
     */
    isBuiltInComponent?: (tag: string) => symbol | void;
    /**
     * Used by some transforms that expects only native elements
     */
    isCustomElement?: (tag: string) => boolean | void;
    /**
     * Transform expressions like {{ foo }} to `_ctx.foo`.
     * If this option is false, the generated code will be wrapped in a
     * `with (this) { ... }` block.
     * - This is force-enabled in module mode, since modules are by default strict
     * and cannot use `with`
     * @default mode === 'module'
     */
    prefixIdentifiers?: boolean;
    /**
     * Hoist static VNodes and props objects to `_hoisted_x` constants
     * @default false
     */
    hoistStatic?: boolean;
    /**
     * Cache v-on handlers to avoid creating new inline functions on each render,
     * also avoids the need for dynamically patching the handlers by wrapping it.
     * e.g `@click="foo"` by default is compiled to `{ onClick: foo }`. With this
     * option it's compiled to:
     * ```js
     * { onClick: _cache[0] || (_cache[0] = e => _ctx.foo(e)) }
     * ```
     * - Requires "prefixIdentifiers" to be enabled because it relies on scope
     * analysis to determine if a handler is safe to cache.
     * @default false
     */
    cacheHandlers?: boolean;
    /**
     * A list of parser plugins to enable for `@babel/parser`, which is used to
     * parse expressions in bindings and interpolations.
     * https://babeljs.io/docs/en/next/babel-parser#plugins
     */
    expressionPlugins?: ParserPlugin[];
    /**
     * SFC scoped styles ID
     */
    scopeId?: string | null;
    /**
     * Indicates this SFC template has used :slotted in its styles
     * Defaults to `true` for backwards compatibility - SFC tooling should set it
     * to `false` if no `:slotted` usage is detected in `<style>`
     */
    slotted?: boolean;
    /**
     * SFC `<style vars>` injection string
     * Should already be an object expression, e.g. `{ 'xxxx-color': color }`
     * needed to render inline CSS variables on component root
     */
    ssrCssVars?: string;
}

export declare type TransformPreset = [
NodeTransform[],
Record<string, DirectiveTransform>
];

export declare function traverseNode(node: RootNode | TemplateChildNode, context: TransformContext): void;

export declare const UNREF: unique symbol;

export declare interface VNodeCall extends Node_2 {
    type: NodeTypes.VNODE_CALL;
    tag: string | symbol | CallExpression;
    props: PropsExpression | undefined;
    children: TemplateChildNode[] | TemplateTextChildNode | SlotsExpression | ForRenderListExpression | SimpleExpressionNode | undefined;
    patchFlag: string | undefined;
    dynamicProps: string | SimpleExpressionNode | undefined;
    directives: DirectiveArguments | undefined;
    isBlock: boolean;
    disableTracking: boolean;
    isComponent: boolean;
}

export declare function walkBlockDeclarations(block: BlockStatement_2 | Program, onIdent: (node: Identifier) => void): void;

export declare function walkFunctionParams(node: Function_2, onIdent: (id: Identifier) => void): void;

export declare function walkIdentifiers(root: Node_3, onIdentifier: (node: Identifier, parent: Node_3, parentStack: Node_3[], isReference: boolean, isLocal: boolean) => void, includeAll?: boolean, parentStack?: Node_3[], knownIds?: Record<string, number>): void;

export declare function warnDeprecation(key: CompilerDeprecationTypes, context: ParserContext | TransformContext, loc: SourceLocation | null, ...args: any[]): void;

export declare const WITH_CTX: unique symbol;

export declare const WITH_DIRECTIVES: unique symbol;

export declare const WITH_MEMO: unique symbol;

export { }
