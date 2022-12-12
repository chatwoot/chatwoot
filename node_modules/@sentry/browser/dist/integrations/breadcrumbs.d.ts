import { Event, Integration } from '@sentry/types';
/** JSDoc */
interface BreadcrumbsOptions {
    console: boolean;
    dom: boolean | {
        serializeAttribute: string | string[];
    };
    fetch: boolean;
    history: boolean;
    sentry: boolean;
    xhr: boolean;
}
/**
 * Default Breadcrumbs instrumentations
 * TODO: Deprecated - with v6, this will be renamed to `Instrument`
 */
export declare class Breadcrumbs implements Integration {
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
     * @inheritDoc
     */
    constructor(options?: Partial<BreadcrumbsOptions>);
    /**
     * Create a breadcrumb of `sentry` from the events themselves
     */
    addSentryBreadcrumb(event: Event): void;
    /**
     * Instrument browser built-ins w/ breadcrumb capturing
     *  - Console API
     *  - DOM API (click/typing)
     *  - XMLHttpRequest API
     *  - Fetch API
     *  - History API
     */
    setupOnce(): void;
}
export {};
//# sourceMappingURL=breadcrumbs.d.ts.map