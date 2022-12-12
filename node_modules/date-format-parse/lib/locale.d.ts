export interface Locale {
    months: string[];
    monthsShort: string[];
    weekdays: string[];
    weekdaysShort: string[];
    weekdaysMin: string[];
    firstDayOfWeek?: number;
    firstWeekContainsDate?: number;
    meridiemParse?: RegExp;
    meridiem?: (hours: number, minutes: number, isLowercase: boolean) => string;
    isPM?: (input: string) => boolean;
}
