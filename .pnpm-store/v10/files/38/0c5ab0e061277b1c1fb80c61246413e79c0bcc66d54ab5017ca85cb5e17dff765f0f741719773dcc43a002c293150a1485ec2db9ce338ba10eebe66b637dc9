import type { AllowedComponentProps } from 'vue';
import type { ComponentCustomProps } from 'vue';
import type { ComponentOptionsMixin } from 'vue';
import type { DefineComponent } from 'vue';
import type { EmitsOptions } from 'vue';
import { ExtractPropTypes } from 'vue';
import type { VNodeProps } from 'vue';

/**
 * Add custom config for provider
 */
export declare function addAPIProvider(provider: string, customConfig: PartialIconifyAPIConfig): boolean;

/**
 * Add icon set
 */
export declare function addCollection(data: IconifyJSON, provider?: string): boolean;

/**
 * Add one icon
 */
export declare function addIcon(name: string, data: IconifyIcon): boolean;

/**
 * Internal API
 */
export declare const _api: IconifyAPIInternalFunctions;

/**
 * Icon with optional parameters that are provided by API and affect only search
 */
declare interface APIIconAttributes {
    	// True if icon is hidden.
    	// Used in icon sets to keep icons that no longer exist, but should still be accessible
    	// from API, preventing websites from breaking when icon is removed by developer.
    	hidden?: boolean;
}

/**
 * API query parameters
 */
declare type APIQueryParamValue = number | string | boolean | undefined;

/**
 * Build icon
 */
export declare function buildIcon(icon: IconifyIcon, customisations?: RawIconCustomisations): IconifyIconBuildResult;

/**
 * Calculate second dimension when only 1 dimension is set
 */
export declare function calculateSize(size: string | number, ratio: number, precision?: number): string | number;

/**
 * Disable cache
 */
export declare function disableCache(storage: IconifyBrowserCacheType): void;

/**
 * Enable cache
 */
export declare function enableCache(storage: IconifyBrowserCacheType): void;

declare interface ExtendedIconifyAlias extends IconifyAlias, APIIconAttributes {}

declare interface ExtendedIconifyIcon extends IconifyIcon, APIIconAttributes {}

/**
 * Signature for getAPIConfig
 */
export declare type GetAPIConfig = (provider: string) => IconifyAPIConfig | undefined;

/**
 * Get icon
 */
export declare function getIcon(name: string): Required<IconifyIcon> | null;

export declare const Icon: DefineComponent<{}, {}, {
    iconMounted: boolean;
    counter: number;
}, {}, {
    abortLoading(): void;
    getIcon(icon: IconifyIcon | string, onload?: IconifyIconOnLoad): IconComponentData | null;
}, ComponentOptionsMixin, ComponentOptionsMixin, EmitsOptions, string, VNodeProps & AllowedComponentProps & ComponentCustomProps, Readonly<ExtractPropTypes<    {}>>, {}>;

/**
 * Component
 */
declare interface IconComponentData {
    data: Required<IconifyIcon>;
    classes?: string[];
}

/**
 * Check if icon exists
 */
export declare function iconExists(name: string): boolean;

/**
 * Alias.
 */
declare interface IconifyAlias extends IconifyOptional {
    	// Parent icon index without prefix, required.
    	parent: string;

    	// IconifyOptional properties.
    	// Alias should have only properties that it overrides.
    	// Transformations are merged, not overridden. See IconifyTransformations comments.
}

/**
 * "aliases" field of JSON file.
 */
declare interface IconifyAliases {
    	// Index is name of icon, without prefix. Value is ExtendedIconifyAlias object.
    	[index: string]: ExtendedIconifyAlias;
}

/**
 * API config
 */
export declare interface IconifyAPIConfig extends RedundancyConfig {
    path: string;
    maxURL: number;
}

export declare interface IconifyAPICustomQueryParams {
    type: 'custom';
    provider?: string;
    uri: string;
}

/**
 * Iconify API functions
 */
export declare interface IconifyAPIFunctions {
    /**
     * Load icons
     */
    loadIcons: (icons: (IconifyIconName | string)[], callback?: IconifyIconLoaderCallback) => IconifyIconLoaderAbort;
    /**
     * Load one icon, using Promise syntax
     */
    loadIcon: (icon: IconifyIconName | string) => Promise<Required<IconifyIcon>>;
    /**
     * Add API provider
     */
    addAPIProvider: (provider: string, customConfig: PartialIconifyAPIConfig) => boolean;
}

/**
 * Params for sendQuery()
 */
declare interface IconifyAPIIconsQueryParams {
    type: 'icons';
    provider: string;
    prefix: string;
    icons: string[];
}

/**
 * Exposed internal functions
 *
 * Used by plug-ins, such as Icon Finder
 *
 * Important: any changes published in a release must be backwards compatible.
 */
export declare interface IconifyAPIInternalFunctions {
    /**
     * Get API config, used by custom modules
     */
    getAPIConfig: GetAPIConfig;
    /**
     * Set custom API module
     */
    setAPIModule: (provider: string, item: IconifyAPIModule) => void;
    /**
     * Send API query
     */
    sendAPIQuery: (target: string | PartialIconifyAPIConfig, query: IconifyAPIQueryParams, callback: QueryDoneCallback) => QueryAbortCallback;
    /**
     * Set and get fetch()
     */
    setFetch: (item: typeof fetch) => void;
    getFetch: () => typeof fetch | null;
    /**
     * List all API providers (from config)
     */
    listAPIProviders: () => string[];
    /**
     * Merge parameters
     */
    mergeParams: MergeParams;
}

export declare type IconifyAPIMergeQueryParams = Record<string, APIQueryParamValue>;

/**
 * API modules
 */
export declare interface IconifyAPIModule {
    prepare: IconifyAPIPrepareIconsQuery;
    send: IconifyAPISendQuery;
}

/**
 * Functions to implement in module
 */
export declare type IconifyAPIPrepareIconsQuery = (provider: string, prefix: string, icons: string[]) => IconifyAPIIconsQueryParams[];

export declare type IconifyAPIQueryParams = IconifyAPIIconsQueryParams | IconifyAPICustomQueryParams;

export declare type IconifyAPISendQuery = (host: string, params: IconifyAPIQueryParams, callback: QueryModuleResponse) => void;

/**
 * Interface for exported functions
 */
export declare interface IconifyBrowserCacheFunctions {
    enableCache: (storage: IconifyBrowserCacheType) => void;
    disableCache: (storage: IconifyBrowserCacheType) => void;
}

/**
 * Cache types
 */
export declare type IconifyBrowserCacheType = 'local' | 'session' | 'all';

/**
 * Interface for exported builder functions
 */
export declare interface IconifyBuilderFunctions {
    replaceIDs: (body: string, prefix?: string | (() => string)) => string;
    calculateSize: (size: string | number, ratio: number, precision?: number) => string | number;
    buildIcon: (icon: IconifyIcon, customisations?: RawIconCustomisations) => IconifyIconBuildResult;
}

/**
 * Icon categories
 */
declare interface IconifyCategories {
    	// Index is category title, such as "Weather".
    	// Value is array of icons that belong to that category.
    	// Each icon can belong to multiple categories or no categories.
    	[index: string]: string[];
}

/**
 * Characters used in font.
 */
declare interface IconifyChars {
    	// Index is character, such as "f000".
    	// Value is icon name.
    	[index: string]: string;
}

/**
 * Icon dimensions.
 *
 * Used in:
 *  icon (as is)
 *  alias (overwrite icon's properties)
 *  root of JSON file (default values)
 */
declare interface IconifyDimenisons {
    	// Left position of viewBox.
    	// Defaults to 0.
    	left?: number;

    	// Top position of viewBox.
    	// Defaults to 0.
    	top?: number;

    	// Width of viewBox.
    	// Defaults to 16.
    	width?: number;

    	// Height of viewBox.
    	// Defaults to 16.
    	height?: number;
}

/**
 * Properties for element that are mentioned in render.ts
 */
declare interface IconifyElementProps {
    id?: string;
    style?: unknown;
    onLoad?: IconifyIconOnLoad;
}

/**
 * Icon alignment
 */
export declare type IconifyHorizontalIconAlignment = 'left' | 'center' | 'right';

/**
 * Icon.
 */
export declare interface IconifyIcon extends IconifyOptional {
    	// Icon body: <path d="..." />, required.
    	body: string;

    	// IconifyOptional properties.
    	// If property is missing in JSON file, look in root object for default value.
}

/**
 * Interface for getSVGData() result
 */
export declare interface IconifyIconBuildResult {
    attributes: {
        width: string;
        height: string;
        preserveAspectRatio: string;
        viewBox: string;
    };
    body: string;
    inline?: boolean;
}

/**
 * Icon customisations
 */
export declare type IconifyIconCustomisations = RawIconCustomisations & {
    rotate?: string | number;
};

/**
 * Function to abort loading (usually just removes callback because loading is already in progress)
 */
export declare type IconifyIconLoaderAbort = () => void;

/**
 * Loader callback
 *
 * Provides list of icons that have been loaded
 */
export declare type IconifyIconLoaderCallback = (loaded: IconifyIconName[], missing: IconifyIconName[], pending: IconifyIconName[], unsubscribe: IconifyIconLoaderAbort) => void;

/**
 * Icon name
 */
export declare interface IconifyIconName {
    readonly provider: string;
    readonly prefix: string;
    readonly name: string;
}

/**
 * Callback for when icon has been loaded (only triggered for icons loaded from API)
 */
export declare type IconifyIconOnLoad = (name: string) => void;

/**
 * Icon properties
 */
export declare interface IconifyIconProps extends IconifyIconCustomisations {
    icon: IconifyIcon | string;
    color?: string;
    flip?: string;
    align?: string;
}

/**
 * "icons" field of JSON file.
 */
declare interface IconifyIcons {
    	// Index is name of icon, without prefix. Value is ExtendedIconifyIcon object.
    	[index: string]: ExtendedIconifyIcon;
}

/**
 * Icon size
 */
export declare type IconifyIconSize = null | string | number;

/**
 * Icon set information block.
 */
declare interface IconifyInfo {
    	// Icon set name.
    	name: string;

    	// Total number of icons.
    	total?: number;

    	// Version string.
    	version?: string;

    	// Author information.
    	author: {
        		// Author name.
        		name: string;

        		// Link to author's website or icon set website.
        		url?: string;
        	};

    	// License
    	license: {
        		// Human readable license.
        		title: string;

        		// SPDX license identifier.
        		spdx?: string;

        		// License URL.
        		url?: string;
        	};

    	// Array of icons that should be used for samples in icon sets list.
    	samples?: string[];

    	// Icon grid: number or array of numbers.
    	height?: number | number[];

    	// Display height for samples: 16 - 24
    	displayHeight?: number;

    	// Category on Iconify collections list.
    	category?: string;

    	// Palette status. True if icons have predefined color scheme, false if icons use currentColor.
    	// Ideally, icon set should not mix icons with and without palette to simplify search.
    	palette?: boolean;

    	// If true, icon set should not appear in icon sets list.
    	hidden?: boolean;
}

/**
 * JSON structure.
 *
 * All optional values can exist in root of JSON file, used as defaults.
 */
export declare interface IconifyJSON extends IconifyJSONIconsData, IconifyMetaData {
    	// Optional list of missing icons. Returned by Iconify API when querying for icons that do not exist.
    	not_found?: string[];
}

/**
 * JSON structure, contains only icon data
 */
declare interface IconifyJSONIconsData extends IconifyOptional {
    	// Prefix for icons in JSON file, required.
    	prefix: string;

    	// API provider, optional.
    	provider?: string;

    	// List of icons, required.
    	icons: IconifyIcons;

    	// Optional aliases.
    	aliases?: IconifyAliases;

    	// IconifyOptional properties that are used as default values for icons when icon is missing value.
    	// If property exists in both icon and root, use value from icon.
    	// This is used to reduce duplication.
}

/**
 * Function to load icons
 */
declare type IconifyLoadIcons = (icons: (IconifyIconName | string)[], callback?: IconifyIconLoaderCallback) => IconifyIconLoaderAbort;

/**
 * Meta data stored in JSON file, used for browsing icon set.
 */
declare interface IconifyMetaData {
    	// Icon set information block. Used for public icon sets, can be skipped for private icon sets.
    	info?: IconifyInfo;

    	// Characters used in font. Used for searching by character for icon sets imported from font, exporting icon set to font.
    	chars?: IconifyChars;

    	// Categories. Used for filtering icons.
    	categories?: IconifyCategories;

    	// Optional themes (old format).
    	themes?: LegacyIconifyThemes;

    	// Optional themes (new format). Key is prefix or suffix, value is title.
    	prefixes?: Record<string, string>;
    	suffixes?: Record<string, string>;
}

/**
 * Combination of dimensions and transformations.
 */
declare interface IconifyOptional
	extends IconifyDimenisons,
		IconifyTransformations {
    	//
}

/**
 * Interface for exported storage functions
 */
export declare interface IconifyStorageFunctions {
    /**
     * Check if icon exists
     */
    iconExists: (name: string) => boolean;
    /**
     * Get icon data with all properties
     */
    getIcon: (name: string) => Required<IconifyIcon> | null;
    /**
     * List all available icons
     */
    listIcons: (provider?: string, prefix?: string) => string[];
    /**
     * Add icon to storage
     */
    addIcon: (name: string, data: IconifyIcon) => boolean;
    /**
     * Add icon set to storage
     */
    addCollection: (data: IconifyJSON, provider?: string) => boolean;
    /**
     * Share storage (used to share icon data between various components or multiple instances of component)
     *
     * It works by moving storage to global variable, new instances of component attempt to detect global
     * variable during load. Therefore, function should be called as soon as possible.
     * Works only in browser, not usable in SSR.
     */
    shareStorage: () => void;
}

/**
 * Icon transformations.
 *
 * Used in:
 *  icon (as is)
 *  alias (merged with icon's properties)
 *  root of JSON file (default values)
 */
declare interface IconifyTransformations {
    	// Number of 90 degrees rotations.
    	// 0 = 0, 1 = 90deg and so on.
    	// Defaults to 0.
    	// When merged (such as alias + icon), result is icon.rotation + alias.rotation.
    	rotate?: number;

    	// Horizontal flip.
    	// Defaults to false.
    	// When merged, result is icon.hFlip !== alias.hFlip
    	hFlip?: boolean;

    	// Vertical flip. (see hFlip comments)
    	vFlip?: boolean;
}

export declare type IconifyVerticalIconAlignment = 'top' | 'middle' | 'bottom';

/**
 * Mix of icon properties and HTMLElement properties
 */
export declare type IconProps = IconifyElementProps & IconifyIconProps;

/**
 * Optional themes, old format.
 *
 * Deprecated because format is unnecessary complicated. Key is meaningless, suffixes and prefixes are mixed together.
 */
declare interface LegacyIconifyThemes {
    	// Key is unique string.
    	[index: string]: {
        		// Theme title.
        		title: string;

        		// Icon prefix or suffix, including dash. All icons that start with prefix and end with suffix belong to theme.
        		prefix?: string; // Example: 'baseline-'
        		suffix?: string; // Example: '-filled'
        	};
}

/**
 * List available icons
 */
export declare function listIcons(provider?: string, prefix?: string): string[];

/**
 * Cache for loadIcon promises
 */
export declare const loadIcon: (icon: IconifyIconName | string) => Promise<Required<IconifyIcon>>;

/**
 * Load icons
 */
export declare const loadIcons: IconifyLoadIcons;

/**
 * Type for mergeParams()
 */
declare type MergeParams = (base: string, params: IconifyAPIMergeQueryParams) => string;

export declare type PartialIconifyAPIConfig = Partial<IconifyAPIConfig> & Pick<IconifyAPIConfig, 'resources'>;

/**
 * Callback for "abort" pending item.
 */
declare type QueryAbortCallback = () => void;

/**
 * Callback
 *
 * If error is present, something went wrong and data is undefined. If error is undefined, data is set.
 */
declare type QueryDoneCallback = (data?: QueryModuleResponseData, error?: QueryModuleResponseData) => void;

declare type QueryModuleResponse = (status: QueryModuleResponseType, data: QueryModuleResponseData) => void;

/**
 * Response from query module
 */
declare type QueryModuleResponseData = unknown;

/**
 * Response from query module
 */
declare type QueryModuleResponseType = 'success' | 'next' | 'abort';

/**
 * Icon customisations
 */
export declare interface RawIconCustomisations {
    inline?: boolean;
    width?: IconifyIconSize;
    height?: IconifyIconSize;
    hAlign?: IconifyHorizontalIconAlignment;
    vAlign?: IconifyVerticalIconAlignment;
    slice?: boolean;
    hFlip?: boolean;
    vFlip?: boolean;
    rotate?: number;
}

/**
 * Configuration object
 */
declare interface RedundancyConfig {
    resources: RedundancyResource[];
    index: number;
    timeout: number;
    rotate: number;
    random: boolean;
    dataAfterTimeout: boolean;
}

/**
 * Resource to rotate (usually hostname or partial URL)
 */
declare type RedundancyResource = string;

/**
 * IDs usage:
 *
 * id="{id}"
 * xlink:href="#{id}"
 * url(#{id})
 *
 * From SVG animations:
 *
 * begin="0;{id}.end"
 * begin="{id}.end"
 * begin="{id}.click"
 */
/**
 * Replace IDs in SVG output with unique IDs
 */
export declare function replaceIDs(body: string, prefix?: string | ((id: string) => string)): string;

/**
 * Share storage between components
 */
export declare function shareStorage(): void;

export { }
