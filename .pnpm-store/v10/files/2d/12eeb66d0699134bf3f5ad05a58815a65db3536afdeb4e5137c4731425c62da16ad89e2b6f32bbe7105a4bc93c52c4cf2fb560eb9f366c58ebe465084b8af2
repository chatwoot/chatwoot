import type { Integrations } from '../../core/events/interfaces';
import { LegacySettings } from '../../browser';
import { JSONObject } from '../../core/events';
import { DestinationPlugin, Plugin } from '../../core/plugin';
import { DestinationMiddlewareFunction } from '../middleware';
import { Context } from '../../core/context';
import { Analytics } from '../../core/analytics';
export interface RemotePlugin {
    /** The name of the remote plugin */
    name: string;
    /** The creation name of the remote plugin */
    creationName: string;
    /** The url of the javascript file to load */
    url: string;
    /** The UMD/global name the plugin uses. Plugins are expected to exist here with the `PluginFactory` method signature */
    libraryName: string;
    /** The settings related to this plugin. */
    settings: JSONObject;
}
export declare class ActionDestination implements DestinationPlugin {
    name: string;
    version: string;
    type: Plugin['type'];
    alternativeNames: string[];
    middleware: DestinationMiddlewareFunction[];
    action: Plugin;
    constructor(name: string, action: Plugin);
    addMiddleware(...fn: DestinationMiddlewareFunction[]): void;
    private transform;
    private _createMethod;
    alias: (ctx: Context) => Promise<Context>;
    group: (ctx: Context) => Promise<Context>;
    identify: (ctx: Context) => Promise<Context>;
    page: (ctx: Context) => Promise<Context>;
    screen: (ctx: Context) => Promise<Context>;
    track: (ctx: Context) => Promise<Context>;
    isLoaded(): boolean;
    ready(): Promise<unknown>;
    load(ctx: Context, analytics: Analytics): Promise<unknown>;
    unload(ctx: Context, analytics: Analytics): Promise<unknown> | unknown;
}
export declare function remoteLoader(settings: LegacySettings, userIntegrations: Integrations, mergedIntegrations: Record<string, JSONObject>, obfuscate?: boolean, routingMiddleware?: DestinationMiddlewareFunction): Promise<Plugin[]>;
//# sourceMappingURL=index.d.ts.map