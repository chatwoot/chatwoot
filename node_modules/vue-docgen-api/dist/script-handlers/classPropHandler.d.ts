import * as bt from '@babel/types';
import { NodePath } from 'ast-types/lib/node-path';
import Documentation from '../Documentation';
import { ParseOptions } from '../parse';
/**
 * Extracts prop information from a class-style VueJs component
 * @param documentation
 * @param path
 */
export default function classPropHandler(documentation: Documentation, path: NodePath<bt.ClassDeclaration>, ast: bt.File, opt: ParseOptions): Promise<void>;
