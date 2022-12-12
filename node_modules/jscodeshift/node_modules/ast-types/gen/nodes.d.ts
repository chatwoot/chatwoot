import { Omit } from "../types";
import * as K from "./kinds";
export interface Printable {
    loc: K.SourceLocationKind | null;
}
export interface SourceLocation {
    start: K.PositionKind;
    end: K.PositionKind;
    source: string | null;
}
export interface Node extends Printable {
    type: string;
    comments: K.CommentKind[] | null;
}
export interface Comment extends Printable {
    value: string;
    leading: boolean;
    trailing: boolean;
}
export interface Position {
    line: number;
    column: number;
}
export interface File extends Omit<Node, "type"> {
    type: "File";
    program: K.ProgramKind;
    name: string | null;
}
export interface Program extends Omit<Node, "type"> {
    type: "Program";
    body: K.StatementKind[];
    directives: K.DirectiveKind[];
    interpreter: K.InterpreterDirectiveKind | null;
}
export interface Statement extends Node {
}
export interface Function extends Node {
    id: K.IdentifierKind | null;
    params: K.PatternKind[];
    body: K.BlockStatementKind;
    generator: boolean;
    async: boolean;
    expression: boolean;
    defaults: (K.ExpressionKind | null)[];
    rest: K.IdentifierKind | null;
    returnType: K.TypeAnnotationKind | K.TSTypeAnnotationKind | null;
    typeParameters: K.TypeParameterDeclarationKind | K.TSTypeParameterDeclarationKind | null;
}
export interface Expression extends Node {
}
export interface Pattern extends Node {
}
export interface Identifier extends Omit<Expression, "type">, Omit<Pattern, "type"> {
    type: "Identifier";
    name: string;
    optional: boolean;
    typeAnnotation: K.TypeAnnotationKind | K.TSTypeAnnotationKind | null;
}
export interface BlockStatement extends Omit<Statement, "type"> {
    type: "BlockStatement";
    body: K.StatementKind[];
    directives: K.DirectiveKind[];
}
export interface EmptyStatement extends Omit<Statement, "type"> {
    type: "EmptyStatement";
}
export interface ExpressionStatement extends Omit<Statement, "type"> {
    type: "ExpressionStatement";
    expression: K.ExpressionKind;
}
export interface IfStatement extends Omit<Statement, "type"> {
    type: "IfStatement";
    test: K.ExpressionKind;
    consequent: K.StatementKind;
    alternate: K.StatementKind | null;
}
export interface LabeledStatement extends Omit<Statement, "type"> {
    type: "LabeledStatement";
    label: K.IdentifierKind;
    body: K.StatementKind;
}
export interface BreakStatement extends Omit<Statement, "type"> {
    type: "BreakStatement";
    label: K.IdentifierKind | null;
}
export interface ContinueStatement extends Omit<Statement, "type"> {
    type: "ContinueStatement";
    label: K.IdentifierKind | null;
}
export interface WithStatement extends Omit<Statement, "type"> {
    type: "WithStatement";
    object: K.ExpressionKind;
    body: K.StatementKind;
}
export interface SwitchStatement extends Omit<Statement, "type"> {
    type: "SwitchStatement";
    discriminant: K.ExpressionKind;
    cases: K.SwitchCaseKind[];
    lexical: boolean;
}
export interface SwitchCase extends Omit<Node, "type"> {
    type: "SwitchCase";
    test: K.ExpressionKind | null;
    consequent: K.StatementKind[];
}
export interface ReturnStatement extends Omit<Statement, "type"> {
    type: "ReturnStatement";
    argument: K.ExpressionKind | null;
}
export interface ThrowStatement extends Omit<Statement, "type"> {
    type: "ThrowStatement";
    argument: K.ExpressionKind;
}
export interface TryStatement extends Omit<Statement, "type"> {
    type: "TryStatement";
    block: K.BlockStatementKind;
    handler: K.CatchClauseKind | null;
    handlers: K.CatchClauseKind[];
    guardedHandlers: K.CatchClauseKind[];
    finalizer: K.BlockStatementKind | null;
}
export interface CatchClause extends Omit<Node, "type"> {
    type: "CatchClause";
    param: K.PatternKind | null;
    guard: K.ExpressionKind | null;
    body: K.BlockStatementKind;
}
export interface WhileStatement extends Omit<Statement, "type"> {
    type: "WhileStatement";
    test: K.ExpressionKind;
    body: K.StatementKind;
}
export interface DoWhileStatement extends Omit<Statement, "type"> {
    type: "DoWhileStatement";
    body: K.StatementKind;
    test: K.ExpressionKind;
}
export interface ForStatement extends Omit<Statement, "type"> {
    type: "ForStatement";
    init: K.VariableDeclarationKind | K.ExpressionKind | null;
    test: K.ExpressionKind | null;
    update: K.ExpressionKind | null;
    body: K.StatementKind;
}
export interface Declaration extends Statement {
}
export interface VariableDeclaration extends Omit<Declaration, "type"> {
    type: "VariableDeclaration";
    kind: "var" | "let" | "const";
    declarations: (K.VariableDeclaratorKind | K.IdentifierKind)[];
}
export interface ForInStatement extends Omit<Statement, "type"> {
    type: "ForInStatement";
    left: K.VariableDeclarationKind | K.ExpressionKind;
    right: K.ExpressionKind;
    body: K.StatementKind;
}
export interface DebuggerStatement extends Omit<Statement, "type"> {
    type: "DebuggerStatement";
}
export interface FunctionDeclaration extends Omit<Function, "type" | "id">, Omit<Declaration, "type"> {
    type: "FunctionDeclaration";
    id: K.IdentifierKind;
}
export interface FunctionExpression extends Omit<Function, "type">, Omit<Expression, "type"> {
    type: "FunctionExpression";
}
export interface VariableDeclarator extends Omit<Node, "type"> {
    type: "VariableDeclarator";
    id: K.PatternKind;
    init: K.ExpressionKind | null;
}
export interface ThisExpression extends Omit<Expression, "type"> {
    type: "ThisExpression";
}
export interface ArrayExpression extends Omit<Expression, "type"> {
    type: "ArrayExpression";
    elements: (K.ExpressionKind | K.SpreadElementKind | K.RestElementKind | null)[];
}
export interface ObjectExpression extends Omit<Expression, "type"> {
    type: "ObjectExpression";
    properties: (K.PropertyKind | K.ObjectMethodKind | K.ObjectPropertyKind | K.SpreadPropertyKind | K.SpreadElementKind)[];
}
export interface Property extends Omit<Node, "type"> {
    type: "Property";
    kind: "init" | "get" | "set";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    value: K.ExpressionKind | K.PatternKind;
    method: boolean;
    shorthand: boolean;
    computed: boolean;
    decorators: K.DecoratorKind[] | null;
}
export interface Literal extends Omit<Expression, "type"> {
    type: "Literal";
    value: string | boolean | null | number | RegExp;
    regex: {
        pattern: string;
        flags: string;
    } | null;
}
export interface SequenceExpression extends Omit<Expression, "type"> {
    type: "SequenceExpression";
    expressions: K.ExpressionKind[];
}
export interface UnaryExpression extends Omit<Expression, "type"> {
    type: "UnaryExpression";
    operator: "-" | "+" | "!" | "~" | "typeof" | "void" | "delete";
    argument: K.ExpressionKind;
    prefix: boolean;
}
export interface BinaryExpression extends Omit<Expression, "type"> {
    type: "BinaryExpression";
    operator: "==" | "!=" | "===" | "!==" | "<" | "<=" | ">" | ">=" | "<<" | ">>" | ">>>" | "+" | "-" | "*" | "/" | "%" | "**" | "&" | "|" | "^" | "in" | "instanceof";
    left: K.ExpressionKind;
    right: K.ExpressionKind;
}
export interface AssignmentExpression extends Omit<Expression, "type"> {
    type: "AssignmentExpression";
    operator: "=" | "+=" | "-=" | "*=" | "/=" | "%=" | "<<=" | ">>=" | ">>>=" | "|=" | "^=" | "&=";
    left: K.PatternKind | K.MemberExpressionKind;
    right: K.ExpressionKind;
}
export interface MemberExpression extends Omit<Expression, "type"> {
    type: "MemberExpression";
    object: K.ExpressionKind;
    property: K.IdentifierKind | K.ExpressionKind;
    computed: boolean;
}
export interface UpdateExpression extends Omit<Expression, "type"> {
    type: "UpdateExpression";
    operator: "++" | "--";
    argument: K.ExpressionKind;
    prefix: boolean;
}
export interface LogicalExpression extends Omit<Expression, "type"> {
    type: "LogicalExpression";
    operator: "||" | "&&" | "??";
    left: K.ExpressionKind;
    right: K.ExpressionKind;
}
export interface ConditionalExpression extends Omit<Expression, "type"> {
    type: "ConditionalExpression";
    test: K.ExpressionKind;
    consequent: K.ExpressionKind;
    alternate: K.ExpressionKind;
}
export interface NewExpression extends Omit<Expression, "type"> {
    type: "NewExpression";
    callee: K.ExpressionKind;
    arguments: (K.ExpressionKind | K.SpreadElementKind)[];
}
export interface CallExpression extends Omit<Expression, "type"> {
    type: "CallExpression";
    callee: K.ExpressionKind;
    arguments: (K.ExpressionKind | K.SpreadElementKind)[];
}
export interface RestElement extends Omit<Pattern, "type"> {
    type: "RestElement";
    argument: K.PatternKind;
    typeAnnotation: K.TypeAnnotationKind | K.TSTypeAnnotationKind | null;
}
export interface TypeAnnotation extends Omit<Node, "type"> {
    type: "TypeAnnotation";
    typeAnnotation: K.FlowTypeKind;
}
export interface TSTypeAnnotation extends Omit<Node, "type"> {
    type: "TSTypeAnnotation";
    typeAnnotation: K.TSTypeKind | K.TSTypeAnnotationKind;
}
export interface SpreadElementPattern extends Omit<Pattern, "type"> {
    type: "SpreadElementPattern";
    argument: K.PatternKind;
}
export interface ArrowFunctionExpression extends Omit<Function, "type" | "id" | "body" | "generator">, Omit<Expression, "type"> {
    type: "ArrowFunctionExpression";
    id: null;
    body: K.BlockStatementKind | K.ExpressionKind;
    generator: false;
}
export interface ForOfStatement extends Omit<Statement, "type"> {
    type: "ForOfStatement";
    left: K.VariableDeclarationKind | K.PatternKind;
    right: K.ExpressionKind;
    body: K.StatementKind;
}
export interface YieldExpression extends Omit<Expression, "type"> {
    type: "YieldExpression";
    argument: K.ExpressionKind | null;
    delegate: boolean;
}
export interface GeneratorExpression extends Omit<Expression, "type"> {
    type: "GeneratorExpression";
    body: K.ExpressionKind;
    blocks: K.ComprehensionBlockKind[];
    filter: K.ExpressionKind | null;
}
export interface ComprehensionBlock extends Omit<Node, "type"> {
    type: "ComprehensionBlock";
    left: K.PatternKind;
    right: K.ExpressionKind;
    each: boolean;
}
export interface ComprehensionExpression extends Omit<Expression, "type"> {
    type: "ComprehensionExpression";
    body: K.ExpressionKind;
    blocks: K.ComprehensionBlockKind[];
    filter: K.ExpressionKind | null;
}
export interface ObjectProperty extends Omit<Node, "type"> {
    shorthand: boolean;
    type: "ObjectProperty";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    value: K.ExpressionKind | K.PatternKind;
    accessibility: K.LiteralKind | null;
    computed: boolean;
}
export interface PropertyPattern extends Omit<Pattern, "type"> {
    type: "PropertyPattern";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    pattern: K.PatternKind;
    computed: boolean;
}
export interface ObjectPattern extends Omit<Pattern, "type"> {
    type: "ObjectPattern";
    properties: (K.PropertyKind | K.PropertyPatternKind | K.SpreadPropertyPatternKind | K.SpreadPropertyKind | K.ObjectPropertyKind | K.RestPropertyKind)[];
    typeAnnotation: K.TypeAnnotationKind | K.TSTypeAnnotationKind | null;
    decorators: K.DecoratorKind[] | null;
}
export interface ArrayPattern extends Omit<Pattern, "type"> {
    type: "ArrayPattern";
    elements: (K.PatternKind | K.SpreadElementKind | null)[];
}
export interface MethodDefinition extends Omit<Declaration, "type"> {
    type: "MethodDefinition";
    kind: "constructor" | "method" | "get" | "set";
    key: K.ExpressionKind;
    value: K.FunctionKind;
    computed: boolean;
    static: boolean;
    decorators: K.DecoratorKind[] | null;
}
export interface SpreadElement extends Omit<Node, "type"> {
    type: "SpreadElement";
    argument: K.ExpressionKind;
}
export interface AssignmentPattern extends Omit<Pattern, "type"> {
    type: "AssignmentPattern";
    left: K.PatternKind;
    right: K.ExpressionKind;
}
export interface ClassPropertyDefinition extends Omit<Declaration, "type"> {
    type: "ClassPropertyDefinition";
    definition: K.MethodDefinitionKind | K.VariableDeclaratorKind | K.ClassPropertyDefinitionKind | K.ClassPropertyKind;
}
export interface ClassProperty extends Omit<Declaration, "type"> {
    type: "ClassProperty";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    computed: boolean;
    value: K.ExpressionKind | null;
    static: boolean;
    typeAnnotation: K.TypeAnnotationKind | K.TSTypeAnnotationKind | null;
    variance: K.VarianceKind | "plus" | "minus" | null;
    access: "public" | "private" | "protected" | undefined;
}
export interface ClassBody extends Omit<Declaration, "type"> {
    type: "ClassBody";
    body: (K.MethodDefinitionKind | K.VariableDeclaratorKind | K.ClassPropertyDefinitionKind | K.ClassPropertyKind | K.ClassPrivatePropertyKind | K.ClassMethodKind | K.ClassPrivateMethodKind | K.TSDeclareMethodKind | K.TSCallSignatureDeclarationKind | K.TSConstructSignatureDeclarationKind | K.TSIndexSignatureKind | K.TSMethodSignatureKind | K.TSPropertySignatureKind)[];
}
export interface ClassDeclaration extends Omit<Declaration, "type"> {
    type: "ClassDeclaration";
    id: K.IdentifierKind | null;
    body: K.ClassBodyKind;
    superClass: K.ExpressionKind | null;
    typeParameters: K.TypeParameterDeclarationKind | K.TSTypeParameterDeclarationKind | null;
    superTypeParameters: K.TypeParameterInstantiationKind | K.TSTypeParameterInstantiationKind | null;
    implements: K.ClassImplementsKind[] | K.TSExpressionWithTypeArgumentsKind[];
}
export interface ClassExpression extends Omit<Expression, "type"> {
    type: "ClassExpression";
    id: K.IdentifierKind | null;
    body: K.ClassBodyKind;
    superClass: K.ExpressionKind | null;
    typeParameters: K.TypeParameterDeclarationKind | K.TSTypeParameterDeclarationKind | null;
    superTypeParameters: K.TypeParameterInstantiationKind | K.TSTypeParameterInstantiationKind | null;
    implements: K.ClassImplementsKind[] | K.TSExpressionWithTypeArgumentsKind[];
}
export interface Specifier extends Node {
}
export interface ModuleSpecifier extends Specifier {
    local: K.IdentifierKind | null;
    id: K.IdentifierKind | null;
    name: K.IdentifierKind | null;
}
export interface ImportSpecifier extends Omit<ModuleSpecifier, "type"> {
    type: "ImportSpecifier";
    imported: K.IdentifierKind;
}
export interface ImportNamespaceSpecifier extends Omit<ModuleSpecifier, "type"> {
    type: "ImportNamespaceSpecifier";
}
export interface ImportDefaultSpecifier extends Omit<ModuleSpecifier, "type"> {
    type: "ImportDefaultSpecifier";
}
export interface ImportDeclaration extends Omit<Declaration, "type"> {
    type: "ImportDeclaration";
    specifiers: (K.ImportSpecifierKind | K.ImportNamespaceSpecifierKind | K.ImportDefaultSpecifierKind)[];
    source: K.LiteralKind;
    importKind: "value" | "type";
}
export interface TaggedTemplateExpression extends Omit<Expression, "type"> {
    type: "TaggedTemplateExpression";
    tag: K.ExpressionKind;
    quasi: K.TemplateLiteralKind;
}
export interface TemplateLiteral extends Omit<Expression, "type"> {
    type: "TemplateLiteral";
    quasis: K.TemplateElementKind[];
    expressions: K.ExpressionKind[];
}
export interface TemplateElement extends Omit<Node, "type"> {
    type: "TemplateElement";
    value: {
        cooked: string;
        raw: string;
    };
    tail: boolean;
}
export interface SpreadProperty extends Omit<Node, "type"> {
    type: "SpreadProperty";
    argument: K.ExpressionKind;
}
export interface SpreadPropertyPattern extends Omit<Pattern, "type"> {
    type: "SpreadPropertyPattern";
    argument: K.PatternKind;
}
export interface AwaitExpression extends Omit<Expression, "type"> {
    type: "AwaitExpression";
    argument: K.ExpressionKind | null;
    all: boolean;
}
export interface JSXAttribute extends Omit<Node, "type"> {
    type: "JSXAttribute";
    name: K.JSXIdentifierKind | K.JSXNamespacedNameKind;
    value: K.LiteralKind | K.JSXExpressionContainerKind | null;
}
export interface JSXIdentifier extends Omit<Identifier, "type" | "name"> {
    type: "JSXIdentifier";
    name: string;
}
export interface JSXNamespacedName extends Omit<Node, "type"> {
    type: "JSXNamespacedName";
    namespace: K.JSXIdentifierKind;
    name: K.JSXIdentifierKind;
}
export interface JSXExpressionContainer extends Omit<Expression, "type"> {
    type: "JSXExpressionContainer";
    expression: K.ExpressionKind;
}
export interface JSXMemberExpression extends Omit<MemberExpression, "type" | "object" | "property" | "computed"> {
    type: "JSXMemberExpression";
    object: K.JSXIdentifierKind | K.JSXMemberExpressionKind;
    property: K.JSXIdentifierKind;
    computed: boolean;
}
export interface JSXSpreadAttribute extends Omit<Node, "type"> {
    type: "JSXSpreadAttribute";
    argument: K.ExpressionKind;
}
export interface JSXElement extends Omit<Expression, "type"> {
    type: "JSXElement";
    openingElement: K.JSXOpeningElementKind;
    closingElement: K.JSXClosingElementKind | null;
    children: (K.JSXElementKind | K.JSXExpressionContainerKind | K.JSXFragmentKind | K.JSXTextKind | K.LiteralKind)[];
    name: K.JSXIdentifierKind | K.JSXNamespacedNameKind | K.JSXMemberExpressionKind;
    selfClosing: boolean;
    attributes: (K.JSXAttributeKind | K.JSXSpreadAttributeKind)[];
}
export interface JSXOpeningElement extends Omit<Node, "type"> {
    type: "JSXOpeningElement";
    name: K.JSXIdentifierKind | K.JSXNamespacedNameKind | K.JSXMemberExpressionKind;
    attributes: (K.JSXAttributeKind | K.JSXSpreadAttributeKind)[];
    selfClosing: boolean;
}
export interface JSXClosingElement extends Omit<Node, "type"> {
    type: "JSXClosingElement";
    name: K.JSXIdentifierKind | K.JSXNamespacedNameKind | K.JSXMemberExpressionKind;
}
export interface JSXFragment extends Omit<Expression, "type"> {
    type: "JSXFragment";
    openingElement: K.JSXOpeningFragmentKind;
    closingElement: K.JSXClosingFragmentKind;
    children: (K.JSXElementKind | K.JSXExpressionContainerKind | K.JSXFragmentKind | K.JSXTextKind | K.LiteralKind)[];
}
export interface JSXText extends Omit<Literal, "type" | "value"> {
    type: "JSXText";
    value: string;
}
export interface JSXOpeningFragment extends Omit<Node, "type"> {
    type: "JSXOpeningFragment";
}
export interface JSXClosingFragment extends Omit<Node, "type"> {
    type: "JSXClosingFragment";
}
export interface JSXEmptyExpression extends Omit<Expression, "type"> {
    type: "JSXEmptyExpression";
}
export interface JSXSpreadChild extends Omit<Expression, "type"> {
    type: "JSXSpreadChild";
    expression: K.ExpressionKind;
}
export interface TypeParameterDeclaration extends Omit<Node, "type"> {
    type: "TypeParameterDeclaration";
    params: K.TypeParameterKind[];
}
export interface TSTypeParameterDeclaration extends Omit<Declaration, "type"> {
    type: "TSTypeParameterDeclaration";
    params: K.TSTypeParameterKind[];
}
export interface TypeParameterInstantiation extends Omit<Node, "type"> {
    type: "TypeParameterInstantiation";
    params: K.FlowTypeKind[];
}
export interface TSTypeParameterInstantiation extends Omit<Node, "type"> {
    type: "TSTypeParameterInstantiation";
    params: K.TSTypeKind[];
}
export interface ClassImplements extends Omit<Node, "type"> {
    type: "ClassImplements";
    id: K.IdentifierKind;
    superClass: K.ExpressionKind | null;
    typeParameters: K.TypeParameterInstantiationKind | null;
}
export interface TSType extends Node {
}
export interface TSHasOptionalTypeParameterInstantiation {
    typeParameters: K.TSTypeParameterInstantiationKind | null;
}
export interface TSExpressionWithTypeArguments extends Omit<TSType, "type">, TSHasOptionalTypeParameterInstantiation {
    type: "TSExpressionWithTypeArguments";
    expression: K.IdentifierKind | K.TSQualifiedNameKind;
}
export interface Flow extends Node {
}
export interface FlowType extends Flow {
}
export interface AnyTypeAnnotation extends Omit<FlowType, "type"> {
    type: "AnyTypeAnnotation";
}
export interface EmptyTypeAnnotation extends Omit<FlowType, "type"> {
    type: "EmptyTypeAnnotation";
}
export interface MixedTypeAnnotation extends Omit<FlowType, "type"> {
    type: "MixedTypeAnnotation";
}
export interface VoidTypeAnnotation extends Omit<FlowType, "type"> {
    type: "VoidTypeAnnotation";
}
export interface NumberTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NumberTypeAnnotation";
}
export interface NumberLiteralTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NumberLiteralTypeAnnotation";
    value: number;
    raw: string;
}
export interface NumericLiteralTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NumericLiteralTypeAnnotation";
    value: number;
    raw: string;
}
export interface StringTypeAnnotation extends Omit<FlowType, "type"> {
    type: "StringTypeAnnotation";
}
export interface StringLiteralTypeAnnotation extends Omit<FlowType, "type"> {
    type: "StringLiteralTypeAnnotation";
    value: string;
    raw: string;
}
export interface BooleanTypeAnnotation extends Omit<FlowType, "type"> {
    type: "BooleanTypeAnnotation";
}
export interface BooleanLiteralTypeAnnotation extends Omit<FlowType, "type"> {
    type: "BooleanLiteralTypeAnnotation";
    value: boolean;
    raw: string;
}
export interface NullableTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NullableTypeAnnotation";
    typeAnnotation: K.FlowTypeKind;
}
export interface NullLiteralTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NullLiteralTypeAnnotation";
}
export interface NullTypeAnnotation extends Omit<FlowType, "type"> {
    type: "NullTypeAnnotation";
}
export interface ThisTypeAnnotation extends Omit<FlowType, "type"> {
    type: "ThisTypeAnnotation";
}
export interface ExistsTypeAnnotation extends Omit<FlowType, "type"> {
    type: "ExistsTypeAnnotation";
}
export interface ExistentialTypeParam extends Omit<FlowType, "type"> {
    type: "ExistentialTypeParam";
}
export interface FunctionTypeAnnotation extends Omit<FlowType, "type"> {
    type: "FunctionTypeAnnotation";
    params: K.FunctionTypeParamKind[];
    returnType: K.FlowTypeKind;
    rest: K.FunctionTypeParamKind | null;
    typeParameters: K.TypeParameterDeclarationKind | null;
}
export interface FunctionTypeParam extends Omit<Node, "type"> {
    type: "FunctionTypeParam";
    name: K.IdentifierKind;
    typeAnnotation: K.FlowTypeKind;
    optional: boolean;
}
export interface ArrayTypeAnnotation extends Omit<FlowType, "type"> {
    type: "ArrayTypeAnnotation";
    elementType: K.FlowTypeKind;
}
export interface ObjectTypeAnnotation extends Omit<FlowType, "type"> {
    type: "ObjectTypeAnnotation";
    properties: (K.ObjectTypePropertyKind | K.ObjectTypeSpreadPropertyKind)[];
    indexers: K.ObjectTypeIndexerKind[];
    callProperties: K.ObjectTypeCallPropertyKind[];
    inexact: boolean | undefined;
    exact: boolean;
    internalSlots: K.ObjectTypeInternalSlotKind[];
}
export interface ObjectTypeProperty extends Omit<Node, "type"> {
    type: "ObjectTypeProperty";
    key: K.LiteralKind | K.IdentifierKind;
    value: K.FlowTypeKind;
    optional: boolean;
    variance: K.VarianceKind | "plus" | "minus" | null;
}
export interface ObjectTypeSpreadProperty extends Omit<Node, "type"> {
    type: "ObjectTypeSpreadProperty";
    argument: K.FlowTypeKind;
}
export interface ObjectTypeIndexer extends Omit<Node, "type"> {
    type: "ObjectTypeIndexer";
    id: K.IdentifierKind;
    key: K.FlowTypeKind;
    value: K.FlowTypeKind;
    variance: K.VarianceKind | "plus" | "minus" | null;
}
export interface ObjectTypeCallProperty extends Omit<Node, "type"> {
    type: "ObjectTypeCallProperty";
    value: K.FunctionTypeAnnotationKind;
    static: boolean;
}
export interface ObjectTypeInternalSlot extends Omit<Node, "type"> {
    type: "ObjectTypeInternalSlot";
    id: K.IdentifierKind;
    value: K.FlowTypeKind;
    optional: boolean;
    static: boolean;
    method: boolean;
}
export interface Variance extends Omit<Node, "type"> {
    type: "Variance";
    kind: "plus" | "minus";
}
export interface QualifiedTypeIdentifier extends Omit<Node, "type"> {
    type: "QualifiedTypeIdentifier";
    qualification: K.IdentifierKind | K.QualifiedTypeIdentifierKind;
    id: K.IdentifierKind;
}
export interface GenericTypeAnnotation extends Omit<FlowType, "type"> {
    type: "GenericTypeAnnotation";
    id: K.IdentifierKind | K.QualifiedTypeIdentifierKind;
    typeParameters: K.TypeParameterInstantiationKind | null;
}
export interface MemberTypeAnnotation extends Omit<FlowType, "type"> {
    type: "MemberTypeAnnotation";
    object: K.IdentifierKind;
    property: K.MemberTypeAnnotationKind | K.GenericTypeAnnotationKind;
}
export interface UnionTypeAnnotation extends Omit<FlowType, "type"> {
    type: "UnionTypeAnnotation";
    types: K.FlowTypeKind[];
}
export interface IntersectionTypeAnnotation extends Omit<FlowType, "type"> {
    type: "IntersectionTypeAnnotation";
    types: K.FlowTypeKind[];
}
export interface TypeofTypeAnnotation extends Omit<FlowType, "type"> {
    type: "TypeofTypeAnnotation";
    argument: K.FlowTypeKind;
}
export interface TypeParameter extends Omit<FlowType, "type"> {
    type: "TypeParameter";
    name: string;
    variance: K.VarianceKind | "plus" | "minus" | null;
    bound: K.TypeAnnotationKind | null;
}
export interface InterfaceTypeAnnotation extends Omit<FlowType, "type"> {
    type: "InterfaceTypeAnnotation";
    body: K.ObjectTypeAnnotationKind;
    extends: K.InterfaceExtendsKind[] | null;
}
export interface InterfaceExtends extends Omit<Node, "type"> {
    type: "InterfaceExtends";
    id: K.IdentifierKind;
    typeParameters: K.TypeParameterInstantiationKind | null;
}
export interface InterfaceDeclaration extends Omit<Declaration, "type"> {
    type: "InterfaceDeclaration";
    id: K.IdentifierKind;
    typeParameters: K.TypeParameterDeclarationKind | null;
    body: K.ObjectTypeAnnotationKind;
    extends: K.InterfaceExtendsKind[];
}
export interface DeclareInterface extends Omit<InterfaceDeclaration, "type"> {
    type: "DeclareInterface";
}
export interface TypeAlias extends Omit<Declaration, "type"> {
    type: "TypeAlias";
    id: K.IdentifierKind;
    typeParameters: K.TypeParameterDeclarationKind | null;
    right: K.FlowTypeKind;
}
export interface OpaqueType extends Omit<Declaration, "type"> {
    type: "OpaqueType";
    id: K.IdentifierKind;
    typeParameters: K.TypeParameterDeclarationKind | null;
    impltype: K.FlowTypeKind;
    supertype: K.FlowTypeKind;
}
export interface DeclareTypeAlias extends Omit<TypeAlias, "type"> {
    type: "DeclareTypeAlias";
}
export interface DeclareOpaqueType extends Omit<TypeAlias, "type"> {
    type: "DeclareOpaqueType";
}
export interface TypeCastExpression extends Omit<Expression, "type"> {
    type: "TypeCastExpression";
    expression: K.ExpressionKind;
    typeAnnotation: K.TypeAnnotationKind;
}
export interface TupleTypeAnnotation extends Omit<FlowType, "type"> {
    type: "TupleTypeAnnotation";
    types: K.FlowTypeKind[];
}
export interface DeclareVariable extends Omit<Statement, "type"> {
    type: "DeclareVariable";
    id: K.IdentifierKind;
}
export interface DeclareFunction extends Omit<Statement, "type"> {
    type: "DeclareFunction";
    id: K.IdentifierKind;
}
export interface DeclareClass extends Omit<InterfaceDeclaration, "type"> {
    type: "DeclareClass";
}
export interface DeclareModule extends Omit<Statement, "type"> {
    type: "DeclareModule";
    id: K.IdentifierKind | K.LiteralKind;
    body: K.BlockStatementKind;
}
export interface DeclareModuleExports extends Omit<Statement, "type"> {
    type: "DeclareModuleExports";
    typeAnnotation: K.TypeAnnotationKind;
}
export interface DeclareExportDeclaration extends Omit<Declaration, "type"> {
    type: "DeclareExportDeclaration";
    default: boolean;
    declaration: K.DeclareVariableKind | K.DeclareFunctionKind | K.DeclareClassKind | K.FlowTypeKind | null;
    specifiers: (K.ExportSpecifierKind | K.ExportBatchSpecifierKind)[];
    source: K.LiteralKind | null;
}
export interface ExportSpecifier extends Omit<ModuleSpecifier, "type"> {
    type: "ExportSpecifier";
    exported: K.IdentifierKind;
}
export interface ExportBatchSpecifier extends Omit<Specifier, "type"> {
    type: "ExportBatchSpecifier";
}
export interface DeclareExportAllDeclaration extends Omit<Declaration, "type"> {
    type: "DeclareExportAllDeclaration";
    source: K.LiteralKind | null;
}
export interface FlowPredicate extends Flow {
}
export interface InferredPredicate extends Omit<FlowPredicate, "type"> {
    type: "InferredPredicate";
}
export interface DeclaredPredicate extends Omit<FlowPredicate, "type"> {
    type: "DeclaredPredicate";
    value: K.ExpressionKind;
}
export interface ExportDeclaration extends Omit<Declaration, "type"> {
    type: "ExportDeclaration";
    default: boolean;
    declaration: K.DeclarationKind | K.ExpressionKind | null;
    specifiers: (K.ExportSpecifierKind | K.ExportBatchSpecifierKind)[];
    source: K.LiteralKind | null;
}
export interface Block extends Comment {
    type: "Block";
}
export interface Line extends Comment {
    type: "Line";
}
export interface Noop extends Omit<Statement, "type"> {
    type: "Noop";
}
export interface DoExpression extends Omit<Expression, "type"> {
    type: "DoExpression";
    body: K.StatementKind[];
}
export interface Super extends Omit<Expression, "type"> {
    type: "Super";
}
export interface BindExpression extends Omit<Expression, "type"> {
    type: "BindExpression";
    object: K.ExpressionKind | null;
    callee: K.ExpressionKind;
}
export interface Decorator extends Omit<Node, "type"> {
    type: "Decorator";
    expression: K.ExpressionKind;
}
export interface MetaProperty extends Omit<Expression, "type"> {
    type: "MetaProperty";
    meta: K.IdentifierKind;
    property: K.IdentifierKind;
}
export interface ParenthesizedExpression extends Omit<Expression, "type"> {
    type: "ParenthesizedExpression";
    expression: K.ExpressionKind;
}
export interface ExportDefaultDeclaration extends Omit<Declaration, "type"> {
    type: "ExportDefaultDeclaration";
    declaration: K.DeclarationKind | K.ExpressionKind;
}
export interface ExportNamedDeclaration extends Omit<Declaration, "type"> {
    type: "ExportNamedDeclaration";
    declaration: K.DeclarationKind | null;
    specifiers: K.ExportSpecifierKind[];
    source: K.LiteralKind | null;
}
export interface ExportNamespaceSpecifier extends Omit<Specifier, "type"> {
    type: "ExportNamespaceSpecifier";
    exported: K.IdentifierKind;
}
export interface ExportDefaultSpecifier extends Omit<Specifier, "type"> {
    type: "ExportDefaultSpecifier";
    exported: K.IdentifierKind;
}
export interface ExportAllDeclaration extends Omit<Declaration, "type"> {
    type: "ExportAllDeclaration";
    exported: K.IdentifierKind | null;
    source: K.LiteralKind;
}
export interface CommentBlock extends Comment {
    type: "CommentBlock";
}
export interface CommentLine extends Comment {
    type: "CommentLine";
}
export interface Directive extends Omit<Node, "type"> {
    type: "Directive";
    value: K.DirectiveLiteralKind;
}
export interface DirectiveLiteral extends Omit<Node, "type">, Omit<Expression, "type"> {
    type: "DirectiveLiteral";
    value: string;
}
export interface InterpreterDirective extends Omit<Node, "type"> {
    type: "InterpreterDirective";
    value: string;
}
export interface StringLiteral extends Omit<Literal, "type" | "value"> {
    type: "StringLiteral";
    value: string;
}
export interface NumericLiteral extends Omit<Literal, "type" | "value"> {
    type: "NumericLiteral";
    value: number;
    raw: string | null;
    extra: {
        rawValue: number;
        raw: string;
    };
}
export interface BigIntLiteral extends Omit<Literal, "type" | "value"> {
    type: "BigIntLiteral";
    value: string | number;
    extra: {
        rawValue: string;
        raw: string;
    };
}
export interface NullLiteral extends Omit<Literal, "type" | "value"> {
    type: "NullLiteral";
    value: null;
}
export interface BooleanLiteral extends Omit<Literal, "type" | "value"> {
    type: "BooleanLiteral";
    value: boolean;
}
export interface RegExpLiteral extends Omit<Literal, "type" | "value"> {
    type: "RegExpLiteral";
    pattern: string;
    flags: string;
    value: RegExp;
}
export interface ObjectMethod extends Omit<Node, "type">, Omit<Function, "type" | "params" | "body" | "generator" | "async"> {
    type: "ObjectMethod";
    kind: "method" | "get" | "set";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    params: K.PatternKind[];
    body: K.BlockStatementKind;
    computed: boolean;
    generator: boolean;
    async: boolean;
    accessibility: K.LiteralKind | null;
    decorators: K.DecoratorKind[] | null;
}
export interface ClassPrivateProperty extends Omit<ClassProperty, "type" | "key" | "value"> {
    type: "ClassPrivateProperty";
    key: K.PrivateNameKind;
    value: K.ExpressionKind | null;
}
export interface ClassMethod extends Omit<Declaration, "type">, Omit<Function, "type" | "body"> {
    type: "ClassMethod";
    key: K.LiteralKind | K.IdentifierKind | K.ExpressionKind;
    kind: "get" | "set" | "method" | "constructor";
    body: K.BlockStatementKind;
    computed: boolean;
    static: boolean | null;
    abstract: boolean | null;
    access: "public" | "private" | "protected" | null;
    accessibility: "public" | "private" | "protected" | null;
    decorators: K.DecoratorKind[] | null;
    optional: boolean | null;
}
export interface ClassPrivateMethod extends Omit<Declaration, "type">, Omit<Function, "type" | "body"> {
    type: "ClassPrivateMethod";
    key: K.PrivateNameKind;
    kind: "get" | "set" | "method" | "constructor";
    body: K.BlockStatementKind;
    computed: boolean;
    static: boolean | null;
    abstract: boolean | null;
    access: "public" | "private" | "protected" | null;
    accessibility: "public" | "private" | "protected" | null;
    decorators: K.DecoratorKind[] | null;
    optional: boolean | null;
}
export interface PrivateName extends Omit<Expression, "type">, Omit<Pattern, "type"> {
    type: "PrivateName";
    id: K.IdentifierKind;
}
export interface RestProperty extends Omit<Node, "type"> {
    type: "RestProperty";
    argument: K.ExpressionKind;
}
export interface ForAwaitStatement extends Omit<Statement, "type"> {
    type: "ForAwaitStatement";
    left: K.VariableDeclarationKind | K.ExpressionKind;
    right: K.ExpressionKind;
    body: K.StatementKind;
}
export interface Import extends Omit<Expression, "type"> {
    type: "Import";
}
export interface TSQualifiedName extends Omit<Node, "type"> {
    type: "TSQualifiedName";
    left: K.IdentifierKind | K.TSQualifiedNameKind;
    right: K.IdentifierKind | K.TSQualifiedNameKind;
}
export interface TSTypeReference extends Omit<TSType, "type">, TSHasOptionalTypeParameterInstantiation {
    type: "TSTypeReference";
    typeName: K.IdentifierKind | K.TSQualifiedNameKind;
}
export interface TSHasOptionalTypeParameters {
    typeParameters: K.TSTypeParameterDeclarationKind | null | undefined;
}
export interface TSHasOptionalTypeAnnotation {
    typeAnnotation: K.TSTypeAnnotationKind | null;
}
export interface TSAsExpression extends Omit<Expression, "type">, Omit<Pattern, "type"> {
    type: "TSAsExpression";
    expression: K.ExpressionKind;
    typeAnnotation: K.TSTypeKind;
    extra: {
        parenthesized: boolean;
    } | null;
}
export interface TSNonNullExpression extends Omit<Expression, "type">, Omit<Pattern, "type"> {
    type: "TSNonNullExpression";
    expression: K.ExpressionKind;
}
export interface TSAnyKeyword extends Omit<TSType, "type"> {
    type: "TSAnyKeyword";
}
export interface TSBigIntKeyword extends Omit<TSType, "type"> {
    type: "TSBigIntKeyword";
}
export interface TSBooleanKeyword extends Omit<TSType, "type"> {
    type: "TSBooleanKeyword";
}
export interface TSNeverKeyword extends Omit<TSType, "type"> {
    type: "TSNeverKeyword";
}
export interface TSNullKeyword extends Omit<TSType, "type"> {
    type: "TSNullKeyword";
}
export interface TSNumberKeyword extends Omit<TSType, "type"> {
    type: "TSNumberKeyword";
}
export interface TSObjectKeyword extends Omit<TSType, "type"> {
    type: "TSObjectKeyword";
}
export interface TSStringKeyword extends Omit<TSType, "type"> {
    type: "TSStringKeyword";
}
export interface TSSymbolKeyword extends Omit<TSType, "type"> {
    type: "TSSymbolKeyword";
}
export interface TSUndefinedKeyword extends Omit<TSType, "type"> {
    type: "TSUndefinedKeyword";
}
export interface TSUnknownKeyword extends Omit<TSType, "type"> {
    type: "TSUnknownKeyword";
}
export interface TSVoidKeyword extends Omit<TSType, "type"> {
    type: "TSVoidKeyword";
}
export interface TSThisType extends Omit<TSType, "type"> {
    type: "TSThisType";
}
export interface TSArrayType extends Omit<TSType, "type"> {
    type: "TSArrayType";
    elementType: K.TSTypeKind;
}
export interface TSLiteralType extends Omit<TSType, "type"> {
    type: "TSLiteralType";
    literal: K.NumericLiteralKind | K.StringLiteralKind | K.BooleanLiteralKind | K.TemplateLiteralKind | K.UnaryExpressionKind;
}
export interface TSUnionType extends Omit<TSType, "type"> {
    type: "TSUnionType";
    types: K.TSTypeKind[];
}
export interface TSIntersectionType extends Omit<TSType, "type"> {
    type: "TSIntersectionType";
    types: K.TSTypeKind[];
}
export interface TSConditionalType extends Omit<TSType, "type"> {
    type: "TSConditionalType";
    checkType: K.TSTypeKind;
    extendsType: K.TSTypeKind;
    trueType: K.TSTypeKind;
    falseType: K.TSTypeKind;
}
export interface TSInferType extends Omit<TSType, "type"> {
    type: "TSInferType";
    typeParameter: K.TSTypeParameterKind;
}
export interface TSTypeParameter extends Omit<Identifier, "type" | "name"> {
    type: "TSTypeParameter";
    name: string;
    constraint: K.TSTypeKind | undefined;
    default: K.TSTypeKind | undefined;
}
export interface TSParenthesizedType extends Omit<TSType, "type"> {
    type: "TSParenthesizedType";
    typeAnnotation: K.TSTypeKind;
}
export interface TSFunctionType extends Omit<TSType, "type">, TSHasOptionalTypeParameters, TSHasOptionalTypeAnnotation {
    type: "TSFunctionType";
    parameters: (K.IdentifierKind | K.RestElementKind | K.ArrayPatternKind | K.ObjectPatternKind)[];
}
export interface TSConstructorType extends Omit<TSType, "type">, TSHasOptionalTypeParameters, TSHasOptionalTypeAnnotation {
    type: "TSConstructorType";
    parameters: (K.IdentifierKind | K.RestElementKind | K.ArrayPatternKind | K.ObjectPatternKind)[];
}
export interface TSDeclareFunction extends Omit<Declaration, "type">, TSHasOptionalTypeParameters {
    type: "TSDeclareFunction";
    declare: boolean;
    async: boolean;
    generator: boolean;
    id: K.IdentifierKind | null;
    params: K.PatternKind[];
    returnType: K.TSTypeAnnotationKind | K.NoopKind | null;
}
export interface TSDeclareMethod extends Omit<Declaration, "type">, TSHasOptionalTypeParameters {
    type: "TSDeclareMethod";
    async: boolean;
    generator: boolean;
    params: K.PatternKind[];
    abstract: boolean;
    accessibility: "public" | "private" | "protected" | undefined;
    static: boolean;
    computed: boolean;
    optional: boolean;
    key: K.IdentifierKind | K.StringLiteralKind | K.NumericLiteralKind | K.ExpressionKind;
    kind: "get" | "set" | "method" | "constructor";
    access: "public" | "private" | "protected" | undefined;
    decorators: K.DecoratorKind[] | null;
    returnType: K.TSTypeAnnotationKind | K.NoopKind | null;
}
export interface TSMappedType extends Omit<TSType, "type"> {
    type: "TSMappedType";
    readonly: boolean | "+" | "-";
    typeParameter: K.TSTypeParameterKind;
    optional: boolean | "+" | "-";
    typeAnnotation: K.TSTypeKind | null;
}
export interface TSTupleType extends Omit<TSType, "type"> {
    type: "TSTupleType";
    elementTypes: K.TSTypeKind[];
}
export interface TSRestType extends Omit<TSType, "type"> {
    type: "TSRestType";
    typeAnnotation: K.TSTypeKind;
}
export interface TSOptionalType extends Omit<TSType, "type"> {
    type: "TSOptionalType";
    typeAnnotation: K.TSTypeKind;
}
export interface TSIndexedAccessType extends Omit<TSType, "type"> {
    type: "TSIndexedAccessType";
    objectType: K.TSTypeKind;
    indexType: K.TSTypeKind;
}
export interface TSTypeOperator extends Omit<TSType, "type"> {
    type: "TSTypeOperator";
    operator: string;
    typeAnnotation: K.TSTypeKind;
}
export interface TSIndexSignature extends Omit<Declaration, "type">, TSHasOptionalTypeAnnotation {
    type: "TSIndexSignature";
    parameters: K.IdentifierKind[];
    readonly: boolean;
}
export interface TSPropertySignature extends Omit<Declaration, "type">, TSHasOptionalTypeAnnotation {
    type: "TSPropertySignature";
    key: K.ExpressionKind;
    computed: boolean;
    readonly: boolean;
    optional: boolean;
    initializer: K.ExpressionKind | null;
}
export interface TSMethodSignature extends Omit<Declaration, "type">, TSHasOptionalTypeParameters, TSHasOptionalTypeAnnotation {
    type: "TSMethodSignature";
    key: K.ExpressionKind;
    computed: boolean;
    optional: boolean;
    parameters: (K.IdentifierKind | K.RestElementKind | K.ArrayPatternKind | K.ObjectPatternKind)[];
}
export interface TSTypePredicate extends Omit<TSTypeAnnotation, "type" | "typeAnnotation"> {
    type: "TSTypePredicate";
    parameterName: K.IdentifierKind | K.TSThisTypeKind;
    typeAnnotation: K.TSTypeAnnotationKind;
}
export interface TSCallSignatureDeclaration extends Omit<Declaration, "type">, TSHasOptionalTypeParameters, TSHasOptionalTypeAnnotation {
    type: "TSCallSignatureDeclaration";
    parameters: (K.IdentifierKind | K.RestElementKind | K.ArrayPatternKind | K.ObjectPatternKind)[];
}
export interface TSConstructSignatureDeclaration extends Omit<Declaration, "type">, TSHasOptionalTypeParameters, TSHasOptionalTypeAnnotation {
    type: "TSConstructSignatureDeclaration";
    parameters: (K.IdentifierKind | K.RestElementKind | K.ArrayPatternKind | K.ObjectPatternKind)[];
}
export interface TSEnumMember extends Omit<Node, "type"> {
    type: "TSEnumMember";
    id: K.IdentifierKind | K.StringLiteralKind;
    initializer: K.ExpressionKind | null;
}
export interface TSTypeQuery extends Omit<TSType, "type"> {
    type: "TSTypeQuery";
    exprName: K.IdentifierKind | K.TSQualifiedNameKind | K.TSImportTypeKind;
}
export interface TSImportType extends Omit<TSType, "type">, TSHasOptionalTypeParameterInstantiation {
    type: "TSImportType";
    argument: K.StringLiteralKind;
    qualifier: K.IdentifierKind | K.TSQualifiedNameKind | undefined;
}
export interface TSTypeLiteral extends Omit<TSType, "type"> {
    type: "TSTypeLiteral";
    members: (K.TSCallSignatureDeclarationKind | K.TSConstructSignatureDeclarationKind | K.TSIndexSignatureKind | K.TSMethodSignatureKind | K.TSPropertySignatureKind)[];
}
export interface TSTypeAssertion extends Omit<Expression, "type">, Omit<Pattern, "type"> {
    type: "TSTypeAssertion";
    typeAnnotation: K.TSTypeKind;
    expression: K.ExpressionKind;
    extra: {
        parenthesized: boolean;
    } | null;
}
export interface TSEnumDeclaration extends Omit<Declaration, "type"> {
    type: "TSEnumDeclaration";
    id: K.IdentifierKind;
    const: boolean;
    declare: boolean;
    members: K.TSEnumMemberKind[];
    initializer: K.ExpressionKind | null;
}
export interface TSTypeAliasDeclaration extends Omit<Declaration, "type">, TSHasOptionalTypeParameters {
    type: "TSTypeAliasDeclaration";
    id: K.IdentifierKind;
    declare: boolean;
    typeAnnotation: K.TSTypeKind;
}
export interface TSModuleBlock extends Omit<Node, "type"> {
    type: "TSModuleBlock";
    body: K.StatementKind[];
}
export interface TSModuleDeclaration extends Omit<Declaration, "type"> {
    type: "TSModuleDeclaration";
    id: K.StringLiteralKind | K.IdentifierKind | K.TSQualifiedNameKind;
    declare: boolean;
    global: boolean;
    body: K.TSModuleBlockKind | K.TSModuleDeclarationKind | null;
}
export interface TSImportEqualsDeclaration extends Omit<Declaration, "type"> {
    type: "TSImportEqualsDeclaration";
    id: K.IdentifierKind;
    isExport: boolean;
    moduleReference: K.IdentifierKind | K.TSQualifiedNameKind | K.TSExternalModuleReferenceKind;
}
export interface TSExternalModuleReference extends Omit<Declaration, "type"> {
    type: "TSExternalModuleReference";
    expression: K.StringLiteralKind;
}
export interface TSExportAssignment extends Omit<Statement, "type"> {
    type: "TSExportAssignment";
    expression: K.ExpressionKind;
}
export interface TSNamespaceExportDeclaration extends Omit<Declaration, "type"> {
    type: "TSNamespaceExportDeclaration";
    id: K.IdentifierKind;
}
export interface TSInterfaceBody extends Omit<Node, "type"> {
    type: "TSInterfaceBody";
    body: (K.TSCallSignatureDeclarationKind | K.TSConstructSignatureDeclarationKind | K.TSIndexSignatureKind | K.TSMethodSignatureKind | K.TSPropertySignatureKind)[];
}
export interface TSInterfaceDeclaration extends Omit<Declaration, "type">, TSHasOptionalTypeParameters {
    type: "TSInterfaceDeclaration";
    id: K.IdentifierKind | K.TSQualifiedNameKind;
    declare: boolean;
    extends: K.TSExpressionWithTypeArgumentsKind[] | null;
    body: K.TSInterfaceBodyKind;
}
export interface TSParameterProperty extends Omit<Pattern, "type"> {
    type: "TSParameterProperty";
    accessibility: "public" | "private" | "protected" | undefined;
    readonly: boolean;
    parameter: K.IdentifierKind | K.AssignmentPatternKind;
}
export interface OptionalMemberExpression extends Omit<MemberExpression, "type"> {
    type: "OptionalMemberExpression";
    optional: boolean;
}
export interface OptionalCallExpression extends Omit<CallExpression, "type"> {
    type: "OptionalCallExpression";
    optional: boolean;
}
export declare type ASTNode = File | Program | Identifier | BlockStatement | EmptyStatement | ExpressionStatement | IfStatement | LabeledStatement | BreakStatement | ContinueStatement | WithStatement | SwitchStatement | SwitchCase | ReturnStatement | ThrowStatement | TryStatement | CatchClause | WhileStatement | DoWhileStatement | ForStatement | VariableDeclaration | ForInStatement | DebuggerStatement | FunctionDeclaration | FunctionExpression | VariableDeclarator | ThisExpression | ArrayExpression | ObjectExpression | Property | Literal | SequenceExpression | UnaryExpression | BinaryExpression | AssignmentExpression | MemberExpression | UpdateExpression | LogicalExpression | ConditionalExpression | NewExpression | CallExpression | RestElement | TypeAnnotation | TSTypeAnnotation | SpreadElementPattern | ArrowFunctionExpression | ForOfStatement | YieldExpression | GeneratorExpression | ComprehensionBlock | ComprehensionExpression | ObjectProperty | PropertyPattern | ObjectPattern | ArrayPattern | MethodDefinition | SpreadElement | AssignmentPattern | ClassPropertyDefinition | ClassProperty | ClassBody | ClassDeclaration | ClassExpression | ImportSpecifier | ImportNamespaceSpecifier | ImportDefaultSpecifier | ImportDeclaration | TaggedTemplateExpression | TemplateLiteral | TemplateElement | SpreadProperty | SpreadPropertyPattern | AwaitExpression | JSXAttribute | JSXIdentifier | JSXNamespacedName | JSXExpressionContainer | JSXMemberExpression | JSXSpreadAttribute | JSXElement | JSXOpeningElement | JSXClosingElement | JSXFragment | JSXText | JSXOpeningFragment | JSXClosingFragment | JSXEmptyExpression | JSXSpreadChild | TypeParameterDeclaration | TSTypeParameterDeclaration | TypeParameterInstantiation | TSTypeParameterInstantiation | ClassImplements | TSExpressionWithTypeArguments | AnyTypeAnnotation | EmptyTypeAnnotation | MixedTypeAnnotation | VoidTypeAnnotation | NumberTypeAnnotation | NumberLiteralTypeAnnotation | NumericLiteralTypeAnnotation | StringTypeAnnotation | StringLiteralTypeAnnotation | BooleanTypeAnnotation | BooleanLiteralTypeAnnotation | NullableTypeAnnotation | NullLiteralTypeAnnotation | NullTypeAnnotation | ThisTypeAnnotation | ExistsTypeAnnotation | ExistentialTypeParam | FunctionTypeAnnotation | FunctionTypeParam | ArrayTypeAnnotation | ObjectTypeAnnotation | ObjectTypeProperty | ObjectTypeSpreadProperty | ObjectTypeIndexer | ObjectTypeCallProperty | ObjectTypeInternalSlot | Variance | QualifiedTypeIdentifier | GenericTypeAnnotation | MemberTypeAnnotation | UnionTypeAnnotation | IntersectionTypeAnnotation | TypeofTypeAnnotation | TypeParameter | InterfaceTypeAnnotation | InterfaceExtends | InterfaceDeclaration | DeclareInterface | TypeAlias | OpaqueType | DeclareTypeAlias | DeclareOpaqueType | TypeCastExpression | TupleTypeAnnotation | DeclareVariable | DeclareFunction | DeclareClass | DeclareModule | DeclareModuleExports | DeclareExportDeclaration | ExportSpecifier | ExportBatchSpecifier | DeclareExportAllDeclaration | InferredPredicate | DeclaredPredicate | ExportDeclaration | Block | Line | Noop | DoExpression | Super | BindExpression | Decorator | MetaProperty | ParenthesizedExpression | ExportDefaultDeclaration | ExportNamedDeclaration | ExportNamespaceSpecifier | ExportDefaultSpecifier | ExportAllDeclaration | CommentBlock | CommentLine | Directive | DirectiveLiteral | InterpreterDirective | StringLiteral | NumericLiteral | BigIntLiteral | NullLiteral | BooleanLiteral | RegExpLiteral | ObjectMethod | ClassPrivateProperty | ClassMethod | ClassPrivateMethod | PrivateName | RestProperty | ForAwaitStatement | Import | TSQualifiedName | TSTypeReference | TSAsExpression | TSNonNullExpression | TSAnyKeyword | TSBigIntKeyword | TSBooleanKeyword | TSNeverKeyword | TSNullKeyword | TSNumberKeyword | TSObjectKeyword | TSStringKeyword | TSSymbolKeyword | TSUndefinedKeyword | TSUnknownKeyword | TSVoidKeyword | TSThisType | TSArrayType | TSLiteralType | TSUnionType | TSIntersectionType | TSConditionalType | TSInferType | TSTypeParameter | TSParenthesizedType | TSFunctionType | TSConstructorType | TSDeclareFunction | TSDeclareMethod | TSMappedType | TSTupleType | TSRestType | TSOptionalType | TSIndexedAccessType | TSTypeOperator | TSIndexSignature | TSPropertySignature | TSMethodSignature | TSTypePredicate | TSCallSignatureDeclaration | TSConstructSignatureDeclaration | TSEnumMember | TSTypeQuery | TSImportType | TSTypeLiteral | TSTypeAssertion | TSEnumDeclaration | TSTypeAliasDeclaration | TSModuleBlock | TSModuleDeclaration | TSImportEqualsDeclaration | TSExternalModuleReference | TSExportAssignment | TSNamespaceExportDeclaration | TSInterfaceBody | TSInterfaceDeclaration | TSParameterProperty | OptionalMemberExpression | OptionalCallExpression;
