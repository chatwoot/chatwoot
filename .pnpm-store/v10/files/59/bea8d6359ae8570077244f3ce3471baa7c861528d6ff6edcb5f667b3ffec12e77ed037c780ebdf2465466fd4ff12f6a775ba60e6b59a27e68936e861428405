import type { Operation } from './operation/operation';
import type { TokenNode } from '@csstools/css-parser-algorithms';
export type Calculation = {
    inputs: Array<Calculation | TokenNode>;
    operation: Operation;
};
export declare function isCalculation(x: unknown): x is Calculation;
export declare function solve(calculation: Calculation | -1): TokenNode | -1;
