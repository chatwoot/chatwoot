export declare function indent(lines: string[], count?: number): string[];
export declare function unindent(code: string): string;
interface AutoBuildingOject {
    key: string;
    cache: Record<string | symbol, AutoBuildingOject>;
    target: any;
    proxy: any;
}
export declare function createAutoBuildingObject(format?: (key: string) => string, specialKeysHandler?: (target: any, p: string | symbol) => (() => unknown) | null, key?: string, depth?: number): AutoBuildingOject;
export {};
