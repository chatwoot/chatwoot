import type { AllowedComponentProps } from 'vue';
import type { ComponentCustomProps } from 'vue';
import type { ComponentOptionsMixin } from 'vue';
import type { DefineComponent } from 'vue';
import type { EmitsOptions } from 'vue';
import { ExtractPropTypes } from 'vue';
import type { VNodeProps } from 'vue';

/**
 * Add collection to storage, allowing to call icons by name
 *
 * @param data Icon set
 * @param prefix Optional prefix to add to icon names, true (default) if prefix from icon set should be used.
 */
export declare function addCollection(data: IconifyJSON, prefix?: string | boolean): void;

/**
 * Add icon to storage, allowing to call it by name
 *
 * @param name
 * @param data
 */
export declare function addIcon(name: string, data: IconifyIcon): void;

/**
 * Icon with optional parameters that are provided by API and affect only search
 */
declare interface APIIconAttributes {
    	// True if icon is hidden.
    	// Used in icon sets to keep icons that no longer exist, but should still be accessible
    	// from API, preventing websites from breaking when icon is removed by developer.
    	hidden?: boolean;
}

declare interface ExtendedIconifyAlias extends IconifyAlias, APIIconAttributes {}

declare interface ExtendedIconifyIcon extends IconifyIcon, APIIconAttributes {}

/**
 * Component
 */
export declare const Icon: DefineComponent<{}, {}, {}, {}, {}, ComponentOptionsMixin, ComponentOptionsMixin, EmitsOptions, string, VNodeProps & AllowedComponentProps & ComponentCustomProps, Readonly<ExtractPropTypes<    {}>>, {}>;

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
 * Icon customisations
 */
export declare type IconifyIconCustomisations = IconifyIconCustomisations_2 & {
    rotate?: string | number;
};

/**
 * Icon customisations
 */
declare interface IconifyIconCustomisations_2 {
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
 * Callback for when icon has been loaded (only triggered for icons loaded from API)
 */
declare type IconifyIconOnLoad = (name: string) => void;

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

export { }
