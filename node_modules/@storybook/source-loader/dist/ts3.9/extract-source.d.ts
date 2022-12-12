import type { SourceBlock } from './types';
export * from './types';
/**
 * given a location, extract the text from the full source
 */
export declare function extractSource(location: SourceBlock, lines: string[]): string | null;
