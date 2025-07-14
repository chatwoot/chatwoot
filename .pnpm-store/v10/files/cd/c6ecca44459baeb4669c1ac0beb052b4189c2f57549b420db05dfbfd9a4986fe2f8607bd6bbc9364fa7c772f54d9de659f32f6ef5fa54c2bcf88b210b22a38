/// <reference types="node" />
import type ModuleClass from "module";
export declare function createRequire(filename: string): ReturnType<typeof ModuleClass.createRequire>;
export declare function getRequireFromLinter(): NodeRequire | null;
export declare function getRequireFromCwd(): NodeRequire | null;
export declare function requireFromLinter<T>(module: string): T | null;
export declare function requireFromCwd<T>(module: string): T | null;
export declare function loadNewest<T>(items: {
    getPkg: () => {
        version: string;
    } | null;
    get: () => T | null;
}[]): T;
