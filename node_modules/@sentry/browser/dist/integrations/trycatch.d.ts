import { Integration } from '@sentry/types';
/** JSDoc */
interface TryCatchOptions {
    setTimeout: boolean;
    setInterval: boolean;
    requestAnimationFrame: boolean;
    XMLHttpRequest: boolean;
    eventTarget: boolean | string[];
}
/** Wrap timer functions and event targets to catch errors and provide better meta data */
export declare class TryCatch implements Integration {
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
    constructor(options?: Partial<TryCatchOptions>);
    /**
     * Wrap timer functions and event targets to catch errors
     * and provide better metadata.
     */
    setupOnce(): void;
}
export {};
//# sourceMappingURL=trycatch.d.ts.map