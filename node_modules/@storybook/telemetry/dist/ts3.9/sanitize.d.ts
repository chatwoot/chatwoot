/// <reference types="node" />
export interface IErrorWithStdErrAndStdOut {
    stderr?: Buffer | string;
    stdout?: Buffer | string;
    [key: string]: unknown;
}
export declare function cleanPaths(str: string, separator?: string): string;
export declare function sanitizeError(error: Error, pathSeparator?: string): string;
