import { parse as babelParse } from '@babel/parser';
import { BindingMetadata } from '@vue/compiler-core';
import { CodegenResult } from '@vue/compiler-core';
import { CompilerError } from '@vue/compiler-core';
import { CompilerOptions } from '@vue/compiler-core';
import { ElementNode } from '@vue/compiler-core';
import { extractIdentifiers } from '@vue/compiler-core';
import { generateCodeFrame } from '@vue/compiler-core';
import { isInDestructureAssignment } from '@vue/compiler-core';
import { isStaticProperty } from '@vue/compiler-core';
import { LazyResult } from 'postcss';
import MagicString from 'magic-string';
import { ParserOptions } from '@vue/compiler-core';
import { ParserPlugin } from '@babel/parser';
import { RawSourceMap } from 'source-map';
import { Result } from 'postcss';
import { RootNode } from '@vue/compiler-core';
import { shouldTransform as shouldTransformRef } from '@vue/reactivity-transform';
import { SourceLocation } from '@vue/compiler-core';
import { transform as transformRef } from '@vue/reactivity-transform';
import { transformAST as transformRefAST } from '@vue/reactivity-transform';
import { walkIdentifiers } from '@vue/compiler-core';

export declare interface AssetURLOptions {
    /**
     * If base is provided, instead of transforming relative asset urls into
     * imports, they will be directly rewritten to absolute urls.
     */
    base?: string | null;
    /**
     * If true, also processes absolute urls.
     */
    includeAbsolute?: boolean;
    tags?: AssetURLTagConfig;
}

export declare interface AssetURLTagConfig {
    [name: string]: string[];
}

export { babelParse }

export { BindingMetadata }

export { CompilerError }

export { CompilerOptions }

/**
 * Compile `<script setup>`
 * It requires the whole SFC descriptor because we need to handle and merge
 * normal `<script>` + `<script setup>` if both are present.
 */
export declare function compileScript(sfc: SFCDescriptor, options: SFCScriptCompileOptions): SFCScriptBlock;

export declare function compileStyle(options: SFCStyleCompileOptions): SFCStyleCompileResults;

export declare function compileStyleAsync(options: SFCAsyncStyleCompileOptions): Promise<SFCStyleCompileResults>;

export declare function compileTemplate(options: SFCTemplateCompileOptions): SFCTemplateCompileResults;

/**
 * Aligns with postcss-modules
 * https://github.com/css-modules/postcss-modules
 */
declare interface CSSModulesOptions {
    scopeBehaviour?: 'global' | 'local';
    generateScopedName?: string | ((name: string, filename: string, css: string) => string);
    hashPrefix?: string;
    localsConvention?: 'camelCase' | 'camelCaseOnly' | 'dashes' | 'dashesOnly';
    exportGlobals?: boolean;
    globalModulePaths?: RegExp[];
}

export { extractIdentifiers }

export { generateCodeFrame }

declare interface ImportBinding {
    isType: boolean;
    imported: string;
    source: string;
    isFromSetup: boolean;
    isUsedInTemplate: boolean;
}

export { isInDestructureAssignment }

export { isStaticProperty }

export { MagicString }

export declare function parse(source: string, { sourceMap, filename, sourceRoot, pad, ignoreEmpty, compiler }?: SFCParseOptions): SFCParseResult;

declare type PreprocessLang = 'less' | 'sass' | 'scss' | 'styl' | 'stylus';

/**
 * Utility for rewriting `export default` in a script block into a variable
 * declaration so that we can inject things into it
 */
export declare function rewriteDefault(input: string, as: string, parserPlugins?: ParserPlugin[]): string;

export declare interface SFCAsyncStyleCompileOptions extends SFCStyleCompileOptions {
    isAsync?: boolean;
    modules?: boolean;
    modulesOptions?: CSSModulesOptions;
}

export declare interface SFCBlock {
    type: string;
    content: string;
    attrs: Record<string, string | true>;
    loc: SourceLocation;
    map?: RawSourceMap;
    lang?: string;
    src?: string;
}

export declare interface SFCDescriptor {
    filename: string;
    source: string;
    template: SFCTemplateBlock | null;
    script: SFCScriptBlock | null;
    scriptSetup: SFCScriptBlock | null;
    styles: SFCStyleBlock[];
    customBlocks: SFCBlock[];
    cssVars: string[];
    /**
     * whether the SFC uses :slotted() modifier.
     * this is used as a compiler optimization hint.
     */
    slotted: boolean;
    /**
     * compare with an existing descriptor to determine whether HMR should perform
     * a reload vs. re-render.
     *
     * Note: this comparison assumes the prev/next script are already identical,
     * and only checks the special case where <script setup lang="ts"> unused import
     * pruning result changes due to template changes.
     */
    shouldForceReload: (prevImports: Record<string, ImportBinding>) => boolean;
}

export declare interface SFCParseOptions {
    filename?: string;
    sourceMap?: boolean;
    sourceRoot?: string;
    pad?: boolean | 'line' | 'space';
    ignoreEmpty?: boolean;
    compiler?: TemplateCompiler;
}

export declare interface SFCParseResult {
    descriptor: SFCDescriptor;
    errors: (CompilerError | SyntaxError)[];
}

export declare interface SFCScriptBlock extends SFCBlock {
    type: 'script';
    setup?: string | boolean;
    bindings?: BindingMetadata;
    imports?: Record<string, ImportBinding>;
    /**
     * import('\@babel/types').Statement
     */
    scriptAst?: any[];
    /**
     * import('\@babel/types').Statement
     */
    scriptSetupAst?: any[];
}

export declare interface SFCScriptCompileOptions {
    /**
     * Scope ID for prefixing injected CSS variables.
     * This must be consistent with the `id` passed to `compileStyle`.
     */
    id: string;
    /**
     * Production mode. Used to determine whether to generate hashed CSS variables
     */
    isProd?: boolean;
    /**
     * Enable/disable source map. Defaults to true.
     */
    sourceMap?: boolean;
    /**
     * https://babeljs.io/docs/en/babel-parser#plugins
     */
    babelParserPlugins?: ParserPlugin[];
    /**
     * (Experimental) Enable syntax transform for using refs without `.value` and
     * using destructured props with reactivity
     */
    reactivityTransform?: boolean;
    /**
     * (Experimental) Enable syntax transform for using refs without `.value`
     * https://github.com/vuejs/rfcs/discussions/369
     * @deprecated now part of `reactivityTransform`
     * @default false
     */
    refTransform?: boolean;
    /**
     * (Experimental) Enable syntax transform for destructuring from defineProps()
     * https://github.com/vuejs/rfcs/discussions/394
     * @deprecated now part of `reactivityTransform`
     * @default false
     */
    propsDestructureTransform?: boolean;
    /**
     * @deprecated use `reactivityTransform` instead.
     */
    refSugar?: boolean;
    /**
     * Compile the template and inline the resulting render function
     * directly inside setup().
     * - Only affects `<script setup>`
     * - This should only be used in production because it prevents the template
     * from being hot-reloaded separately from component state.
     */
    inlineTemplate?: boolean;
    /**
     * Options for template compilation when inlining. Note these are options that
     * would normally be passed to `compiler-sfc`'s own `compileTemplate()`, not
     * options passed to `compiler-dom`.
     */
    templateOptions?: Partial<SFCTemplateCompileOptions>;
}

export declare interface SFCStyleBlock extends SFCBlock {
    type: 'style';
    scoped?: boolean;
    module?: string | boolean;
}

export declare interface SFCStyleCompileOptions {
    source: string;
    filename: string;
    id: string;
    scoped?: boolean;
    trim?: boolean;
    isProd?: boolean;
    inMap?: RawSourceMap;
    preprocessLang?: PreprocessLang;
    preprocessOptions?: any;
    preprocessCustomRequire?: (id: string) => any;
    postcssOptions?: any;
    postcssPlugins?: any[];
    /**
     * @deprecated use `inMap` instead.
     */
    map?: RawSourceMap;
}

export declare interface SFCStyleCompileResults {
    code: string;
    map: RawSourceMap | undefined;
    rawResult: Result | LazyResult | undefined;
    errors: Error[];
    modules?: Record<string, string>;
    dependencies: Set<string>;
}

export declare interface SFCTemplateBlock extends SFCBlock {
    type: 'template';
    ast: ElementNode;
}

export declare interface SFCTemplateCompileOptions {
    source: string;
    filename: string;
    id: string;
    scoped?: boolean;
    slotted?: boolean;
    isProd?: boolean;
    ssr?: boolean;
    ssrCssVars?: string[];
    inMap?: RawSourceMap;
    compiler?: TemplateCompiler;
    compilerOptions?: CompilerOptions;
    preprocessLang?: string;
    preprocessOptions?: any;
    /**
     * In some cases, compiler-sfc may not be inside the project root (e.g. when
     * linked or globally installed). In such cases a custom `require` can be
     * passed to correctly resolve the preprocessors.
     */
    preprocessCustomRequire?: (id: string) => any;
    /**
     * Configure what tags/attributes to transform into asset url imports,
     * or disable the transform altogether with `false`.
     */
    transformAssetUrls?: AssetURLOptions | AssetURLTagConfig | boolean;
}

export declare interface SFCTemplateCompileResults {
    code: string;
    ast?: RootNode;
    preamble?: string;
    source: string;
    tips: string[];
    errors: (string | CompilerError)[];
    map?: RawSourceMap;
}

export { shouldTransformRef }

export declare interface TemplateCompiler {
    compile(template: string, options: CompilerOptions): CodegenResult;
    parse(template: string, options: ParserOptions): RootNode;
}

export { transformRef }

export { transformRefAST }

export declare const walk: any;

export { walkIdentifiers }

export { }
