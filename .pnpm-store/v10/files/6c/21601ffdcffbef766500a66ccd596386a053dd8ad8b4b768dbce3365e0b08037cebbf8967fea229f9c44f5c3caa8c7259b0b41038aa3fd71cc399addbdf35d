import type { CoreAnalytics } from '../analytics';
import type { CoreContext } from '../context';
interface CorePluginConfig {
    options: any;
    priority: 'critical' | 'non-critical';
}
export declare type PluginType = 'before' | 'after' | 'destination' | 'enrichment' | 'utility';
export interface CorePlugin<Ctx extends CoreContext = CoreContext, Analytics extends CoreAnalytics = any> {
    name: string;
    alternativeNames?: string[];
    version: string;
    type: PluginType;
    isLoaded: () => boolean;
    load: (ctx: Ctx, instance: Analytics, config?: CorePluginConfig) => Promise<unknown>;
    unload?: (ctx: Ctx, instance: Analytics) => Promise<unknown> | unknown;
    ready?: () => Promise<unknown>;
    track?: (ctx: Ctx) => Promise<Ctx> | Ctx;
    identify?: (ctx: Ctx) => Promise<Ctx> | Ctx;
    page?: (ctx: Ctx) => Promise<Ctx> | Ctx;
    group?: (ctx: Ctx) => Promise<Ctx> | Ctx;
    alias?: (ctx: Ctx) => Promise<Ctx> | Ctx;
    screen?: (ctx: Ctx) => Promise<Ctx> | Ctx;
}
export {};
//# sourceMappingURL=index.d.ts.map