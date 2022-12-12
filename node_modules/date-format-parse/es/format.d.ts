import { Locale } from './locale';
declare function format(val: Date, str: string, options?: {
    locale?: Locale;
}): string;
export default format;
