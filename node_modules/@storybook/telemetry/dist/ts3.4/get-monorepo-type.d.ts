export declare const monorepoConfigs: {
    readonly Nx: "nx.json";
    readonly Turborepo: "turbo.json";
    readonly Lerna: "lerna.json";
    readonly Rush: "rush.json";
    readonly Lage: "lage.config.json";
};
export declare type MonorepoType = keyof typeof monorepoConfigs | 'Workspaces' | undefined;
export declare const getMonorepoType: () => MonorepoType;
