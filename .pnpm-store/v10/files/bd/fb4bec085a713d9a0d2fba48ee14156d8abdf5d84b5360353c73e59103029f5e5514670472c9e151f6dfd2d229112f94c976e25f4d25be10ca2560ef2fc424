/**
 * IE11 doesn't support `new URL`
 * so we can create an anchor element and use that to parse the URL
 * there's a lot of overlap between HTMLHyperlinkElementUtils and URL
 * meaning useful properties like `pathname` are available on both
 */
export declare const convertToURL: (url: string) => HTMLAnchorElement | null;
export declare const formDataToQuery: (formdata: Record<string, any> | FormData, arg_separator?: string) => string;
export declare const getQueryParam: (url: string, param: string) => string;
export declare const maskQueryParams: <T extends string | undefined>(url: T, maskedParams: string[] | undefined, mask: string) => T extends string ? string : undefined;
export declare const _getHashParam: (hash: string, param: string) => string | null;
export declare const isLocalhost: () => boolean;
