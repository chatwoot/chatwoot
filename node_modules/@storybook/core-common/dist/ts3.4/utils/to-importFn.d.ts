import { NormalizedStoriesSpecifier } from '../types';
export declare function webpackIncludeRegexp(specifier: NormalizedStoriesSpecifier): RegExp;
export declare function toImportFnPart(specifier: NormalizedStoriesSpecifier): string;
export declare function toImportFn(stories: NormalizedStoriesSpecifier[]): string;
