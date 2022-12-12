import { CommanderStatic } from 'commander';
import { CLIOptions } from '@storybook/core-common';
export declare function getDevCli(packageJson: {
    version: string;
    name: string;
}): Promise<CommanderStatic & CLIOptions>;
