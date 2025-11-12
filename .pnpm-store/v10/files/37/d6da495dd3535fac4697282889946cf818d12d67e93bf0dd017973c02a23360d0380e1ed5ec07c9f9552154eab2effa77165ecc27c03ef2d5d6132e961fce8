import type { YAMLAlias, YAMLContent } from "../ast";
export type TagResolver<T> = {
    tag: string;
    testString: (str: string) => boolean;
    resolveString: (str: string) => T;
};
export type TagNodeResolver<T> = {
    tag: string;
    testNode: (node: Exclude<YAMLContent, YAMLAlias>) => boolean;
    resolveNode: (node: Exclude<YAMLContent, YAMLAlias>) => T;
};
