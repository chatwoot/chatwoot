import { ConsoleLevel } from '@sentry/types';
type ReplayConsoleLevels = Extract<ConsoleLevel, 'info' | 'warn' | 'error' | 'log'>;
type LoggerMethod = (...args: unknown[]) => void;
type LoggerConsoleMethods = Record<ReplayConsoleLevels, LoggerMethod>;
interface LoggerConfig {
    captureExceptions: boolean;
    traceInternals: boolean;
}
interface ReplayLogger extends LoggerConsoleMethods {
    /**
     * Calls `logger.info` but saves breadcrumb in the next tick due to race
     * conditions before replay is initialized.
     */
    infoTick: LoggerMethod;
    /**
     * Captures exceptions (`Error`) if "capture internal exceptions" is enabled
     */
    exception: LoggerMethod;
    /**
     * Configures the logger with additional debugging behavior
     */
    setConfig(config: LoggerConfig): void;
}
export declare const logger: ReplayLogger;
export {};
//# sourceMappingURL=logger.d.ts.map
