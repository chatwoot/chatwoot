import { Event, EventProcessor, Hub, Integration } from '@sentry/types';
/** Options for the InboundFilters integration */
export interface InboundFiltersOptions {
    allowUrls: Array<string | RegExp>;
    denyUrls: Array<string | RegExp>;
    ignoreErrors: Array<string | RegExp>;
    ignoreInternal: boolean;
    /** @deprecated use {@link InboundFiltersOptions.allowUrls} instead. */
    whitelistUrls: Array<string | RegExp>;
    /** @deprecated use {@link InboundFiltersOptions.denyUrls} instead. */
    blacklistUrls: Array<string | RegExp>;
}
/** Inbound filters configurable by the user */
export declare class InboundFilters implements Integration {
    private readonly _options;
    /**
     * @inheritDoc
     */
    static id: string;
    /**
     * @inheritDoc
     */
    name: string;
    constructor(_options?: Partial<InboundFiltersOptions>);
    /**
     * @inheritDoc
     */
    setupOnce(addGlobalEventProcessor: (processor: EventProcessor) => void, getCurrentHub: () => Hub): void;
}
/** JSDoc */
export declare function _mergeOptions(internalOptions?: Partial<InboundFiltersOptions>, clientOptions?: Partial<InboundFiltersOptions>): Partial<InboundFiltersOptions>;
/** JSDoc */
export declare function _shouldDropEvent(event: Event, options: Partial<InboundFiltersOptions>): boolean;
//# sourceMappingURL=inboundfilters.d.ts.map