/**
 * Given a child DOM element, returns a query-selector statement describing that
 * and its ancestors
 * e.g. [HTMLElement] => body > div > input#foo.btn[name=baz]
 * @returns generated DOM path
 */
export declare function htmlTreeAsString(elem: unknown, keyAttrs?: string[]): string;
/**
 * A safe form of location.href
 */
export declare function getLocationHref(): string;
//# sourceMappingURL=browser.d.ts.map