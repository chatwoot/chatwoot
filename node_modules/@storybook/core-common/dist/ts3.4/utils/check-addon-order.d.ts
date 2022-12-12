export declare type OptionsEntry = {
    name: string;
};
export declare type AddonEntry = string | OptionsEntry;
export declare type AddonInfo = {
    name: string;
    inEssentials: boolean;
};
interface Options {
    before: AddonInfo;
    after: AddonInfo;
    configFile: string;
    getConfig: (path: string) => any;
}
export declare const checkAddonOrder: ({ before, after, configFile, getConfig }: Options) => Promise<void>;
export {};
