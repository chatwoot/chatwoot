export declare const sanitize: (string: string) => string;
export declare const toId: (kind: string, name: string) => string;
export declare const storyNameFromExport: (key: string) => string;
declare type StoryDescriptor = string[] | RegExp;
export interface IncludeExcludeOptions {
    includeStories?: StoryDescriptor;
    excludeStories?: StoryDescriptor;
}
export declare function isExportStory(key: string, { includeStories, excludeStories }: IncludeExcludeOptions): boolean | null;
export interface SeparatorOptions {
    rootSeparator: string | RegExp;
    groupSeparator: string | RegExp;
}
export declare const parseKind: (kind: string, { rootSeparator, groupSeparator }: SeparatorOptions) => {
    root: string | null;
    groups: string[];
};
export {};
