interface PostinstallContext {
    root: any;
    api: any;
}
export declare function addPreset(preset: string, presetOptions: any, { api, root }: PostinstallContext): void;
export {};
