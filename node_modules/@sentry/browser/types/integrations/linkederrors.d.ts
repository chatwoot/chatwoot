import { Event, EventHint, Exception, ExtendedError, Integration } from '@sentry/types';
interface LinkedErrorsOptions {
    key: string;
    limit: number;
}
/** Adds SDK info to an event. */
export declare class LinkedErrors implements Integration {
    /**
     * @inheritDoc
     */
    static id: string;
    /**
     * @inheritDoc
     */
    readonly name: string;
    /**
     * @inheritDoc
     */
    private readonly _key;
    /**
     * @inheritDoc
     */
    private readonly _limit;
    /**
     * @inheritDoc
     */
    constructor(options?: Partial<LinkedErrorsOptions>);
    /**
     * @inheritDoc
     */
    setupOnce(): void;
}
/**
 * @inheritDoc
 */
export declare function _handler(key: string, limit: number, event: Event, hint?: EventHint): Event | null;
/**
 * JSDOC
 */
export declare function _walkErrorTree(limit: number, error: ExtendedError, key: string, stack?: Exception[]): Exception[];
export {};
//# sourceMappingURL=linkederrors.d.ts.map