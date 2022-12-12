import * as bt from '@babel/types';
interface ImportedVariable {
    filePath: string[];
    exportName: string;
}
export interface ImportedVariableSet {
    [varname: string]: ImportedVariable;
}
/**
 *
 * @param ast
 * @param varNameFilter
 */
export default function resolveRequired(ast: bt.File, varNameFilter?: string[]): ImportedVariableSet;
export {};
