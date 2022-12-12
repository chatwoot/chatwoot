import { CoreConfig, StorybookConfig } from '@storybook/core-common';
import { Options } from '@storybook/core-common';
export declare const babel: (_: unknown, options: Options) => Promise<{}>;
export declare const logLevel: (previous: any, options: Options) => any;
export declare const previewHead: (base: any, { configDir, presets }: Options) => Promise<string>;
export declare const env: () => Promise<Record<string, string>>;
export declare const previewBody: (base: any, { configDir, presets }: Options) => Promise<string>;
export declare const previewMainTemplate: () => string;
export declare const managerMainTemplate: () => string;
export declare const previewEntries: (entries: any[], options: {
    modern?: boolean;
}) => any[];
export declare const typescript: () => {
    check: boolean;
    reactDocgen: string;
    reactDocgenTypescriptOptions: {
        shouldExtractLiteralValuesFromEnum: boolean;
        shouldRemoveUndefinedFromOptional: boolean;
        propFilter: (prop: any) => boolean;
        savePropValueAsString: boolean;
    };
};
/**
 * If for some reason this config is not applied, the reason is that
 * likely there is an addon that does `export core = () => ({ someConfig })`,
 * instead of `export core = (existing) => ({ ...existing, someConfig })`,
 * just overwriting everything and not merging with the existing values.
 */
export declare const core: (existing: CoreConfig, options: Options) => Promise<CoreConfig>;
export declare const config: (base: any, options: Options) => Promise<any[]>;
export declare const features: (existing: StorybookConfig['features']) => Promise<StorybookConfig['features']>;
