import { Formatter } from './Formatter';
import { CodeFrameFormatterOptions } from './CodeframeFormatter';
declare type FormatterType = undefined | 'default' | 'codeframe' | Formatter;
declare type FormatterOptions = CodeFrameFormatterOptions;
declare function createFormatter(type?: FormatterType, options?: FormatterOptions): Formatter;
export { createFormatter, FormatterType, FormatterOptions };
