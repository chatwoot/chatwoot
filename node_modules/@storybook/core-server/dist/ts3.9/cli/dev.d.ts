import { CommanderStatic } from 'commander';
import type { CLIOptions } from '@storybook/core-common';
export declare function getDevCli(packageJson: {
    version: string;
    name: string;
}): Promise<CommanderStatic & CLIOptions>;
