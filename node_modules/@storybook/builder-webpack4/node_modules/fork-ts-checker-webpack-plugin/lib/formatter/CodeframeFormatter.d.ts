import { Formatter } from './Formatter';
interface CodeFrameFormatterOptions {
    /** Syntax highlight the code as JavaScript for terminals. default: false */
    highlightCode?: boolean;
    /**  The number of lines to show above the error. default: 2 */
    linesBelow?: number;
    /**  The number of lines to show below the error. default: 3 */
    linesAbove?: number;
    /**
     * Forcibly syntax highlight the code as JavaScript (for non-terminals);
     * overrides highlightCode.
     * default: false
     */
    forceColor?: boolean;
}
declare function createCodeframeFormatter(options?: CodeFrameFormatterOptions): Formatter;
export { createCodeframeFormatter, CodeFrameFormatterOptions };
