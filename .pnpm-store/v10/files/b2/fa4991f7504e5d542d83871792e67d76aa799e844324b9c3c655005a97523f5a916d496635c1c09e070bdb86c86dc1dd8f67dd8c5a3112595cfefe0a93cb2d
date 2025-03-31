import { Context } from './context.js';
export interface CreateServerOptions {
    port?: number;
    open?: boolean;
}
export declare function createServer(ctx: Context, options?: CreateServerOptions): Promise<{
    server: import("vite").ViteDevServer;
    viteConfigFile: string;
    close: () => Promise<void>;
}>;
