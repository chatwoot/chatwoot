import { IGrammar, IRawTheme } from 'vscode-textmate';

type Theme = 'css-variables' | 'dark-plus' | 'dracula-soft' | 'dracula' | 'github-dark-dimmed' | 'github-dark' | 'github-light' | 'hc_light' | 'light-plus' | 'material-darker' | 'material-default' | 'material-lighter' | 'material-ocean' | 'material-palenight' | 'min-dark' | 'min-light' | 'monokai' | 'nord' | 'one-dark-pro' | 'poimandres' | 'rose-pine-dawn' | 'rose-pine-moon' | 'rose-pine' | 'slack-dark' | 'slack-ochin' | 'solarized-dark' | 'solarized-light' | 'vitesse-dark' | 'vitesse-light';
declare const themes: Theme[];

declare enum FontStyle {
    NotSet = -1,
    None = 0,
    Italic = 1,
    Bold = 2,
    Underline = 4
}

interface IThemedTokenScopeExplanation {
    scopeName: string;
    themeMatches: any[];
}
interface IThemedTokenExplanation {
    content: string;
    scopes: IThemedTokenScopeExplanation[];
}
/**
 * A single token with color, and optionally with explanation.
 *
 * For example:
 *
 * {
 *   "content": "shiki",
 *   "color": "#D8DEE9",
 *   "explanation": [
 *     {
 *       "content": "shiki",
 *       "scopes": [
 *         {
 *           "scopeName": "source.js",
 *           "themeMatches": []
 *         },
 *         {
 *           "scopeName": "meta.objectliteral.js",
 *           "themeMatches": []
 *         },
 *         {
 *           "scopeName": "meta.object.member.js",
 *           "themeMatches": []
 *         },
 *         {
 *           "scopeName": "meta.array.literal.js",
 *           "themeMatches": []
 *         },
 *         {
 *           "scopeName": "variable.other.object.js",
 *           "themeMatches": [
 *             {
 *               "name": "Variable",
 *               "scope": "variable.other",
 *               "settings": {
 *                 "foreground": "#D8DEE9"
 *               }
 *             },
 *             {
 *               "name": "[JavaScript] Variable Other Object",
 *               "scope": "source.js variable.other.object",
 *               "settings": {
 *                 "foreground": "#D8DEE9"
 *               }
 *             }
 *           ]
 *         }
 *       ]
 *     }
 *   ]
 * }
 *
 */
interface IThemedToken {
    /**
     * The content of the token
     */
    content: string;
    /**
     * 6 or 8 digit hex code representation of the token's color
     */
    color?: string;
    /**
     * Font style of token. Can be None/Italic/Bold/Underline
     */
    fontStyle?: FontStyle;
    /**
     * Explanation of
     *
     * - token text's matching scopes
     * - reason that token text is given a color (one matching scope matches a rule (scope -> color) in the theme)
     */
    explanation?: IThemedTokenExplanation[];
}

interface HighlighterOptions {
    /**
     * The theme to load upfront.
     */
    theme?: IThemeRegistration;
    /**
     * A list of themes to load upfront.
     *
     * Default to: `['dark-plus', 'light-plus']`
     */
    themes?: IThemeRegistration[];
    /**
     * A list of languages to load upfront.
     *
     * Default to all the bundled languages.
     */
    langs?: (Lang | ILanguageRegistration)[];
    /**
     * Paths for loading themes and langs. Relative to the package's root.
     */
    paths?: IHighlighterPaths;
}
interface Highlighter {
    /**
     * Convert code to HTML tokens.
     * `lang` and `theme` must have been loaded.
     * @deprecated Please use the `codeToHtml(code, options?)` overload instead.
     */
    codeToHtml(code: string, lang?: StringLiteralUnion<Lang>, theme?: StringLiteralUnion<Theme>, options?: HtmlOptions): string;
    /**
     * Convert code to HTML tokens.
     * `lang` and `theme` must have been loaded.
     */
    codeToHtml(code: string, options?: HtmlOptions): string;
    /**
     * Convert code to themed tokens for custom processing.
     * `lang` and `theme` must have been loaded.
     * You may customize the bundled HTML / SVG renderer or write your own
     * renderer for another render target.
     */
    codeToThemedTokens(code: string, lang?: StringLiteralUnion<Lang>, theme?: StringLiteralUnion<Theme>, options?: ThemedTokenizerOptions): IThemedToken[][];
    /**
     * Get the loaded theme
     */
    getTheme(theme?: IThemeRegistration): IShikiTheme;
    /**
     * Load a theme
     */
    loadTheme(theme: IThemeRegistration): Promise<void>;
    /**
     * Load a language
     */
    loadLanguage(lang: ILanguageRegistration | Lang): Promise<void>;
    /**
     * Get all loaded themes
     */
    getLoadedThemes(): Theme[];
    /**
     * Get all loaded languages
     */
    getLoadedLanguages(): Lang[];
    /**
     * Get the foreground color for theme. Can be used for CSS `color`.
     */
    getForegroundColor(theme?: StringLiteralUnion<Theme>): string;
    /**
     * Get the background color for theme. Can be used for CSS `background-color`.
     */
    getBackgroundColor(theme?: StringLiteralUnion<Theme>): string;
    setColorReplacements(map: Record<string, string>): void;
}
interface IHighlighterPaths {
    /**
     * @default 'themes/'
     */
    themes?: string;
    /**
     * @default 'languages/'
     */
    languages?: string;
    /**
     * @default 'dist/'
     */
    wasm?: string;
}
type ILanguageRegistration = {
    id: string;
    scopeName: string;
    aliases?: string[];
    samplePath?: string;
    /**
     * A list of languages the current language embeds.
     * If manually specifying languages to load, make sure to load the embedded
     * languages for each parent language.
     */
    embeddedLangs?: Lang[];
    balancedBracketSelectors?: string[];
    unbalancedBracketSelectors?: string[];
} & {
    path: string;
    grammar?: IGrammar;
};
type IThemeRegistration = IShikiTheme | StringLiteralUnion<Theme>;
interface IShikiTheme extends IRawTheme {
    /**
     * @description theme name
     */
    name: string;
    /**
     * @description light/dark theme
     */
    type: 'light' | 'dark' | 'css';
    /**
     * @description tokenColors of the theme file
     */
    settings: any[];
    /**
     * @description text default foreground color
     */
    fg: string;
    /**
     * @description text default background color
     */
    bg: string;
    /**
     * @description relative path of included theme
     */
    include?: string;
    /**
     *
     * @description color map of the theme file
     */
    colors?: Record<string, string>;
}
/**
 * type StringLiteralUnion<'foo'> = 'foo' | string
 * This has auto completion whereas `'foo' | string` doesn't
 * Adapted from https://github.com/microsoft/TypeScript/issues/29729
 */
type StringLiteralUnion<T extends U, U = string> = T | (U & {});
interface HtmlOptions {
    lang?: StringLiteralUnion<Lang>;
    theme?: StringLiteralUnion<Theme>;
    lineOptions?: LineOption[];
}
interface HtmlRendererOptions {
    langId?: string;
    fg?: string;
    bg?: string;
    lineOptions?: LineOption[];
    elements?: ElementsOptions;
    themeName?: string;
}
interface LineOption {
    /**
     * 1-based line number.
     */
    line: number;
    classes?: string[];
}
interface ElementProps {
    children: string;
    [key: string]: unknown;
}
interface PreElementProps extends ElementProps {
    className: string;
    style: string;
}
interface CodeElementProps extends ElementProps {
}
interface LineElementProps extends ElementProps {
    className: string;
    lines: IThemedToken[][];
    line: IThemedToken[];
    index: number;
}
interface TokenElementProps extends ElementProps {
    style: string;
    tokens: IThemedToken[];
    token: IThemedToken;
    index: number;
}
interface ElementsOptions {
    pre?: (props: PreElementProps) => string;
    code?: (props: CodeElementProps) => string;
    line?: (props: LineElementProps) => string;
    token?: (props: TokenElementProps) => string;
}
interface ThemedTokenizerOptions {
    /**
     * Whether to include explanation of each token's matching scopes and
     * why it's given its color. Default to false to reduce output verbosity.
     */
    includeExplanation?: boolean;
}

type Lang = 'abap' | 'actionscript-3' | 'ada' | 'apache' | 'apex' | 'apl' | 'applescript' | 'asm' | 'astro' | 'awk' | 'ballerina' | 'bat' | 'batch' | 'berry' | 'be' | 'bibtex' | 'bicep' | 'blade' | 'c' | 'cadence' | 'cdc' | 'clarity' | 'clojure' | 'clj' | 'cmake' | 'cobol' | 'codeql' | 'ql' | 'coffee' | 'cpp' | 'crystal' | 'csharp' | 'c#' | 'cs' | 'css' | 'cue' | 'd' | 'dart' | 'diff' | 'docker' | 'dream-maker' | 'elixir' | 'elm' | 'erb' | 'erlang' | 'erl' | 'fish' | 'fsharp' | 'f#' | 'fs' | 'gherkin' | 'git-commit' | 'git-rebase' | 'glsl' | 'gnuplot' | 'go' | 'graphql' | 'groovy' | 'hack' | 'haml' | 'handlebars' | 'hbs' | 'haskell' | 'hs' | 'hcl' | 'hlsl' | 'html' | 'imba' | 'ini' | 'java' | 'javascript' | 'js' | 'jinja-html' | 'json' | 'json5' | 'jsonc' | 'jsonnet' | 'jssm' | 'fsl' | 'jsx' | 'julia' | 'kotlin' | 'latex' | 'less' | 'liquid' | 'lisp' | 'logo' | 'lua' | 'make' | 'makefile' | 'markdown' | 'md' | 'marko' | 'matlab' | 'mdx' | 'mermaid' | 'nginx' | 'nim' | 'nix' | 'objective-c' | 'objc' | 'objective-cpp' | 'ocaml' | 'pascal' | 'perl' | 'php' | 'plsql' | 'postcss' | 'powershell' | 'ps' | 'ps1' | 'prisma' | 'prolog' | 'proto' | 'pug' | 'jade' | 'puppet' | 'purescript' | 'python' | 'py' | 'r' | 'raku' | 'perl6' | 'razor' | 'rel' | 'riscv' | 'rst' | 'ruby' | 'rb' | 'rust' | 'rs' | 'sas' | 'sass' | 'scala' | 'scheme' | 'scss' | 'shaderlab' | 'shader' | 'shellscript' | 'shell' | 'bash' | 'sh' | 'zsh' | 'smalltalk' | 'solidity' | 'sparql' | 'sql' | 'ssh-config' | 'stata' | 'stylus' | 'styl' | 'svelte' | 'swift' | 'system-verilog' | 'tasl' | 'tcl' | 'tex' | 'toml' | 'tsx' | 'turtle' | 'twig' | 'typescript' | 'ts' | 'v' | 'vb' | 'cmd' | 'verilog' | 'vhdl' | 'viml' | 'vim' | 'vimscript' | 'vue-html' | 'vue' | 'wasm' | 'wenyan' | '文言' | 'xml' | 'xsl' | 'yaml' | 'zenscript';
declare const languages: ILanguageRegistration[];

declare function getHighlighter(options: HighlighterOptions): Promise<Highlighter>;

declare function renderToHtml(lines: IThemedToken[][], options?: HtmlRendererOptions): string;

/**
 * Set the route for loading the assets
 * URL should end with `/`
 *
 * For example:
 * ```ts
 * setCDN('https://unpkg.com/shiki/') // use unpkg
 * setCDN('/assets/shiki/') // serve by yourself
 * ```
 */
declare function setCDN(root: string): void;
/**
 * Explicitly set the source for loading the oniguruma web assembly module.
 *  *
 * Accepts ArrayBuffer or Response (usage of string is deprecated)
 */
declare function setWasm(data: string | ArrayBuffer | Response): void;
/**
 * @param themePath related path to theme.json
 */
declare function fetchTheme(themePath: string): Promise<IShikiTheme>;
declare function toShikiTheme(rawTheme: IRawTheme): IShikiTheme;

/** @deprecated use setWasm instead, will be removed in a future version */
declare function setOnigasmWASM(path: string | ArrayBuffer): void;

export { languages as BUNDLED_LANGUAGES, themes as BUNDLED_THEMES, FontStyle, Highlighter, HighlighterOptions, HtmlRendererOptions, ILanguageRegistration, IShikiTheme, IThemeRegistration, IThemedToken, Lang, Theme, getHighlighter, fetchTheme as loadTheme, renderToHtml, setCDN, setOnigasmWASM, setWasm, toShikiTheme };
