import { encode, decode } from '@jridgewell/sourcemap-codec';

import resolve from './resolve';
import stripFilename from './strip-filename';
import maybeSort from './sort';
import buildBySources from './by-source';
import {
  memoizedState,
  memoizedBinarySearch,
  upperBound,
  lowerBound,
  found as bsFound,
} from './binary-search';
import {
  SOURCES_INDEX,
  SOURCE_LINE,
  SOURCE_COLUMN,
  NAMES_INDEX,
  REV_GENERATED_LINE,
  REV_GENERATED_COLUMN,
} from './sourcemap-segment';

import type { SourceMapSegment, ReverseSegment } from './sourcemap-segment';
import type {
  SourceMapV3,
  DecodedSourceMap,
  EncodedSourceMap,
  InvalidOriginalMapping,
  OriginalMapping,
  InvalidGeneratedMapping,
  GeneratedMapping,
  SourceMapInput,
  Needle,
  SourceNeedle,
  SourceMap,
  EachMapping,
} from './types';
import type { Source } from './by-source';
import type { MemoState } from './binary-search';

export type { SourceMapSegment } from './sourcemap-segment';
export type {
  SourceMapInput,
  SectionedSourceMapInput,
  DecodedSourceMap,
  EncodedSourceMap,
  SectionedSourceMap,
  InvalidOriginalMapping,
  OriginalMapping as Mapping,
  OriginalMapping,
  InvalidGeneratedMapping,
  GeneratedMapping,
  EachMapping,
} from './types';

const LINE_GTR_ZERO = '`line` must be greater than 0 (lines start at line 1)';
const COL_GTR_EQ_ZERO = '`column` must be greater than or equal to 0 (columns start at column 0)';

export const LEAST_UPPER_BOUND = -1;
export const GREATEST_LOWER_BOUND = 1;

/**
 * Returns the encoded (VLQ string) form of the SourceMap's mappings field.
 */
export let encodedMappings: (map: TraceMap) => EncodedSourceMap['mappings'];

/**
 * Returns the decoded (array of lines of segments) form of the SourceMap's mappings field.
 */
export let decodedMappings: (map: TraceMap) => Readonly<DecodedSourceMap['mappings']>;

/**
 * A low-level API to find the segment associated with a generated line/column (think, from a
 * stack trace). Line and column here are 0-based, unlike `originalPositionFor`.
 */
export let traceSegment: (
  map: TraceMap,
  line: number,
  column: number,
) => Readonly<SourceMapSegment> | null;

/**
 * A higher-level API to find the source/line/column associated with a generated line/column
 * (think, from a stack trace). Line is 1-based, but column is 0-based, due to legacy behavior in
 * `source-map` library.
 */
export let originalPositionFor: (
  map: TraceMap,
  needle: Needle,
) => OriginalMapping | InvalidOriginalMapping;

/**
 * Finds the source/line/column directly after the mapping returned by originalPositionFor, provided
 * the found mapping is from the same source and line as the originalPositionFor mapping.
 *
 * Eg, in the code `let id = 1`, `originalPositionAfter` could find the mapping associated with `1`
 * using the same needle that would return `id` when calling `originalPositionFor`.
 */
export let generatedPositionFor: (
  map: TraceMap,
  needle: SourceNeedle,
) => GeneratedMapping | InvalidGeneratedMapping;

/**
 * Iterates each mapping in generated position order.
 */
export let eachMapping: (map: TraceMap, cb: (mapping: EachMapping) => void) => void;

/**
 * Retrieves the source content for a particular source, if its found. Returns null if not.
 */
export let sourceContentFor: (map: TraceMap, source: string) => string | null;

/**
 * A helper that skips sorting of the input map's mappings array, which can be expensive for larger
 * maps.
 */
export let presortedDecodedMap: (map: DecodedSourceMap, mapUrl?: string) => TraceMap;

/**
 * Returns a sourcemap object (with decoded mappings) suitable for passing to a library that expects
 * a sourcemap, or to JSON.stringify.
 */
export let decodedMap: (
  map: TraceMap,
) => Omit<DecodedSourceMap, 'mappings'> & { mappings: readonly SourceMapSegment[][] };

/**
 * Returns a sourcemap object (with encoded mappings) suitable for passing to a library that expects
 * a sourcemap, or to JSON.stringify.
 */
export let encodedMap: (map: TraceMap) => EncodedSourceMap;

export { AnyMap } from './any-map';

export class TraceMap implements SourceMap {
  declare version: SourceMapV3['version'];
  declare file: SourceMapV3['file'];
  declare names: SourceMapV3['names'];
  declare sourceRoot: SourceMapV3['sourceRoot'];
  declare sources: SourceMapV3['sources'];
  declare sourcesContent: SourceMapV3['sourcesContent'];

  declare resolvedSources: string[];
  private declare _encoded: string | undefined;

  private declare _decoded: SourceMapSegment[][] | undefined;
  private _decodedMemo = memoizedState();

  private _bySources: Source[] | undefined = undefined;
  private _bySourceMemos: MemoState[] | undefined = undefined;

  constructor(map: SourceMapInput, mapUrl?: string | null) {
    const isString = typeof map === 'string';

    if (!isString && (map as unknown as { _decodedMemo: any })._decodedMemo) return map as TraceMap;

    const parsed = (isString ? JSON.parse(map) : map) as Exclude<SourceMapInput, string | TraceMap>;

    const { version, file, names, sourceRoot, sources, sourcesContent } = parsed;
    this.version = version;
    this.file = file;
    this.names = names;
    this.sourceRoot = sourceRoot;
    this.sources = sources;
    this.sourcesContent = sourcesContent;

    const from = resolve(sourceRoot || '', stripFilename(mapUrl));
    this.resolvedSources = sources.map((s) => resolve(s || '', from));

    const { mappings } = parsed;
    if (typeof mappings === 'string') {
      this._encoded = mappings;
      this._decoded = undefined;
    } else {
      this._encoded = undefined;
      this._decoded = maybeSort(mappings, isString);
    }
  }

  static {
    encodedMappings = (map) => {
      return (map._encoded ??= encode(map._decoded!));
    };

    decodedMappings = (map) => {
      return (map._decoded ||= decode(map._encoded!));
    };

    traceSegment = (map, line, column) => {
      const decoded = decodedMappings(map);

      // It's common for parent source maps to have pointers to lines that have no
      // mapping (like a "//# sourceMappingURL=") at the end of the child file.
      if (line >= decoded.length) return null;

      return traceSegmentInternal(
        decoded[line],
        map._decodedMemo,
        line,
        column,
        GREATEST_LOWER_BOUND,
      );
    };

    originalPositionFor = (map, { line, column, bias }) => {
      line--;
      if (line < 0) throw new Error(LINE_GTR_ZERO);
      if (column < 0) throw new Error(COL_GTR_EQ_ZERO);

      const decoded = decodedMappings(map);

      // It's common for parent source maps to have pointers to lines that have no
      // mapping (like a "//# sourceMappingURL=") at the end of the child file.
      if (line >= decoded.length) return OMapping(null, null, null, null);

      const segment = traceSegmentInternal(
        decoded[line],
        map._decodedMemo,
        line,
        column,
        bias || GREATEST_LOWER_BOUND,
      );

      if (segment == null) return OMapping(null, null, null, null);
      if (segment.length == 1) return OMapping(null, null, null, null);

      const { names, resolvedSources } = map;
      return OMapping(
        resolvedSources[segment[SOURCES_INDEX]],
        segment[SOURCE_LINE] + 1,
        segment[SOURCE_COLUMN],
        segment.length === 5 ? names[segment[NAMES_INDEX]] : null,
      );
    };

    generatedPositionFor = (map, { source, line, column, bias }) => {
      line--;
      if (line < 0) throw new Error(LINE_GTR_ZERO);
      if (column < 0) throw new Error(COL_GTR_EQ_ZERO);

      const { sources, resolvedSources } = map;
      let sourceIndex = sources.indexOf(source);
      if (sourceIndex === -1) sourceIndex = resolvedSources.indexOf(source);
      if (sourceIndex === -1) return GMapping(null, null);

      const generated = (map._bySources ||= buildBySources(
        decodedMappings(map),
        (map._bySourceMemos = sources.map(memoizedState)),
      ));
      const memos = map._bySourceMemos!;

      const segments = generated[sourceIndex][line];

      if (segments == null) return GMapping(null, null);

      const segment = traceSegmentInternal(
        segments,
        memos[sourceIndex],
        line,
        column,
        bias || GREATEST_LOWER_BOUND,
      );

      if (segment == null) return GMapping(null, null);
      return GMapping(segment[REV_GENERATED_LINE] + 1, segment[REV_GENERATED_COLUMN]);
    };

    eachMapping = (map, cb) => {
      const decoded = decodedMappings(map);
      const { names, resolvedSources } = map;

      for (let i = 0; i < decoded.length; i++) {
        const line = decoded[i];
        for (let j = 0; j < line.length; j++) {
          const seg = line[j];

          const generatedLine = i + 1;
          const generatedColumn = seg[0];
          let source = null;
          let originalLine = null;
          let originalColumn = null;
          let name = null;
          if (seg.length !== 1) {
            source = resolvedSources[seg[1]];
            originalLine = seg[2] + 1;
            originalColumn = seg[3];
          }
          if (seg.length === 5) name = names[seg[4]];

          cb({
            generatedLine,
            generatedColumn,
            source,
            originalLine,
            originalColumn,
            name,
          } as EachMapping);
        }
      }
    };

    sourceContentFor = (map, source) => {
      const { sources, resolvedSources, sourcesContent } = map;
      if (sourcesContent == null) return null;

      let index = sources.indexOf(source);
      if (index === -1) index = resolvedSources.indexOf(source);

      return index === -1 ? null : sourcesContent[index];
    };

    presortedDecodedMap = (map, mapUrl) => {
      const clone = Object.assign({}, map);
      clone.mappings = [];
      const tracer = new TraceMap(clone, mapUrl);
      tracer._decoded = map.mappings;
      return tracer;
    };

    decodedMap = (map) => {
      return {
        version: 3,
        file: map.file,
        names: map.names,
        sourceRoot: map.sourceRoot,
        sources: map.sources,
        sourcesContent: map.sourcesContent,
        mappings: decodedMappings(map),
      };
    };

    encodedMap = (map) => {
      return {
        version: 3,
        file: map.file,
        names: map.names,
        sourceRoot: map.sourceRoot,
        sources: map.sources,
        sourcesContent: map.sourcesContent,
        mappings: encodedMappings(map),
      };
    };
  }
}

function OMapping(
  source: null,
  line: null,
  column: null,
  name: null,
): OriginalMapping | InvalidOriginalMapping;
function OMapping(
  source: string,
  line: number,
  column: number,
  name: string | null,
): OriginalMapping | InvalidOriginalMapping;
function OMapping(
  source: string | null,
  line: number | null,
  column: number | null,
  name: string | null,
): OriginalMapping | InvalidOriginalMapping {
  return { source, line, column, name } as any;
}

function GMapping(line: null, column: null): GeneratedMapping | InvalidGeneratedMapping;
function GMapping(line: number, column: number): GeneratedMapping | InvalidGeneratedMapping;
function GMapping(
  line: number | null,
  column: number | null,
): GeneratedMapping | InvalidGeneratedMapping {
  return { line, column } as any;
}

function traceSegmentInternal(
  segments: SourceMapSegment[],
  memo: MemoState,
  line: number,
  column: number,
  bias: typeof LEAST_UPPER_BOUND | typeof GREATEST_LOWER_BOUND,
): Readonly<SourceMapSegment> | null;
function traceSegmentInternal(
  segments: ReverseSegment[],
  memo: MemoState,
  line: number,
  column: number,
  bias: typeof LEAST_UPPER_BOUND | typeof GREATEST_LOWER_BOUND,
): Readonly<ReverseSegment> | null;
function traceSegmentInternal(
  segments: SourceMapSegment[] | ReverseSegment[],
  memo: MemoState,
  line: number,
  column: number,
  bias: typeof LEAST_UPPER_BOUND | typeof GREATEST_LOWER_BOUND,
): Readonly<SourceMapSegment | ReverseSegment> | null {
  let index = memoizedBinarySearch(segments, column, memo, line);
  if (bsFound) {
    index = (bias === LEAST_UPPER_BOUND ? upperBound : lowerBound)(segments, column, index);
  } else if (bias === LEAST_UPPER_BOUND) index++;

  if (index === -1 || index === segments.length) return null;
  return segments[index];
}
