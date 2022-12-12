import { StackFrame } from '@sentry/types';
export declare type StackParser = (stack: string, skipFirst?: number) => StackFrame[];
export declare type StackLineParserFn = (line: string) => StackFrame | undefined;
export declare type StackLineParser = [number, StackLineParserFn];
/**
 * Creates a stack parser with the supplied line parsers
 *
 * StackFrames are returned in the correct order for Sentry Exception
 * frames and with Sentry SDK internal frames removed from the top and bottom
 *
 */
export declare function createStackParser(...parsers: StackLineParser[]): StackParser;
/**
 * @hidden
 */
export declare function stripSentryFramesAndReverse(stack: StackFrame[]): StackFrame[];
/**
 * Safely extract function name from itself
 */
export declare function getFunctionName(fn: unknown): string;
//# sourceMappingURL=stacktrace.d.ts.map