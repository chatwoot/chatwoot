export declare type LogLevel = 'debug' | 'info' | 'warn' | 'error';
export declare type LogMessage = {
    level: LogLevel;
    message: string;
    time?: Date;
    extras?: Record<string, any>;
};
export interface GenericLogger {
    log(level: LogLevel, message: string, extras?: object): void;
    flush(): void;
    logs: LogMessage[];
}
export declare class CoreLogger implements GenericLogger {
    private _logs;
    log(level: LogLevel, message: string, extras?: object): void;
    get logs(): LogMessage[];
    flush(): void;
}
//# sourceMappingURL=index.d.ts.map