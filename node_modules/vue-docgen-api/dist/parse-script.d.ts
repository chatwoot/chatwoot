import * as bt from '@babel/types';
import { NodePath } from 'ast-types/lib/node-path';
import Map from 'ts-map';
import Documentation from './Documentation';
import { ParseOptions } from './parse';
export declare type Handler = (doc: Documentation, componentDefinition: NodePath, ast: bt.File, opt: ParseOptions) => Promise<void>;
export default function parseScript(source: string, options: ParseOptions, documentation?: Documentation, forceSingleExport?: boolean, noNeedForExport?: boolean): Promise<Documentation[] | undefined>;
export declare function addDefaultAndExecuteHandlers(componentDefinitions: Map<string, NodePath>, ast: bt.File, options: ParseOptions, documentation?: Documentation, forceSingleExport?: boolean): Promise<Documentation[] | undefined>;
