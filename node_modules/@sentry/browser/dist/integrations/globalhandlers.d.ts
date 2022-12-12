import { Integration } from '@sentry/types';
declare type GlobalHandlersIntegrationsOptionKeys = 'onerror' | 'onunhandledrejection';
/** JSDoc */
declare type GlobalHandlersIntegrations = Record<GlobalHandlersIntegrationsOptionKeys, boolean>;
/** Global handlers */
export declare class GlobalHandlers implements Integration {
    /**
     * @inheritDoc
     */
    static id: string;
    /**
     * @inheritDoc
     */
    name: string;
    /** JSDoc */
    private readonly _options;
    /**
     * Stores references functions to installing handlers. Will set to undefined
     * after they have been run so that they are not used twice.
     */
    private _installFunc;
    /** JSDoc */
    constructor(options?: GlobalHandlersIntegrations);
    /**
     * @inheritDoc
     */
    setupOnce(): void;
}
export {};
//# sourceMappingURL=globalhandlers.d.ts.map