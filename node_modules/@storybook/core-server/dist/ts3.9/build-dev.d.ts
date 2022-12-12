import { CLIOptions, LoadOptions, BuilderOptions } from '@storybook/core-common';
export declare function buildDevStandalone(options: CLIOptions & LoadOptions & BuilderOptions): Promise<void>;
export declare function buildDev(loadOptions: LoadOptions): Promise<void>;
