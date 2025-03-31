export type CodePointReader = {
    representationStart: number;
    representationEnd: number;
    cursor: number;
    codePointSource: Array<number>;
    source: string;
    advanceCodePoint(n?: number): void;
    readCodePoint(n?: number): number | false;
    unreadCodePoint(n?: number): void;
};
