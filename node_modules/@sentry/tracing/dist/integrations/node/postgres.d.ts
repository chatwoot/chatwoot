import { Hub } from '@sentry/hub';
import { EventProcessor, Integration } from '@sentry/types';
interface PgOptions {
    usePgNative?: boolean;
}
/** Tracing integration for node-postgres package */
export declare class Postgres implements Integration {
    /**
     * @inheritDoc
     */
    static id: string;
    /**
     * @inheritDoc
     */
    name: string;
    private _usePgNative;
    constructor(options?: PgOptions);
    /**
     * @inheritDoc
     */
    setupOnce(_: (callback: EventProcessor) => void, getCurrentHub: () => Hub): void;
}
export {};
//# sourceMappingURL=postgres.d.ts.map