import npmLog from 'npmlog';
import chalk from 'chalk';
export declare const colors: {
    pink: chalk.Chalk;
    purple: chalk.Chalk;
    orange: chalk.Chalk;
    green: chalk.Chalk;
    blue: chalk.Chalk;
    red: chalk.Chalk;
    gray: chalk.Chalk;
};
export declare const logger: {
    verbose: (message: string) => void;
    info: (message: string) => void;
    plain: (message: string) => void;
    line: (count?: number) => void;
    warn: (message: string) => void;
    error: (message: string) => void;
    trace: ({ message, time }: {
        message: string;
        time: [
            number,
            number
        ];
    }) => void;
    setLevel: (level?: string) => void;
};
export { npmLog as instance };
export declare const once: {
    (type: 'verbose' | 'info' | 'warn' | 'error'): (message: string) => void;
    clear(): void;
    verbose: (message: string) => void;
    info: (message: string) => void;
    warn: (message: string) => void;
    error: (message: string) => void;
};
