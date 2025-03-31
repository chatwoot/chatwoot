import type { PreInitMethodCall, PreInitMethodName, PreInitMethodParams } from '.';
export declare function transformSnippetCall([methodName, ...args]: SnippetWindowBufferedMethodCall): PreInitMethodCall;
type SnippetWindowBufferedMethodCall<MethodName extends PreInitMethodName = PreInitMethodName> = [MethodName, ...PreInitMethodParams<MethodName>];
/**
 * Fetch the buffered method calls from the window object and normalize them.
 * This removes existing buffered calls from the window object.
 */
export declare const popSnippetWindowBuffer: () => PreInitMethodCall[];
export {};
//# sourceMappingURL=snippet.d.ts.map