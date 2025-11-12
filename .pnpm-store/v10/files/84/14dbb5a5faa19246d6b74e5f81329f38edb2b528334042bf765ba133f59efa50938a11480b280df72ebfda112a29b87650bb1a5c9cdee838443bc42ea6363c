/**
 * This function detects which browser is running this script.
 * The order of the checks are important since many user agents
 * include keywords used in later checks.
 */
export declare const detectBrowser: (user_agent: string, vendor: string | undefined) => string;
/**
 * This function detects which browser version is running this script,
 * parsing major and minor version (e.g., 42.1). User agent strings from:
 * http://www.useragentstring.com/pages/useragentstring.php
 *
 * `navigator.vendor` is passed in and used to help with detecting certain browsers
 * NB `navigator.vendor` is deprecated and not present in every browser
 */
export declare const detectBrowserVersion: (userAgent: string, vendor: string | undefined) => number | null;
export declare const detectOS: (user_agent: string) => [string, string];
export declare const detectDevice: (user_agent: string) => string;
export declare const detectDeviceType: (user_agent: string) => string;
