import { Lib } from './lib';
import type { Program } from 'typescript';
declare type DebugLevel = boolean | ('typescript-eslint' | 'eslint' | 'typescript')[];
declare type EcmaVersion = 3 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 2015 | 2016 | 2017 | 2018 | 2019 | 2020 | 2021 | 2022;
declare type SourceType = 'script' | 'module';
interface ParserOptions {
    ecmaFeatures?: {
        globalReturn?: boolean;
        jsx?: boolean;
    };
    ecmaVersion?: EcmaVersion | 'latest';
    jsxPragma?: string | null;
    jsxFragmentName?: string | null;
    lib?: Lib[];
    emitDecoratorMetadata?: boolean;
    comment?: boolean;
    debugLevel?: DebugLevel;
    errorOnTypeScriptSyntacticAndSemanticIssues?: boolean;
    errorOnUnknownASTType?: boolean;
    EXPERIMENTAL_useSourceOfProjectReferenceRedirect?: boolean;
    extraFileExtensions?: string[];
    filePath?: string;
    loc?: boolean;
    program?: Program;
    project?: string | string[];
    projectFolderIgnoreList?: (string | RegExp)[];
    range?: boolean;
    sourceType?: SourceType;
    tokens?: boolean;
    tsconfigRootDir?: string;
    warnOnUnsupportedTypeScriptVersion?: boolean;
    moduleResolver?: string;
}
export { DebugLevel, EcmaVersion, ParserOptions, SourceType };
//# sourceMappingURL=parser-options.d.ts.map