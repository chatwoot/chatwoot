interface NormalizedStoriesSpecifier {
    titlePrefix?: string;
    directory: string;
    files?: string;
    importPathMatcher: RegExp;
}
export declare const userOrAutoTitleFromSpecifier: (fileName: string | number, entry: NormalizedStoriesSpecifier, userTitle?: string) => string;
export declare const userOrAutoTitle: (fileName: string, storiesEntries: NormalizedStoriesSpecifier[], userTitle?: string) => string;
export {};
