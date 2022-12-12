import * as bt from '@babel/types';
import { NodePath } from 'ast-types/lib/node-path';
import Documentation from '../Documentation';
import { ParseOptions } from '../parse';
/**
 * Returns documentation of the component referenced in the extends property of the component
 * @param {NodePath} astPath
 * @param {Array<NodePath>} componentDefinitions
 * @param {string} originalFilePath
 */
export default function extendsHandler(documentation: Documentation, componentDefinition: NodePath, astPath: bt.File, opt: ParseOptions): Promise<void>;
