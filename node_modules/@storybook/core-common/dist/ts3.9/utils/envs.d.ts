export declare function loadEnvs(options?: {
    production?: boolean;
}): {
    stringified: Record<string, string>;
    raw: Record<string, string>;
};
export declare const stringifyEnvs: (raw: Record<string, string>) => Record<string, string>;
export declare const stringifyProcessEnvs: (raw: Record<string, string>) => Record<string, string>;
