/**
 * Get the path of the file or directory with input name inside the Storybook cache directory:
 *  - `node_modules/.cache/storybook/{directoryName}` in a Node.js project or npm package
 *  - `.cache/storybook/{directoryName}` otherwise
 *
 * @param fileOrDirectoryName {string} Name of the file or directory
 * @return {string} Absolute path to the file or directory
 */
export declare function resolvePathInStorybookCache(fileOrDirectoryName: string): string;
