import * as bt from '@babel/types';
import { NodePath } from 'ast-types/lib/node-path';
import type { Documentation } from '../Documentation';
import { ParseOptions } from '../parse';
/**
 * Extract information from an setup-style VueJs 3 component
 * about what props can be used with this component
 * @param {NodePath} astPath
 * @param {Array<NodePath>} componentDefinitions
 * @param {string} originalFilePath
 */
export default function setupPropHandler(documentation: Documentation, componentDefinition: NodePath, astPath: bt.File, opt: ParseOptions): Promise<void>;
export declare function getPropsFromLiteralType(documentation: Documentation, typeParamsPathMembers: any): void;
