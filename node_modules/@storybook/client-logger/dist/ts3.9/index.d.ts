export declare const logger: {
    readonly trace: (message: any, ...rest: any[]) => void;
    readonly debug: (message: any, ...rest: any[]) => void;
    readonly info: (message: any, ...rest: any[]) => void;
    readonly warn: (message: any, ...rest: any[]) => void;
    readonly error: (message: any, ...rest: any[]) => void;
    readonly log: (message: any, ...rest: any[]) => void;
};
export declare const once: {
    (type: keyof typeof logger): (message: any, ...rest: any[]) => void;
    clear(): void;
    trace: (message: any, ...rest: any[]) => void;
    debug: (message: any, ...rest: any[]) => void;
    info: (message: any, ...rest: any[]) => void;
    warn: (message: any, ...rest: any[]) => void;
    error: (message: any, ...rest: any[]) => void;
    log: (message: any, ...rest: any[]) => void;
};
export declare const pretty: {
    (type: keyof typeof logger): (...args: string[]) => void;
    trace: (...args: string[]) => void;
    debug: (...args: string[]) => void;
    info: (...args: string[]) => void;
    warn: (...args: string[]) => void;
    error: (...args: string[]) => void;
};
