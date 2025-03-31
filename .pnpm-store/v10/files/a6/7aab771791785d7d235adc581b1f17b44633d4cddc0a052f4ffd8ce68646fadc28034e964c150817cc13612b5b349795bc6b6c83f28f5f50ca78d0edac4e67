export interface SanitizerOptions {
    /**
     * Wrapper element id.
     */
    id?: string;
    /**
     * Removes all HTML tags from the contents.
     */
    dropAllHtmlTags?: boolean;
    /**
     * Replaces CSS url() and src= attribute values with return values of this function.
     */
    rewriteExternalResources?: (url: string) => string;
    /**
     * Replaces href= attribute values with return values of this function.
     */
    rewriteExternalLinks?: (url: string) => string;
    /**
     * Allowed schemas, default: ['http', 'https', 'mailto'].
     * Does not apply if rewriteExternalResources and/or rewriteExternalLinks are enabled.
     */
    allowedSchemas?: string[];
    /**
     * Allowed css properties, default @see `allowedCssProperties`
     */
    allowedCssProperties?: string[];
    /**
     * Remove wrapper <div> from the output, default: false.
     */
    noWrapper?: boolean;
    /**
     * Preserves CSS priority (!important), default: true.
     */
    preserveCssPriority?: boolean;
}
export declare function sanitize(html: string, text?: string, options?: SanitizerOptions): string;
export declare const allowedCssProperties: string[];
