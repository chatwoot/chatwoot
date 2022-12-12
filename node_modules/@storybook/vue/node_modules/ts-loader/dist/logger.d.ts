import { Chalk } from 'chalk';
import { LoaderOptions } from './interfaces';
declare type LoggerFunc = (message: string) => void;
export interface Logger {
    log: LoggerFunc;
    logInfo: LoggerFunc;
    logWarning: LoggerFunc;
    logError: LoggerFunc;
}
export declare enum LogLevel {
    INFO = 1,
    WARN = 2,
    ERROR = 3
}
export declare function makeLogger(loaderOptions: LoaderOptions, colors: Chalk): Logger;
export {};
//# sourceMappingURL=logger.d.ts.map