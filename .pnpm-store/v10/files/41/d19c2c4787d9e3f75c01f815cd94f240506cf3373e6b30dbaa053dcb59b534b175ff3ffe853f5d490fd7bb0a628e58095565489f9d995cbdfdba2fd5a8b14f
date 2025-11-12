import { CodePointReader } from './interfaces/code-point-reader';
export declare class Reader implements CodePointReader {
    cursor: number;
    source: string;
    codePointSource: Array<number>;
    length: number;
    representationStart: number;
    representationEnd: number;
    constructor(source: string);
    advanceCodePoint(n?: number): void;
    readCodePoint(n?: number): number | false;
    unreadCodePoint(n?: number): void;
}
