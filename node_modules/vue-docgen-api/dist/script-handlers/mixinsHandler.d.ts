import * as bt from '@babel/types';
import { NodePath } from 'ast-types/lib/node-path';
import Documentation from '../Documentation';
import { ParseOptions } from '../parse';
/**
 * Look in the mixin section of a component.
 * Parse the file mixins point to.
 * Add the necessary info to the current doc object.
 * Must be run first as mixins do not override components.
 * @param documentation
 * @param componentDefinition
 * @param astPath
 * @param opt
 */
export default function mixinsHandler(documentation: Documentation, componentDefinition: NodePath, astPath: bt.File, opt: ParseOptions): Promise<void>;
