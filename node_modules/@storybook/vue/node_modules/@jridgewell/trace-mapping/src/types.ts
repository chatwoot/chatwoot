import type { SourceMapSegment } from './sourcemap-segment';
import type { TraceMap } from './trace-mapping';

export interface SourceMapV3 {
  file?: string | null;
  names: string[];
  sourceRoot?: string;
  sources: (string | null)[];
  sourcesContent?: (string | null)[];
  version: 3;
}

export interface EncodedSourceMap extends SourceMapV3 {
  mappings: string;
}

export interface DecodedSourceMap extends SourceMapV3 {
  mappings: SourceMapSegment[][];
}

export interface Section {
  offset: {
    line: number;
    column: number;
  };
  map: EncodedSourceMap | DecodedSourceMap | SectionedSourceMap;
}

export interface SectionedSourceMap {
  file?: string | null;
  sections: Section[];
  version: 3;
}

export type OriginalMapping = {
  source: string | null;
  line: number;
  column: number;
  name: string | null;
};

export type InvalidOriginalMapping = {
  source: null;
  line: null;
  column: null;
  name: null;
};

export type GeneratedMapping = {
  line: number;
  column: number;
};
export type InvalidGeneratedMapping = {
  line: null;
  column: null;
};

export type SourceMapInput = string | EncodedSourceMap | DecodedSourceMap | TraceMap;
export type SectionedSourceMapInput = SourceMapInput | SectionedSourceMap;

export type Needle = { line: number; column: number; bias?: 1 | -1 };
export type SourceNeedle = { source: string; line: number; column: number; bias?: 1 | -1 };

export type EachMapping =
  | {
      generatedLine: number;
      generatedColumn: number;
      source: null;
      originalLine: null;
      originalColumn: null;
      name: null;
    }
  | {
      generatedLine: number;
      generatedColumn: number;
      source: string | null;
      originalLine: number;
      originalColumn: number;
      name: string | null;
    };

export abstract class SourceMap {
  declare version: SourceMapV3['version'];
  declare file: SourceMapV3['file'];
  declare names: SourceMapV3['names'];
  declare sourceRoot: SourceMapV3['sourceRoot'];
  declare sources: SourceMapV3['sources'];
  declare sourcesContent: SourceMapV3['sourcesContent'];
  declare resolvedSources: SourceMapV3['sources'];
}
