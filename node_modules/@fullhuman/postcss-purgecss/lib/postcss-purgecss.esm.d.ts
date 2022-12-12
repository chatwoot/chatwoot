import postcss from "postcss";
interface RawContent<T = string> {
    extension: string;
    raw: T;
}
interface RawCSS {
    raw: string;
}
type ExtractorFunction<T = string> = (content: T) => string[];
interface Extractors {
    extensions: string[];
    extractor: ExtractorFunction;
}
interface UserDefinedOptions {
    content?: Array<string | RawContent>;
    contentFunction?: (sourceFile: string) => Array<string | RawContent>;
    css: Array<string | RawCSS>;
    defaultExtractor?: ExtractorFunction;
    extractors?: Array<Extractors>;
    fontFace?: boolean;
    keyframes?: boolean;
    output?: string;
    rejected?: boolean;
    stdin?: boolean;
    stdout?: boolean;
    variables?: boolean;
    whitelist?: string[];
    whitelistPatterns?: Array<RegExp>;
    whitelistPatternsChildren?: Array<RegExp>;
}
declare const purgeCSSPlugin: postcss.Plugin<Pick<UserDefinedOptions, "keyframes" | "content" | "extractors" | "contentFunction" | "defaultExtractor" | "fontFace" | "output" | "rejected" | "stdin" | "stdout" | "variables" | "whitelist" | "whitelistPatterns" | "whitelistPatternsChildren">>;
export { purgeCSSPlugin as default };
