import { Unionize } from 'utility-types';
import { Locale } from './locale';
export interface ParseFlagMark {
    year: number;
    month: number;
    day: number;
    hour: number;
    minute: number;
    second: number;
    millisecond: number;
    offset: number;
    weekday: number;
    week: number;
    date: Date;
    isPM: boolean;
}
export declare type ParseFlagCallBackReturn = Unionize<ParseFlagMark>;
export declare type ParseFlagRegExp = RegExp | ((locale: Locale) => RegExp);
export declare type ParseFlagCallBack = (input: string, locale: Locale) => ParseFlagCallBackReturn;
export interface ParseFlag {
    [key: string]: [ParseFlagRegExp, ParseFlagCallBack];
}
export default function parse(str: string, format: string, options?: {
    locale?: Locale;
    backupDate?: Date;
}): Date;
