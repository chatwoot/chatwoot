import { FileSystem } from './FileSystem';
/**
 * It's an implementation of FileSystem interface which reads from the real file system, but write to the in-memory file system.
 *
 * @param caseSensitive
 * @param realFileSystem
 */
declare function createPassiveFileSystem(caseSensitive: boolean | undefined, realFileSystem: FileSystem): FileSystem;
export { createPassiveFileSystem };
