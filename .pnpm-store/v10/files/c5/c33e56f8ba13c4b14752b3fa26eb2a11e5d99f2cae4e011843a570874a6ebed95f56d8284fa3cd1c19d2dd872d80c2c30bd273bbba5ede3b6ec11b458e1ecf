import type { HistoireConfig, ConfigMode } from '@histoire/shared';
import type { Context } from './context.js';
export declare function getDefaultConfig(): HistoireConfig;
export declare const configFileNames: string[];
export declare function resolveConfigFile(cwd?: string, configFile?: string): string;
export declare function loadConfigFile(configFile: string): Promise<Partial<HistoireConfig>>;
export declare const mergeBuildConfig: <Source extends {
    [x: string]: any;
    [x: number]: any;
    [x: symbol]: any;
}, Defaults extends ({
    [x: string]: any;
    [x: number]: any;
    [x: symbol]: any;
} | (number | boolean | any[] | Record<never, any>))[]>(source: Source, ...defaults: Defaults) => import("defu").Defu<Source, Defaults>;
export declare const mergeConfig: <Source extends {
    [x: string]: any;
    [x: number]: any;
    [x: symbol]: any;
}, Defaults extends ({
    [x: string]: any;
    [x: number]: any;
    [x: symbol]: any;
} | (number | boolean | any[] | Record<never, any>))[]>(source: Source, ...defaults: Defaults) => import("defu").Defu<Source, Defaults>;
export declare function resolveConfig(cwd: string, mode: ConfigMode, configFile: string): Promise<HistoireConfig>;
export declare function processConfig(ctx: Context): Promise<void>;
export declare function defineConfig(config: Partial<HistoireConfig>): Partial<HistoireConfig>;
declare module 'vite' {
    interface UserConfig {
        /**
         * Histoire configuration
         */
        histoire?: Partial<HistoireConfig>;
    }
}
