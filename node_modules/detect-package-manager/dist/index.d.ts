declare type PM = "npm" | "yarn" | "pnpm";
declare const detect: ({ cwd }?: {
    cwd?: string | undefined;
}) => Promise<PM>;

declare function getNpmVersion(pm: PM): Promise<string>;
declare function clearCache(): void;

export { PM, clearCache, detect, getNpmVersion };
