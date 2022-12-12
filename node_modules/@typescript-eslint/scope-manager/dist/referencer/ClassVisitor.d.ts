import { TSESTree } from '@typescript-eslint/types';
import { Referencer } from './Referencer';
import { Visitor } from './Visitor';
declare class ClassVisitor extends Visitor {
    #private;
    constructor(referencer: Referencer, node: TSESTree.ClassDeclaration | TSESTree.ClassExpression, emitDecoratorMetadata: boolean);
    static visit(referencer: Referencer, node: TSESTree.ClassDeclaration | TSESTree.ClassExpression, emitDecoratorMetadata: boolean): void;
    visit(node: TSESTree.Node | null | undefined): void;
    protected visitClass(node: TSESTree.ClassDeclaration | TSESTree.ClassExpression): void;
    protected visitPropertyDefinition(node: TSESTree.TSAbstractPropertyDefinition | TSESTree.PropertyDefinition): void;
    protected visitFunctionParameterTypeAnnotation(node: TSESTree.Parameter, withDecorators: boolean): void;
    protected visitMethodFunction(node: TSESTree.FunctionExpression, methodNode: TSESTree.MethodDefinition): void;
    protected visitProperty(node: TSESTree.PropertyDefinition | TSESTree.TSAbstractPropertyDefinition | TSESTree.TSAbstractMethodDefinition): void;
    protected visitMethod(node: TSESTree.MethodDefinition): void;
    protected visitType(node: TSESTree.Node | null | undefined): void;
    protected visitMetadataType(node: TSESTree.TSTypeAnnotation | null | undefined, withDecorators: boolean): void;
    protected ClassBody(node: TSESTree.ClassBody): void;
    protected PropertyDefinition(node: TSESTree.PropertyDefinition): void;
    protected MethodDefinition(node: TSESTree.MethodDefinition): void;
    protected TSAbstractPropertyDefinition(node: TSESTree.TSAbstractPropertyDefinition): void;
    protected TSAbstractMethodDefinition(node: TSESTree.TSAbstractMethodDefinition): void;
    protected Identifier(node: TSESTree.Identifier): void;
    protected PrivateIdentifier(): void;
}
export { ClassVisitor };
//# sourceMappingURL=ClassVisitor.d.ts.map