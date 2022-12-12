import { StoriesEntry, NormalizedStoriesSpecifier } from '../types';
export declare const getDirectoryFromWorkingDir: ({ configDir, workingDir, directory, }: NormalizeOptions & {
    directory: string;
}) => string;
export declare const normalizeStoriesEntry: (entry: StoriesEntry, { configDir, workingDir }: NormalizeOptions) => NormalizedStoriesSpecifier;
interface NormalizeOptions {
    configDir: string;
    workingDir: string;
}
export declare const normalizeStories: (entries: StoriesEntry[], options: NormalizeOptions) => NormalizedStoriesSpecifier[];
export {};
