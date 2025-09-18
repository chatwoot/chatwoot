import { FormKitClasses, FormKitNode } from '@formkit/core';

/**
 * This package contains the official themes for FormKit. Read the
 * {@link https://formkit.com/getting-started/installation |
 * installation documentation} for more information.
 *
 * @packageDocumentation
 */

/**
 * A function that returns an icon SVG string.
 * @public
 */
interface FormKitIconLoader {
    (iconName: string): string | undefined | Promise<string | undefined>;
}
/**
 * A function that returns a remote URL for retrieving an SVG icon by name.
 * @public
 */
interface FormKitIconLoaderUrl {
    (iconName: string): string | undefined;
}
/**
 * A function to generate FormKit class functions from a JavaScript object.
 * @param classes - An object of input types with nested objects of sectionKeys and class lists.
 * @returns An object of sectionKeys with class functions.
 * @public
 */
declare function generateClasses(classes: Record<string, Record<string, string>>): Record<string, string | FormKitClasses | Record<string, boolean>>;
/**
 * The FormKit icon Registry - a global record of loaded icons.
 * @public
 */
declare const iconRegistry: Record<string, string | undefined>;
/**
 * Creates the theme plugin based on a given theme name.
 * @param theme - The name or id of the theme to apply.
 * @param icons - Icons you want to add to the global icon registry.
 * @param iconLoaderUrl - A function that returns a remote url for retrieving an
 * SVG icon by name.
 * @param iconLoader - A function that handles loading an icon when it is not
 * found in the registry.
 * @public
 */
declare function createThemePlugin(theme?: string, icons?: Record<string, string | undefined>, iconLoaderUrl?: FormKitIconLoaderUrl, iconLoader?: FormKitIconLoader): (node: FormKitNode) => any;
/**
 * Returns a function responsible for loading an icon by name.
 * @param iconLoader - a function for loading an icon when it's not found in the
 * iconRegistry.
 * @param iconLoaderUrl - a function that returns a remote URL for retrieving an
 * SVG icon by name.
 * @public
 */
declare function createIconHandler(iconLoader?: FormKitIconLoader, iconLoaderUrl?: FormKitIconLoaderUrl): FormKitIconLoader;

export { type FormKitIconLoader, type FormKitIconLoaderUrl, createIconHandler, createThemePlugin, generateClasses, iconRegistry };
