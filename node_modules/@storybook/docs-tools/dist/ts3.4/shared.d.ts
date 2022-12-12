export declare const ADDON_ID = "storybook/docs";
export declare const PANEL_ID: string;
export declare const PARAM_KEY = "docs";
export declare const SNIPPET_RENDERED: string;
export declare enum SourceType {
    /**
     * AUTO is the default
     *
     * Use the CODE logic if:
     * - the user has set a custom source snippet in `docs.source.code` story parameter
     * - the story is not an args-based story
     *
     * Use the DYNAMIC rendered snippet if the story is an args story
     */
    AUTO = "auto",
    /**
     * Render the code extracted by source-loader
     */
    CODE = "code",
    /**
     * Render dynamically-rendered source snippet from the story's virtual DOM (currently React only)
     */
    DYNAMIC = "dynamic"
}
