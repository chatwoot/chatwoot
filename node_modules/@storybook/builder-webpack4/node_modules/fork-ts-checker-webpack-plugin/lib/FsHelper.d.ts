/// <reference types="node" />
import * as fs from 'fs';
export declare function fileExistsSync(filePath: fs.PathLike): boolean;
export declare function throwIfIsInvalidSourceFileError(filepath: string, error: any): void;
