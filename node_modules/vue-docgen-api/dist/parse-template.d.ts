import { TemplateChildNode } from '@vue/compiler-dom';
import { SFCTemplateBlock } from '@vue/compiler-sfc';
import Documentation from './Documentation';
import { ParseOptions } from './parse';
export interface TemplateParserOptions {
    functional: boolean;
}
export declare type Handler = (documentation: Documentation, templateAst: TemplateChildNode, siblings: TemplateChildNode[], options: TemplateParserOptions) => void;
export default function parseTemplate(tpl: Pick<SFCTemplateBlock, 'content' | 'attrs'>, documentation: Documentation, handlers: Handler[], opts: ParseOptions): void;
export declare function traverse(templateAst: TemplateChildNode, documentation: Documentation, handlers: Handler[], siblings: TemplateChildNode[], options: TemplateParserOptions): void;
