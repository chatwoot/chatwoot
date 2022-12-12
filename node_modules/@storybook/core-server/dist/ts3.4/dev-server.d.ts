import { Router } from 'express';
import { Options } from '@storybook/core-common';
export declare const router: Router;
export declare const DEBOUNCE = 100;
export declare function storybookDevServer(options: Options): Promise<{
    previewResult: void | {
        stats: unknown;
        totalTime: [
            number,
            number
        ];
        bail: (e?: Error) => Promise<void>;
    };
    managerResult: void | {
        stats: unknown;
        totalTime: [
            number,
            number
        ];
        bail: (e?: Error) => Promise<void>;
    };
    address: string;
    networkAddress: string;
}>;
