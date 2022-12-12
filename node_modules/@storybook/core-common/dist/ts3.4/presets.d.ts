import { CLIOptions, LoadedPreset, LoadOptions, PresetConfig, Presets, BuilderOptions } from './types';
export declare function filterPresetsConfig(presetsConfig: PresetConfig[]): PresetConfig[];
/**
 * Parse an addon into either a managerEntries or a preset. Throw on invalid input.
 *
 * Valid inputs:
 * - '@storybook/addon-actions/manager'
 *   =>  { type: 'virtual', item }
 *
 * - '@storybook/addon-docs/preset'
 *   =>  { type: 'presets', item }
 *
 * - '@storybook/addon-docs'
 *   =>  { type: 'presets', item: '@storybook/addon-docs/preset' }
 *
 * - { name: '@storybook/addon-docs(/preset)?', options: { ... } }
 *   =>  { type: 'presets', item: { name: '@storybook/addon-docs/preset', options } }
 */
interface ResolvedAddonPreset {
    type: 'presets';
    name: string;
}
interface ResolvedAddonVirtual {
    type: 'virtual';
    name: string;
    managerEntries?: string[];
    previewAnnotations?: string[];
    presets?: (string | {
        name: string;
        options?: any;
    })[];
}
export declare const resolveAddonName: (configDir: string, name: string, options: any) => ResolvedAddonPreset | ResolvedAddonVirtual;
export declare function loadPreset(input: PresetConfig, level: number, storybookOptions: InterPresetOptions): LoadedPreset[];
declare type InterPresetOptions = Pick<CLIOptions & LoadOptions & BuilderOptions, Exclude<keyof (CLIOptions & LoadOptions & BuilderOptions), 'frameworkPresets'>>;
export declare function getPresets(presets: PresetConfig[], storybookOptions: InterPresetOptions): Presets;
export declare function loadAllPresets(options: CLIOptions & LoadOptions & BuilderOptions & {
    corePresets: string[];
    overridePresets: string[];
    frameworkPresets: string[];
}): Presets;
export {};
