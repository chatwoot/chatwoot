import { DirectiveOptions } from 'vue';
import { HookEvent, HookName, SanitizeAttributeHookEvent, SanitizeElementHookEvent } from 'dompurify';
export interface MinimalDOMPurifyConfig {
    ADD_ATTR?: string[] | undefined;
    ADD_DATA_URI_TAGS?: string[] | undefined;
    ADD_TAGS?: string[] | undefined;
    ALLOW_DATA_ATTR?: boolean | undefined;
    ALLOWED_ATTR?: string[] | undefined;
    ALLOWED_TAGS?: string[] | undefined;
    FORBID_ATTR?: string[] | undefined;
    FORBID_CONTENTS?: string[] | undefined;
    FORBID_TAGS?: string[] | undefined;
    ALLOWED_URI_REGEXP?: RegExp | undefined;
    ALLOW_UNKNOWN_PROTOCOLS?: boolean | undefined;
    USE_PROFILES?: false | {
        mathMl?: boolean | undefined;
        svg?: boolean | undefined;
        svgFilters?: boolean | undefined;
        html?: boolean | undefined;
    } | undefined;
    CUSTOM_ELEMENT_HANDLING?: {
        tagNameCheck?: RegExp | ((tagName: string) => boolean) | null | undefined;
        attributeNameCheck?: RegExp | ((lcName: string) => boolean) | null | undefined;
        allowCustomizedBuiltInElements?: boolean | undefined;
    };
}
export interface DirectiveConfig {
    default?: MinimalDOMPurifyConfig | undefined;
    namedConfigurations?: Record<string, MinimalDOMPurifyConfig> | undefined;
    hooks?: {
        uponSanitizeElement?: (currentNode: Element, data: SanitizeElementHookEvent, config: MinimalDOMPurifyConfig) => void;
        uponSanitizeAttribute?: (currentNode: Element, data: SanitizeAttributeHookEvent, config: MinimalDOMPurifyConfig) => void;
    } & {
        [H in HookName]?: (currentNode: Element, data: HookEvent, config: MinimalDOMPurifyConfig) => void;
    };
}
export declare function buildDirective(config?: DirectiveConfig): DirectiveOptions;
