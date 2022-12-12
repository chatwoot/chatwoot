import { NormalizedStoriesSpecifier } from '../types';
export declare const toRequireContext: (specifier: NormalizedStoriesSpecifier) => {
    path: string;
    recursive: boolean;
    match: RegExp;
};
export declare const toRequireContextString: (specifier: NormalizedStoriesSpecifier) => string;
