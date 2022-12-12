export = TerserPlugin;
/** @typedef {import("schema-utils/declarations/validate").Schema} Schema */
/** @typedef {import("webpack").Compiler} Compiler */
/** @typedef {import("webpack").Compilation} Compilation */
/** @typedef {import("webpack").WebpackError} WebpackError */
/** @typedef {import("webpack").Asset} Asset */
/** @typedef {import("./utils.js").TerserECMA} TerserECMA */
/** @typedef {import("./utils.js").TerserOptions} TerserOptions */
/** @typedef {import("jest-worker").Worker} JestWorker */
/** @typedef {import("@jridgewell/trace-mapping").SourceMapInput} SourceMapInput */
/** @typedef {RegExp | string} Rule */
/** @typedef {Rule[] | Rule} Rules */
/**
 * @callback ExtractCommentsFunction
 * @param {any} astNode
 * @param {{ value: string, type: 'comment1' | 'comment2' | 'comment3' | 'comment4', pos: number, line: number, col: number }} comment
 * @returns {boolean}
 */
/**
 * @typedef {boolean | 'all' | 'some' | RegExp | ExtractCommentsFunction} ExtractCommentsCondition
 */
/**
 * @typedef {string | ((fileData: any) => string)} ExtractCommentsFilename
 */
/**
 * @typedef {boolean | string | ((commentsFile: string) => string)} ExtractCommentsBanner
 */
/**
 * @typedef {Object} ExtractCommentsObject
 * @property {ExtractCommentsCondition} [condition]
 * @property {ExtractCommentsFilename} [filename]
 * @property {ExtractCommentsBanner} [banner]
 */
/**
 * @typedef {ExtractCommentsCondition | ExtractCommentsObject} ExtractCommentsOptions
 */
/**
 * @typedef {Object} MinimizedResult
 * @property {string} code
 * @property {SourceMapInput} [map]
 * @property {Array<Error | string>} [errors]
 * @property {Array<Error | string>} [warnings]
 * @property {Array<string>} [extractedComments]
 */
/**
 * @typedef {{ [file: string]: string }} Input
 */
/**
 * @typedef {{ [key: string]: any }} CustomOptions
 */
/**
 * @template T
 * @typedef {T extends infer U ? U : CustomOptions} InferDefaultType
 */
/**
 * @typedef {Object} PredefinedOptions
 * @property {boolean} [module]
 * @property {TerserECMA} [ecma]
 */
/**
 * @template T
 * @typedef {PredefinedOptions & InferDefaultType<T>} MinimizerOptions
 */
/**
 * @template T
 * @callback BasicMinimizerImplementation
 * @param {Input} input
 * @param {SourceMapInput | undefined} sourceMap
 * @param {MinimizerOptions<T>} minifyOptions
 * @param {ExtractCommentsOptions | undefined} extractComments
 * @returns {Promise<MinimizedResult>}
 */
/**
 * @typedef {object} MinimizeFunctionHelpers
 * @property {() => string | undefined} [getMinimizerVersion]
 */
/**
 * @template T
 * @typedef {BasicMinimizerImplementation<T> & MinimizeFunctionHelpers} MinimizerImplementation
 */
/**
 * @template T
 * @typedef {Object} InternalOptions
 * @property {string} name
 * @property {string} input
 * @property {SourceMapInput | undefined} inputSourceMap
 * @property {ExtractCommentsOptions | undefined} extractComments
 * @property {{ implementation: MinimizerImplementation<T>, options: MinimizerOptions<T> }} minimizer
 */
/**
 * @template T
 * @typedef {JestWorker & { transform: (options: string) => MinimizedResult, minify: (options: InternalOptions<T>) => MinimizedResult }} MinimizerWorker
 */
/**
 * @typedef {undefined | boolean | number} Parallel
 */
/**
 * @typedef {Object} BasePluginOptions
 * @property {Rules} [test]
 * @property {Rules} [include]
 * @property {Rules} [exclude]
 * @property {ExtractCommentsOptions} [extractComments]
 * @property {Parallel} [parallel]
 */
/**
 * @template T
 * @typedef {T extends TerserOptions ? { minify?: MinimizerImplementation<T> | undefined, terserOptions?: MinimizerOptions<T> | undefined } : { minify: MinimizerImplementation<T>, terserOptions?: MinimizerOptions<T> | undefined }} DefinedDefaultMinimizerAndOptions
 */
/**
 * @template T
 * @typedef {BasePluginOptions & { minimizer: { implementation: MinimizerImplementation<T>, options: MinimizerOptions<T> } }} InternalPluginOptions
 */
/**
 * @template [T=TerserOptions]
 */
declare class TerserPlugin<T = import("terser").MinifyOptions> {
  /**
   * @private
   * @param {any} input
   * @returns {boolean}
   */
  private static isSourceMap;
  /**
   * @private
   * @param {unknown} warning
   * @param {string} file
   * @returns {Error}
   */
  private static buildWarning;
  /**
   * @private
   * @param {any} error
   * @param {string} file
   * @param {TraceMap} [sourceMap]
   * @param {Compilation["requestShortener"]} [requestShortener]
   * @returns {Error}
   */
  private static buildError;
  /**
   * @private
   * @param {Parallel} parallel
   * @returns {number}
   */
  private static getAvailableNumberOfCores;
  /**
   * @private
   * @param {any} environment
   * @returns {TerserECMA}
   */
  private static getEcmaVersion;
  /**
   * @param {BasePluginOptions & DefinedDefaultMinimizerAndOptions<T>} [options]
   */
  constructor(
    options?:
      | (BasePluginOptions & DefinedDefaultMinimizerAndOptions<T>)
      | undefined
  );
  /**
   * @private
   * @type {InternalPluginOptions<T>}
   */
  private options;
  /**
   * @private
   * @param {Compiler} compiler
   * @param {Compilation} compilation
   * @param {Record<string, import("webpack").sources.Source>} assets
   * @param {{availableNumberOfCores: number}} optimizeOptions
   * @returns {Promise<void>}
   */
  private optimize;
  /**
   * @param {Compiler} compiler
   * @returns {void}
   */
  apply(compiler: Compiler): void;
}
declare namespace TerserPlugin {
  export {
    terserMinify,
    uglifyJsMinify,
    swcMinify,
    esbuildMinify,
    Schema,
    Compiler,
    Compilation,
    WebpackError,
    Asset,
    TerserECMA,
    TerserOptions,
    JestWorker,
    SourceMapInput,
    Rule,
    Rules,
    ExtractCommentsFunction,
    ExtractCommentsCondition,
    ExtractCommentsFilename,
    ExtractCommentsBanner,
    ExtractCommentsObject,
    ExtractCommentsOptions,
    MinimizedResult,
    Input,
    CustomOptions,
    InferDefaultType,
    PredefinedOptions,
    MinimizerOptions,
    BasicMinimizerImplementation,
    MinimizeFunctionHelpers,
    MinimizerImplementation,
    InternalOptions,
    MinimizerWorker,
    Parallel,
    BasePluginOptions,
    DefinedDefaultMinimizerAndOptions,
    InternalPluginOptions,
  };
}
type Compiler = import("webpack").Compiler;
type BasePluginOptions = {
  test?: Rules | undefined;
  include?: Rules | undefined;
  exclude?: Rules | undefined;
  extractComments?: ExtractCommentsOptions | undefined;
  parallel?: Parallel;
};
type DefinedDefaultMinimizerAndOptions<T> = T extends TerserOptions
  ? {
      minify?: MinimizerImplementation<T> | undefined;
      terserOptions?: MinimizerOptions<T> | undefined;
    }
  : {
      minify: MinimizerImplementation<T>;
      terserOptions?: MinimizerOptions<T> | undefined;
    };
import { terserMinify } from "./utils";
import { uglifyJsMinify } from "./utils";
import { swcMinify } from "./utils";
import { esbuildMinify } from "./utils";
type Schema = import("schema-utils/declarations/validate").Schema;
type Compilation = import("webpack").Compilation;
type WebpackError = import("webpack").WebpackError;
type Asset = import("webpack").Asset;
type TerserECMA = import("./utils.js").TerserECMA;
type TerserOptions = import("./utils.js").TerserOptions;
type JestWorker = import("jest-worker").Worker;
type SourceMapInput = import("@jridgewell/trace-mapping").SourceMapInput;
type Rule = RegExp | string;
type Rules = Rule[] | Rule;
type ExtractCommentsFunction = (
  astNode: any,
  comment: {
    value: string;
    type: "comment1" | "comment2" | "comment3" | "comment4";
    pos: number;
    line: number;
    col: number;
  }
) => boolean;
type ExtractCommentsCondition =
  | boolean
  | "all"
  | "some"
  | RegExp
  | ExtractCommentsFunction;
type ExtractCommentsFilename = string | ((fileData: any) => string);
type ExtractCommentsBanner =
  | string
  | boolean
  | ((commentsFile: string) => string);
type ExtractCommentsObject = {
  condition?: ExtractCommentsCondition | undefined;
  filename?: ExtractCommentsFilename | undefined;
  banner?: ExtractCommentsBanner | undefined;
};
type ExtractCommentsOptions = ExtractCommentsCondition | ExtractCommentsObject;
type MinimizedResult = {
  code: string;
  map?: import("@jridgewell/trace-mapping").SourceMapInput | undefined;
  errors?: (string | Error)[] | undefined;
  warnings?: (string | Error)[] | undefined;
  extractedComments?: string[] | undefined;
};
type Input = {
  [file: string]: string;
};
type CustomOptions = {
  [key: string]: any;
};
type InferDefaultType<T> = T extends infer U ? U : CustomOptions;
type PredefinedOptions = {
  module?: boolean | undefined;
  ecma?: import("terser").ECMA | undefined;
};
type MinimizerOptions<T> = PredefinedOptions & InferDefaultType<T>;
type BasicMinimizerImplementation<T> = (
  input: Input,
  sourceMap: SourceMapInput | undefined,
  minifyOptions: MinimizerOptions<T>,
  extractComments: ExtractCommentsOptions | undefined
) => Promise<MinimizedResult>;
type MinimizeFunctionHelpers = {
  getMinimizerVersion?: (() => string | undefined) | undefined;
};
type MinimizerImplementation<T> = BasicMinimizerImplementation<T> &
  MinimizeFunctionHelpers;
type InternalOptions<T> = {
  name: string;
  input: string;
  inputSourceMap: SourceMapInput | undefined;
  extractComments: ExtractCommentsOptions | undefined;
  minimizer: {
    implementation: MinimizerImplementation<T>;
    options: MinimizerOptions<T>;
  };
};
type MinimizerWorker<T> = Worker & {
  transform: (options: string) => MinimizedResult;
  minify: (options: InternalOptions<T>) => MinimizedResult;
};
type Parallel = undefined | boolean | number;
type InternalPluginOptions<T> = BasePluginOptions & {
  minimizer: {
    implementation: MinimizerImplementation<T>;
    options: MinimizerOptions<T>;
  };
};
import { minify } from "./minify";
import { Worker } from "jest-worker";
