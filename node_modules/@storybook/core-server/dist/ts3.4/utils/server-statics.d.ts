import { Options } from '@storybook/core-common';
export declare function useStatics(router: any, options: Options): Promise<void>;
export declare const parseStaticDir: (arg: string) => Promise<{
    staticDir: string;
    staticPath: string;
    targetDir: string;
    targetEndpoint: string;
}>;
