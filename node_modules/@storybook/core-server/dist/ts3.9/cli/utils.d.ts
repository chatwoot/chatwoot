import type { CLIOptions } from '@storybook/core-common';
import type { ProdCliOptions } from './prod';
export declare function parseList(str: string): string[];
export declare function getEnvConfig(program: Record<string, any>, configEnv: Record<string, any>): void;
export declare function checkDeprecatedFlags({ dll, uiDll, docsDll, staticDir, }: CLIOptions | ProdCliOptions): void;
