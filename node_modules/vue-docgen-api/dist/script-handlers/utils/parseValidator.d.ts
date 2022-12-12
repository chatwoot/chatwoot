import * as bt from '@babel/types';
import { ParseOptions } from '../../parse';
export default function parseValidatorForValues(validatorNode: bt.Method | bt.ArrowFunctionExpression, ast: bt.File, options: ParseOptions): Promise<string[] | undefined>;
