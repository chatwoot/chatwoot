export interface Options {
    allowRegExp: boolean;
    allowFunction: boolean;
    allowSymbol: boolean;
    allowDate: boolean;
    allowUndefined: boolean;
    allowClass: boolean;
    maxDepth: number;
    space: number | undefined;
    lazyEval: boolean;
}
export declare const isJSON: (input: string) => RegExpMatchArray | null;
export declare const replacer: (options: Options) => any;
export declare const reviver: (options: Options) => any;
export declare const stringify: (data: unknown, options?: Partial<Options>) => string;
export declare const parse: (data: string, options?: Partial<Options>) => any;
