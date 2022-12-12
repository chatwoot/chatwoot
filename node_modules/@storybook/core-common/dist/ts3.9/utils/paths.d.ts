export declare const getProjectRoot: () => string;
export declare const nodePathsToArray: (nodePath: string) => string[];
/**
 * Ensures that a path starts with `./` or `../`, or is entirely `.` or `..`
 */
export declare function normalizeStoryPath(filename: string): string;
