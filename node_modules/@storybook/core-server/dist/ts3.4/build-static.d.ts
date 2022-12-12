import { LoadOptions, CLIOptions, BuilderOptions } from '@storybook/core-common';
export declare function buildStaticStandalone(options: CLIOptions & LoadOptions & BuilderOptions): Promise<void>;
export declare function buildStatic({ packageJson, ...loadOptions }: LoadOptions): Promise<void>;
