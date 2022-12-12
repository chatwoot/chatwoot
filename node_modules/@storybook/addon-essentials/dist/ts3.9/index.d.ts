interface PresetOptions {
    configDir?: string;
    docs?: boolean;
    controls?: boolean;
    actions?: boolean;
    backgrounds?: boolean;
    viewport?: boolean;
    toolbars?: boolean;
    measure?: boolean;
    outline?: boolean;
}
export declare function addons(options?: PresetOptions): string[];
export {};
