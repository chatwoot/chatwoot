import { ServerOptions, PluginOption } from 'vite';

type HttpsOption = ServerOptions['https'];
interface ResolvedConfig {
    additionalEntrypoints: string[];
    assetHost: string;
    assetsDir: string;
    configPath: string;
    publicDir: string;
    mode: string;
    entrypointsDir: string;
    sourceCodeDir: string;
    host: string;
    https: HttpsOption;
    port: number;
    publicOutputDir: string;
    watchAdditionalPaths: string[];
    base: string;
    skipProxy: boolean;
    /**
     * @private
     * In the context of the internal code, whether an SSR build should be performed.
     */
    server: ServerOptions;
    /**
     * @private
     * In the context of the internal code, whether an SSR build should be performed.
     */
    ssrBuild: boolean;
    /**
     * A file glob specifying a pattern that matches the SSR entrypoint to build.
     */
    ssrEntrypoint: string;
    /**
     * Specify the output directory for the SSR build (relative to the project root).
     */
    ssrOutputDir: string;
}
type Config = Partial<ResolvedConfig>;
interface PluginOptions {
    root: string;
    outDir: string;
    base: string;
}
type Entrypoints = Array<[string, string]>;
type UnifiedConfig = ResolvedConfig & PluginOptions & {
    entrypoints: Entrypoints;
};
type MultiEnvConfig = Record<string, Config | undefined>;

declare const projectRoot: string;
declare function ViteRubyPlugin(): PluginOption[];

export { Config, Entrypoints, HttpsOption, MultiEnvConfig, PluginOptions, ResolvedConfig, UnifiedConfig, ViteRubyPlugin as default, projectRoot };
