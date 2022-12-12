export declare const CONSOLE_LEVELS: readonly ["debug", "info", "warn", "error", "log", "assert"];
declare type LoggerMethod = (...args: unknown[]) => void;
declare type LoggerConsoleMethods = Record<typeof CONSOLE_LEVELS[number], LoggerMethod>;
/** JSDoc */
interface Logger extends LoggerConsoleMethods {
    disable(): void;
    enable(): void;
}
/**
 * Temporarily disable sentry console instrumentations.
 *
 * @param callback The function to run against the original `console` messages
 * @returns The results of the callback
 */
export declare function consoleSandbox<T>(callback: () => T): T;
declare let logger: Logger;
export { logger };
//# sourceMappingURL=logger.d.ts.map