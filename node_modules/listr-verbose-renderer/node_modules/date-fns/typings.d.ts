declare module 'date-fns' {
  function addDays (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addDays {}

  function addHours (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addHours {}

  function addISOYears (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addISOYears {}

  function addMilliseconds (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addMilliseconds {}

  function addMinutes (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addMinutes {}

  function addMonths (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addMonths {}

  function addQuarters (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addQuarters {}

  function addSeconds (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addSeconds {}

  function addWeeks (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addWeeks {}

  function addYears (
    date: Date | string | number,
    amount: number
  ): Date
  namespace addYears {}

  function areRangesOverlapping (
    initialRangeStartDate: Date | string | number,
    initialRangeEndDate: Date | string | number,
    comparedRangeStartDate: Date | string | number,
    comparedRangeEndDate: Date | string | number
  ): boolean
  namespace areRangesOverlapping {}

  function closestIndexTo (
    dateToCompare: Date | string | number,
    datesArray: (Date | string | number)[]
  ): number
  namespace closestIndexTo {}

  function closestTo (
    dateToCompare: Date | string | number,
    datesArray: (Date | string | number)[]
  ): Date
  namespace closestTo {}

  function compareAsc (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace compareAsc {}

  function compareDesc (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace compareDesc {}

  function differenceInCalendarDays (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarDays {}

  function differenceInCalendarISOWeeks (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarISOWeeks {}

  function differenceInCalendarISOYears (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarISOYears {}

  function differenceInCalendarMonths (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarMonths {}

  function differenceInCalendarQuarters (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarQuarters {}

  function differenceInCalendarWeeks (
    dateLeft: Date | string | number,
    dateRight: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): number
  namespace differenceInCalendarWeeks {}

  function differenceInCalendarYears (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInCalendarYears {}

  function differenceInDays (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInDays {}

  function differenceInHours (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInHours {}

  function differenceInISOYears (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInISOYears {}

  function differenceInMilliseconds (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInMilliseconds {}

  function differenceInMinutes (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInMinutes {}

  function differenceInMonths (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInMonths {}

  function differenceInQuarters (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInQuarters {}

  function differenceInSeconds (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInSeconds {}

  function differenceInWeeks (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInWeeks {}

  function differenceInYears (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): number
  namespace differenceInYears {}

  function distanceInWords (
    dateToCompare: Date | string | number,
    date: Date | string | number,
    options?: {
      includeSeconds?: boolean,
      addSuffix?: boolean,
      locale?: Object
    }
  ): string
  namespace distanceInWords {}

  function distanceInWordsStrict (
    dateToCompare: Date | string | number,
    date: Date | string | number,
    options?: {
      addSuffix?: boolean,
      unit?: 's' | 'm' | 'h' | 'd' | 'M' | 'Y',
      partialMethod?: 'floor' | 'ceil' | 'round',
      locale?: Object
    }
  ): string
  namespace distanceInWordsStrict {}

  function distanceInWordsToNow (
    date: Date | string | number,
    options?: {
      includeSeconds?: boolean,
      addSuffix?: boolean,
      locale?: Object
    }
  ): string
  namespace distanceInWordsToNow {}

  function eachDay (
    startDate: Date | string | number,
    endDate: Date | string | number,
    step?: number
  ): Date[]
  namespace eachDay {}

  function endOfDay (
    date: Date | string | number
  ): Date
  namespace endOfDay {}

  function endOfHour (
    date: Date | string | number
  ): Date
  namespace endOfHour {}

  function endOfISOWeek (
    date: Date | string | number
  ): Date
  namespace endOfISOWeek {}

  function endOfISOYear (
    date: Date | string | number
  ): Date
  namespace endOfISOYear {}

  function endOfMinute (
    date: Date | string | number
  ): Date
  namespace endOfMinute {}

  function endOfMonth (
    date: Date | string | number
  ): Date
  namespace endOfMonth {}

  function endOfQuarter (
    date: Date | string | number
  ): Date
  namespace endOfQuarter {}

  function endOfSecond (
    date: Date | string | number
  ): Date
  namespace endOfSecond {}

  function endOfToday (): Date
  namespace endOfToday {}

  function endOfTomorrow (): Date
  namespace endOfTomorrow {}

  function endOfWeek (
    date: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): Date
  namespace endOfWeek {}

  function endOfYear (
    date: Date | string | number
  ): Date
  namespace endOfYear {}

  function endOfYesterday (): Date
  namespace endOfYesterday {}

  function format (
    date: Date | string | number,
    format?: string,
    options?: {
      locale?: Object
    }
  ): string
  namespace format {}

  function getDate (
    date: Date | string | number
  ): number
  namespace getDate {}

  function getDay (
    date: Date | string | number
  ): number
  namespace getDay {}

  function getDayOfYear (
    date: Date | string | number
  ): number
  namespace getDayOfYear {}

  function getDaysInMonth (
    date: Date | string | number
  ): number
  namespace getDaysInMonth {}

  function getDaysInYear (
    date: Date | string | number
  ): number
  namespace getDaysInYear {}

  function getHours (
    date: Date | string | number
  ): number
  namespace getHours {}

  function getISODay (
    date: Date | string | number
  ): number
  namespace getISODay {}

  function getISOWeek (
    date: Date | string | number
  ): number
  namespace getISOWeek {}

  function getISOWeeksInYear (
    date: Date | string | number
  ): number
  namespace getISOWeeksInYear {}

  function getISOYear (
    date: Date | string | number
  ): number
  namespace getISOYear {}

  function getMilliseconds (
    date: Date | string | number
  ): number
  namespace getMilliseconds {}

  function getMinutes (
    date: Date | string | number
  ): number
  namespace getMinutes {}

  function getMonth (
    date: Date | string | number
  ): number
  namespace getMonth {}

  function getOverlappingDaysInRanges (
    initialRangeStartDate: Date | string | number,
    initialRangeEndDate: Date | string | number,
    comparedRangeStartDate: Date | string | number,
    comparedRangeEndDate: Date | string | number
  ): number
  namespace getOverlappingDaysInRanges {}

  function getQuarter (
    date: Date | string | number
  ): number
  namespace getQuarter {}

  function getSeconds (
    date: Date | string | number
  ): number
  namespace getSeconds {}

  function getTime (
    date: Date | string | number
  ): number
  namespace getTime {}

  function getYear (
    date: Date | string | number
  ): number
  namespace getYear {}

  function isAfter (
    date: Date | string | number,
    dateToCompare: Date | string | number
  ): boolean
  namespace isAfter {}

  function isBefore (
    date: Date | string | number,
    dateToCompare: Date | string | number
  ): boolean
  namespace isBefore {}

  function isDate (
    argument: any
  ): boolean
  namespace isDate {}

  function isEqual (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isEqual {}

  function isFirstDayOfMonth (
    date: Date | string | number
  ): boolean
  namespace isFirstDayOfMonth {}

  function isFriday (
    date: Date | string | number
  ): boolean
  namespace isFriday {}

  function isFuture (
    date: Date | string | number
  ): boolean
  namespace isFuture {}

  function isLastDayOfMonth (
    date: Date | string | number
  ): boolean
  namespace isLastDayOfMonth {}

  function isLeapYear (
    date: Date | string | number
  ): boolean
  namespace isLeapYear {}

  function isMonday (
    date: Date | string | number
  ): boolean
  namespace isMonday {}

  function isPast (
    date: Date | string | number
  ): boolean
  namespace isPast {}

  function isSameDay (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameDay {}

  function isSameHour (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameHour {}

  function isSameISOWeek (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameISOWeek {}

  function isSameISOYear (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameISOYear {}

  function isSameMinute (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameMinute {}

  function isSameMonth (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameMonth {}

  function isSameQuarter (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameQuarter {}

  function isSameSecond (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameSecond {}

  function isSameWeek (
    dateLeft: Date | string | number,
    dateRight: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): boolean
  namespace isSameWeek {}

  function isSameYear (
    dateLeft: Date | string | number,
    dateRight: Date | string | number
  ): boolean
  namespace isSameYear {}

  function isSaturday (
    date: Date | string | number
  ): boolean
  namespace isSaturday {}

  function isSunday (
    date: Date | string | number
  ): boolean
  namespace isSunday {}

  function isThisHour (
    date: Date | string | number
  ): boolean
  namespace isThisHour {}

  function isThisISOWeek (
    date: Date | string | number
  ): boolean
  namespace isThisISOWeek {}

  function isThisISOYear (
    date: Date | string | number
  ): boolean
  namespace isThisISOYear {}

  function isThisMinute (
    date: Date | string | number
  ): boolean
  namespace isThisMinute {}

  function isThisMonth (
    date: Date | string | number
  ): boolean
  namespace isThisMonth {}

  function isThisQuarter (
    date: Date | string | number
  ): boolean
  namespace isThisQuarter {}

  function isThisSecond (
    date: Date | string | number
  ): boolean
  namespace isThisSecond {}

  function isThisWeek (
    date: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): boolean
  namespace isThisWeek {}

  function isThisYear (
    date: Date | string | number
  ): boolean
  namespace isThisYear {}

  function isThursday (
    date: Date | string | number
  ): boolean
  namespace isThursday {}

  function isToday (
    date: Date | string | number
  ): boolean
  namespace isToday {}

  function isTomorrow (
    date: Date | string | number
  ): boolean
  namespace isTomorrow {}

  function isTuesday (
    date: Date | string | number
  ): boolean
  namespace isTuesday {}

  function isValid (
    date: Date
  ): boolean
  namespace isValid {}

  function isWednesday (
    date: Date | string | number
  ): boolean
  namespace isWednesday {}

  function isWeekend (
    date: Date | string | number
  ): boolean
  namespace isWeekend {}

  function isWithinRange (
    date: Date | string | number,
    startDate: Date | string | number,
    endDate: Date | string | number
  ): boolean
  namespace isWithinRange {}

  function isYesterday (
    date: Date | string | number
  ): boolean
  namespace isYesterday {}

  function lastDayOfISOWeek (
    date: Date | string | number
  ): Date
  namespace lastDayOfISOWeek {}

  function lastDayOfISOYear (
    date: Date | string | number
  ): Date
  namespace lastDayOfISOYear {}

  function lastDayOfMonth (
    date: Date | string | number
  ): Date
  namespace lastDayOfMonth {}

  function lastDayOfQuarter (
    date: Date | string | number
  ): Date
  namespace lastDayOfQuarter {}

  function lastDayOfWeek (
    date: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): Date
  namespace lastDayOfWeek {}

  function lastDayOfYear (
    date: Date | string | number
  ): Date
  namespace lastDayOfYear {}

  function max (
    ...dates: (Date | string | number)[]
  ): Date
  namespace max {}

  function min (
    ...dates: (Date | string | number)[]
  ): Date
  namespace min {}

  function parse (
    argument: Date | string | number,
    options?: {
      additionalDigits?: 0 | 1 | 2
    }
  ): Date
  namespace parse {}

  function setDate (
    date: Date | string | number,
    dayOfMonth: number
  ): Date
  namespace setDate {}

  function setDay (
    date: Date | string | number,
    day: number,
    options?: {
      weekStartsOn?: number
    }
  ): Date
  namespace setDay {}

  function setDayOfYear (
    date: Date | string | number,
    dayOfYear: number
  ): Date
  namespace setDayOfYear {}

  function setHours (
    date: Date | string | number,
    hours: number
  ): Date
  namespace setHours {}

  function setISODay (
    date: Date | string | number,
    day: number
  ): Date
  namespace setISODay {}

  function setISOWeek (
    date: Date | string | number,
    isoWeek: number
  ): Date
  namespace setISOWeek {}

  function setISOYear (
    date: Date | string | number,
    isoYear: number
  ): Date
  namespace setISOYear {}

  function setMilliseconds (
    date: Date | string | number,
    milliseconds: number
  ): Date
  namespace setMilliseconds {}

  function setMinutes (
    date: Date | string | number,
    minutes: number
  ): Date
  namespace setMinutes {}

  function setMonth (
    date: Date | string | number,
    month: number
  ): Date
  namespace setMonth {}

  function setQuarter (
    date: Date | string | number,
    quarter: number
  ): Date
  namespace setQuarter {}

  function setSeconds (
    date: Date | string | number,
    seconds: number
  ): Date
  namespace setSeconds {}

  function setYear (
    date: Date | string | number,
    year: number
  ): Date
  namespace setYear {}

  function startOfDay (
    date: Date | string | number
  ): Date
  namespace startOfDay {}

  function startOfHour (
    date: Date | string | number
  ): Date
  namespace startOfHour {}

  function startOfISOWeek (
    date: Date | string | number
  ): Date
  namespace startOfISOWeek {}

  function startOfISOYear (
    date: Date | string | number
  ): Date
  namespace startOfISOYear {}

  function startOfMinute (
    date: Date | string | number
  ): Date
  namespace startOfMinute {}

  function startOfMonth (
    date: Date | string | number
  ): Date
  namespace startOfMonth {}

  function startOfQuarter (
    date: Date | string | number
  ): Date
  namespace startOfQuarter {}

  function startOfSecond (
    date: Date | string | number
  ): Date
  namespace startOfSecond {}

  function startOfToday (): Date
  namespace startOfToday {}

  function startOfTomorrow (): Date
  namespace startOfTomorrow {}

  function startOfWeek (
    date: Date | string | number,
    options?: {
      weekStartsOn?: number
    }
  ): Date
  namespace startOfWeek {}

  function startOfYear (
    date: Date | string | number
  ): Date
  namespace startOfYear {}

  function startOfYesterday (): Date
  namespace startOfYesterday {}

  function subDays (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subDays {}

  function subHours (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subHours {}

  function subISOYears (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subISOYears {}

  function subMilliseconds (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subMilliseconds {}

  function subMinutes (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subMinutes {}

  function subMonths (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subMonths {}

  function subQuarters (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subQuarters {}

  function subSeconds (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subSeconds {}

  function subWeeks (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subWeeks {}

  function subYears (
    date: Date | string | number,
    amount: number
  ): Date
  namespace subYears {}
}

declare module 'date-fns/add_days' {
  import {addDays} from 'date-fns'
  export = addDays
}

declare module 'date-fns/add_hours' {
  import {addHours} from 'date-fns'
  export = addHours
}

declare module 'date-fns/add_iso_years' {
  import {addISOYears} from 'date-fns'
  export = addISOYears
}

declare module 'date-fns/add_milliseconds' {
  import {addMilliseconds} from 'date-fns'
  export = addMilliseconds
}

declare module 'date-fns/add_minutes' {
  import {addMinutes} from 'date-fns'
  export = addMinutes
}

declare module 'date-fns/add_months' {
  import {addMonths} from 'date-fns'
  export = addMonths
}

declare module 'date-fns/add_quarters' {
  import {addQuarters} from 'date-fns'
  export = addQuarters
}

declare module 'date-fns/add_seconds' {
  import {addSeconds} from 'date-fns'
  export = addSeconds
}

declare module 'date-fns/add_weeks' {
  import {addWeeks} from 'date-fns'
  export = addWeeks
}

declare module 'date-fns/add_years' {
  import {addYears} from 'date-fns'
  export = addYears
}

declare module 'date-fns/are_ranges_overlapping' {
  import {areRangesOverlapping} from 'date-fns'
  export = areRangesOverlapping
}

declare module 'date-fns/closest_index_to' {
  import {closestIndexTo} from 'date-fns'
  export = closestIndexTo
}

declare module 'date-fns/closest_to' {
  import {closestTo} from 'date-fns'
  export = closestTo
}

declare module 'date-fns/compare_asc' {
  import {compareAsc} from 'date-fns'
  export = compareAsc
}

declare module 'date-fns/compare_desc' {
  import {compareDesc} from 'date-fns'
  export = compareDesc
}

declare module 'date-fns/difference_in_calendar_days' {
  import {differenceInCalendarDays} from 'date-fns'
  export = differenceInCalendarDays
}

declare module 'date-fns/difference_in_calendar_iso_weeks' {
  import {differenceInCalendarISOWeeks} from 'date-fns'
  export = differenceInCalendarISOWeeks
}

declare module 'date-fns/difference_in_calendar_iso_years' {
  import {differenceInCalendarISOYears} from 'date-fns'
  export = differenceInCalendarISOYears
}

declare module 'date-fns/difference_in_calendar_months' {
  import {differenceInCalendarMonths} from 'date-fns'
  export = differenceInCalendarMonths
}

declare module 'date-fns/difference_in_calendar_quarters' {
  import {differenceInCalendarQuarters} from 'date-fns'
  export = differenceInCalendarQuarters
}

declare module 'date-fns/difference_in_calendar_weeks' {
  import {differenceInCalendarWeeks} from 'date-fns'
  export = differenceInCalendarWeeks
}

declare module 'date-fns/difference_in_calendar_years' {
  import {differenceInCalendarYears} from 'date-fns'
  export = differenceInCalendarYears
}

declare module 'date-fns/difference_in_days' {
  import {differenceInDays} from 'date-fns'
  export = differenceInDays
}

declare module 'date-fns/difference_in_hours' {
  import {differenceInHours} from 'date-fns'
  export = differenceInHours
}

declare module 'date-fns/difference_in_iso_years' {
  import {differenceInISOYears} from 'date-fns'
  export = differenceInISOYears
}

declare module 'date-fns/difference_in_milliseconds' {
  import {differenceInMilliseconds} from 'date-fns'
  export = differenceInMilliseconds
}

declare module 'date-fns/difference_in_minutes' {
  import {differenceInMinutes} from 'date-fns'
  export = differenceInMinutes
}

declare module 'date-fns/difference_in_months' {
  import {differenceInMonths} from 'date-fns'
  export = differenceInMonths
}

declare module 'date-fns/difference_in_quarters' {
  import {differenceInQuarters} from 'date-fns'
  export = differenceInQuarters
}

declare module 'date-fns/difference_in_seconds' {
  import {differenceInSeconds} from 'date-fns'
  export = differenceInSeconds
}

declare module 'date-fns/difference_in_weeks' {
  import {differenceInWeeks} from 'date-fns'
  export = differenceInWeeks
}

declare module 'date-fns/difference_in_years' {
  import {differenceInYears} from 'date-fns'
  export = differenceInYears
}

declare module 'date-fns/distance_in_words' {
  import {distanceInWords} from 'date-fns'
  export = distanceInWords
}

declare module 'date-fns/distance_in_words_strict' {
  import {distanceInWordsStrict} from 'date-fns'
  export = distanceInWordsStrict
}

declare module 'date-fns/distance_in_words_to_now' {
  import {distanceInWordsToNow} from 'date-fns'
  export = distanceInWordsToNow
}

declare module 'date-fns/each_day' {
  import {eachDay} from 'date-fns'
  export = eachDay
}

declare module 'date-fns/end_of_day' {
  import {endOfDay} from 'date-fns'
  export = endOfDay
}

declare module 'date-fns/end_of_hour' {
  import {endOfHour} from 'date-fns'
  export = endOfHour
}

declare module 'date-fns/end_of_iso_week' {
  import {endOfISOWeek} from 'date-fns'
  export = endOfISOWeek
}

declare module 'date-fns/end_of_iso_year' {
  import {endOfISOYear} from 'date-fns'
  export = endOfISOYear
}

declare module 'date-fns/end_of_minute' {
  import {endOfMinute} from 'date-fns'
  export = endOfMinute
}

declare module 'date-fns/end_of_month' {
  import {endOfMonth} from 'date-fns'
  export = endOfMonth
}

declare module 'date-fns/end_of_quarter' {
  import {endOfQuarter} from 'date-fns'
  export = endOfQuarter
}

declare module 'date-fns/end_of_second' {
  import {endOfSecond} from 'date-fns'
  export = endOfSecond
}

declare module 'date-fns/end_of_today' {
  import {endOfToday} from 'date-fns'
  export = endOfToday
}

declare module 'date-fns/end_of_tomorrow' {
  import {endOfTomorrow} from 'date-fns'
  export = endOfTomorrow
}

declare module 'date-fns/end_of_week' {
  import {endOfWeek} from 'date-fns'
  export = endOfWeek
}

declare module 'date-fns/end_of_year' {
  import {endOfYear} from 'date-fns'
  export = endOfYear
}

declare module 'date-fns/end_of_yesterday' {
  import {endOfYesterday} from 'date-fns'
  export = endOfYesterday
}

declare module 'date-fns/format' {
  import {format} from 'date-fns'
  export = format
}

declare module 'date-fns/get_date' {
  import {getDate} from 'date-fns'
  export = getDate
}

declare module 'date-fns/get_day' {
  import {getDay} from 'date-fns'
  export = getDay
}

declare module 'date-fns/get_day_of_year' {
  import {getDayOfYear} from 'date-fns'
  export = getDayOfYear
}

declare module 'date-fns/get_days_in_month' {
  import {getDaysInMonth} from 'date-fns'
  export = getDaysInMonth
}

declare module 'date-fns/get_days_in_year' {
  import {getDaysInYear} from 'date-fns'
  export = getDaysInYear
}

declare module 'date-fns/get_hours' {
  import {getHours} from 'date-fns'
  export = getHours
}

declare module 'date-fns/get_iso_day' {
  import {getISODay} from 'date-fns'
  export = getISODay
}

declare module 'date-fns/get_iso_week' {
  import {getISOWeek} from 'date-fns'
  export = getISOWeek
}

declare module 'date-fns/get_iso_weeks_in_year' {
  import {getISOWeeksInYear} from 'date-fns'
  export = getISOWeeksInYear
}

declare module 'date-fns/get_iso_year' {
  import {getISOYear} from 'date-fns'
  export = getISOYear
}

declare module 'date-fns/get_milliseconds' {
  import {getMilliseconds} from 'date-fns'
  export = getMilliseconds
}

declare module 'date-fns/get_minutes' {
  import {getMinutes} from 'date-fns'
  export = getMinutes
}

declare module 'date-fns/get_month' {
  import {getMonth} from 'date-fns'
  export = getMonth
}

declare module 'date-fns/get_overlapping_days_in_ranges' {
  import {getOverlappingDaysInRanges} from 'date-fns'
  export = getOverlappingDaysInRanges
}

declare module 'date-fns/get_quarter' {
  import {getQuarter} from 'date-fns'
  export = getQuarter
}

declare module 'date-fns/get_seconds' {
  import {getSeconds} from 'date-fns'
  export = getSeconds
}

declare module 'date-fns/get_time' {
  import {getTime} from 'date-fns'
  export = getTime
}

declare module 'date-fns/get_year' {
  import {getYear} from 'date-fns'
  export = getYear
}

declare module 'date-fns/is_after' {
  import {isAfter} from 'date-fns'
  export = isAfter
}

declare module 'date-fns/is_before' {
  import {isBefore} from 'date-fns'
  export = isBefore
}

declare module 'date-fns/is_date' {
  import {isDate} from 'date-fns'
  export = isDate
}

declare module 'date-fns/is_equal' {
  import {isEqual} from 'date-fns'
  export = isEqual
}

declare module 'date-fns/is_first_day_of_month' {
  import {isFirstDayOfMonth} from 'date-fns'
  export = isFirstDayOfMonth
}

declare module 'date-fns/is_friday' {
  import {isFriday} from 'date-fns'
  export = isFriday
}

declare module 'date-fns/is_future' {
  import {isFuture} from 'date-fns'
  export = isFuture
}

declare module 'date-fns/is_last_day_of_month' {
  import {isLastDayOfMonth} from 'date-fns'
  export = isLastDayOfMonth
}

declare module 'date-fns/is_leap_year' {
  import {isLeapYear} from 'date-fns'
  export = isLeapYear
}

declare module 'date-fns/is_monday' {
  import {isMonday} from 'date-fns'
  export = isMonday
}

declare module 'date-fns/is_past' {
  import {isPast} from 'date-fns'
  export = isPast
}

declare module 'date-fns/is_same_day' {
  import {isSameDay} from 'date-fns'
  export = isSameDay
}

declare module 'date-fns/is_same_hour' {
  import {isSameHour} from 'date-fns'
  export = isSameHour
}

declare module 'date-fns/is_same_iso_week' {
  import {isSameISOWeek} from 'date-fns'
  export = isSameISOWeek
}

declare module 'date-fns/is_same_iso_year' {
  import {isSameISOYear} from 'date-fns'
  export = isSameISOYear
}

declare module 'date-fns/is_same_minute' {
  import {isSameMinute} from 'date-fns'
  export = isSameMinute
}

declare module 'date-fns/is_same_month' {
  import {isSameMonth} from 'date-fns'
  export = isSameMonth
}

declare module 'date-fns/is_same_quarter' {
  import {isSameQuarter} from 'date-fns'
  export = isSameQuarter
}

declare module 'date-fns/is_same_second' {
  import {isSameSecond} from 'date-fns'
  export = isSameSecond
}

declare module 'date-fns/is_same_week' {
  import {isSameWeek} from 'date-fns'
  export = isSameWeek
}

declare module 'date-fns/is_same_year' {
  import {isSameYear} from 'date-fns'
  export = isSameYear
}

declare module 'date-fns/is_saturday' {
  import {isSaturday} from 'date-fns'
  export = isSaturday
}

declare module 'date-fns/is_sunday' {
  import {isSunday} from 'date-fns'
  export = isSunday
}

declare module 'date-fns/is_this_hour' {
  import {isThisHour} from 'date-fns'
  export = isThisHour
}

declare module 'date-fns/is_this_iso_week' {
  import {isThisISOWeek} from 'date-fns'
  export = isThisISOWeek
}

declare module 'date-fns/is_this_iso_year' {
  import {isThisISOYear} from 'date-fns'
  export = isThisISOYear
}

declare module 'date-fns/is_this_minute' {
  import {isThisMinute} from 'date-fns'
  export = isThisMinute
}

declare module 'date-fns/is_this_month' {
  import {isThisMonth} from 'date-fns'
  export = isThisMonth
}

declare module 'date-fns/is_this_quarter' {
  import {isThisQuarter} from 'date-fns'
  export = isThisQuarter
}

declare module 'date-fns/is_this_second' {
  import {isThisSecond} from 'date-fns'
  export = isThisSecond
}

declare module 'date-fns/is_this_week' {
  import {isThisWeek} from 'date-fns'
  export = isThisWeek
}

declare module 'date-fns/is_this_year' {
  import {isThisYear} from 'date-fns'
  export = isThisYear
}

declare module 'date-fns/is_thursday' {
  import {isThursday} from 'date-fns'
  export = isThursday
}

declare module 'date-fns/is_today' {
  import {isToday} from 'date-fns'
  export = isToday
}

declare module 'date-fns/is_tomorrow' {
  import {isTomorrow} from 'date-fns'
  export = isTomorrow
}

declare module 'date-fns/is_tuesday' {
  import {isTuesday} from 'date-fns'
  export = isTuesday
}

declare module 'date-fns/is_valid' {
  import {isValid} from 'date-fns'
  export = isValid
}

declare module 'date-fns/is_wednesday' {
  import {isWednesday} from 'date-fns'
  export = isWednesday
}

declare module 'date-fns/is_weekend' {
  import {isWeekend} from 'date-fns'
  export = isWeekend
}

declare module 'date-fns/is_within_range' {
  import {isWithinRange} from 'date-fns'
  export = isWithinRange
}

declare module 'date-fns/is_yesterday' {
  import {isYesterday} from 'date-fns'
  export = isYesterday
}

declare module 'date-fns/last_day_of_iso_week' {
  import {lastDayOfISOWeek} from 'date-fns'
  export = lastDayOfISOWeek
}

declare module 'date-fns/last_day_of_iso_year' {
  import {lastDayOfISOYear} from 'date-fns'
  export = lastDayOfISOYear
}

declare module 'date-fns/last_day_of_month' {
  import {lastDayOfMonth} from 'date-fns'
  export = lastDayOfMonth
}

declare module 'date-fns/last_day_of_quarter' {
  import {lastDayOfQuarter} from 'date-fns'
  export = lastDayOfQuarter
}

declare module 'date-fns/last_day_of_week' {
  import {lastDayOfWeek} from 'date-fns'
  export = lastDayOfWeek
}

declare module 'date-fns/last_day_of_year' {
  import {lastDayOfYear} from 'date-fns'
  export = lastDayOfYear
}

declare module 'date-fns/max' {
  import {max} from 'date-fns'
  export = max
}

declare module 'date-fns/min' {
  import {min} from 'date-fns'
  export = min
}

declare module 'date-fns/parse' {
  import {parse} from 'date-fns'
  export = parse
}

declare module 'date-fns/set_date' {
  import {setDate} from 'date-fns'
  export = setDate
}

declare module 'date-fns/set_day' {
  import {setDay} from 'date-fns'
  export = setDay
}

declare module 'date-fns/set_day_of_year' {
  import {setDayOfYear} from 'date-fns'
  export = setDayOfYear
}

declare module 'date-fns/set_hours' {
  import {setHours} from 'date-fns'
  export = setHours
}

declare module 'date-fns/set_iso_day' {
  import {setISODay} from 'date-fns'
  export = setISODay
}

declare module 'date-fns/set_iso_week' {
  import {setISOWeek} from 'date-fns'
  export = setISOWeek
}

declare module 'date-fns/set_iso_year' {
  import {setISOYear} from 'date-fns'
  export = setISOYear
}

declare module 'date-fns/set_milliseconds' {
  import {setMilliseconds} from 'date-fns'
  export = setMilliseconds
}

declare module 'date-fns/set_minutes' {
  import {setMinutes} from 'date-fns'
  export = setMinutes
}

declare module 'date-fns/set_month' {
  import {setMonth} from 'date-fns'
  export = setMonth
}

declare module 'date-fns/set_quarter' {
  import {setQuarter} from 'date-fns'
  export = setQuarter
}

declare module 'date-fns/set_seconds' {
  import {setSeconds} from 'date-fns'
  export = setSeconds
}

declare module 'date-fns/set_year' {
  import {setYear} from 'date-fns'
  export = setYear
}

declare module 'date-fns/start_of_day' {
  import {startOfDay} from 'date-fns'
  export = startOfDay
}

declare module 'date-fns/start_of_hour' {
  import {startOfHour} from 'date-fns'
  export = startOfHour
}

declare module 'date-fns/start_of_iso_week' {
  import {startOfISOWeek} from 'date-fns'
  export = startOfISOWeek
}

declare module 'date-fns/start_of_iso_year' {
  import {startOfISOYear} from 'date-fns'
  export = startOfISOYear
}

declare module 'date-fns/start_of_minute' {
  import {startOfMinute} from 'date-fns'
  export = startOfMinute
}

declare module 'date-fns/start_of_month' {
  import {startOfMonth} from 'date-fns'
  export = startOfMonth
}

declare module 'date-fns/start_of_quarter' {
  import {startOfQuarter} from 'date-fns'
  export = startOfQuarter
}

declare module 'date-fns/start_of_second' {
  import {startOfSecond} from 'date-fns'
  export = startOfSecond
}

declare module 'date-fns/start_of_today' {
  import {startOfToday} from 'date-fns'
  export = startOfToday
}

declare module 'date-fns/start_of_tomorrow' {
  import {startOfTomorrow} from 'date-fns'
  export = startOfTomorrow
}

declare module 'date-fns/start_of_week' {
  import {startOfWeek} from 'date-fns'
  export = startOfWeek
}

declare module 'date-fns/start_of_year' {
  import {startOfYear} from 'date-fns'
  export = startOfYear
}

declare module 'date-fns/start_of_yesterday' {
  import {startOfYesterday} from 'date-fns'
  export = startOfYesterday
}

declare module 'date-fns/sub_days' {
  import {subDays} from 'date-fns'
  export = subDays
}

declare module 'date-fns/sub_hours' {
  import {subHours} from 'date-fns'
  export = subHours
}

declare module 'date-fns/sub_iso_years' {
  import {subISOYears} from 'date-fns'
  export = subISOYears
}

declare module 'date-fns/sub_milliseconds' {
  import {subMilliseconds} from 'date-fns'
  export = subMilliseconds
}

declare module 'date-fns/sub_minutes' {
  import {subMinutes} from 'date-fns'
  export = subMinutes
}

declare module 'date-fns/sub_months' {
  import {subMonths} from 'date-fns'
  export = subMonths
}

declare module 'date-fns/sub_quarters' {
  import {subQuarters} from 'date-fns'
  export = subQuarters
}

declare module 'date-fns/sub_seconds' {
  import {subSeconds} from 'date-fns'
  export = subSeconds
}

declare module 'date-fns/sub_weeks' {
  import {subWeeks} from 'date-fns'
  export = subWeeks
}

declare module 'date-fns/sub_years' {
  import {subYears} from 'date-fns'
  export = subYears
}

declare module 'date-fns/add_days/index' {
  import {addDays} from 'date-fns'
  export = addDays
}

declare module 'date-fns/add_hours/index' {
  import {addHours} from 'date-fns'
  export = addHours
}

declare module 'date-fns/add_iso_years/index' {
  import {addISOYears} from 'date-fns'
  export = addISOYears
}

declare module 'date-fns/add_milliseconds/index' {
  import {addMilliseconds} from 'date-fns'
  export = addMilliseconds
}

declare module 'date-fns/add_minutes/index' {
  import {addMinutes} from 'date-fns'
  export = addMinutes
}

declare module 'date-fns/add_months/index' {
  import {addMonths} from 'date-fns'
  export = addMonths
}

declare module 'date-fns/add_quarters/index' {
  import {addQuarters} from 'date-fns'
  export = addQuarters
}

declare module 'date-fns/add_seconds/index' {
  import {addSeconds} from 'date-fns'
  export = addSeconds
}

declare module 'date-fns/add_weeks/index' {
  import {addWeeks} from 'date-fns'
  export = addWeeks
}

declare module 'date-fns/add_years/index' {
  import {addYears} from 'date-fns'
  export = addYears
}

declare module 'date-fns/are_ranges_overlapping/index' {
  import {areRangesOverlapping} from 'date-fns'
  export = areRangesOverlapping
}

declare module 'date-fns/closest_index_to/index' {
  import {closestIndexTo} from 'date-fns'
  export = closestIndexTo
}

declare module 'date-fns/closest_to/index' {
  import {closestTo} from 'date-fns'
  export = closestTo
}

declare module 'date-fns/compare_asc/index' {
  import {compareAsc} from 'date-fns'
  export = compareAsc
}

declare module 'date-fns/compare_desc/index' {
  import {compareDesc} from 'date-fns'
  export = compareDesc
}

declare module 'date-fns/difference_in_calendar_days/index' {
  import {differenceInCalendarDays} from 'date-fns'
  export = differenceInCalendarDays
}

declare module 'date-fns/difference_in_calendar_iso_weeks/index' {
  import {differenceInCalendarISOWeeks} from 'date-fns'
  export = differenceInCalendarISOWeeks
}

declare module 'date-fns/difference_in_calendar_iso_years/index' {
  import {differenceInCalendarISOYears} from 'date-fns'
  export = differenceInCalendarISOYears
}

declare module 'date-fns/difference_in_calendar_months/index' {
  import {differenceInCalendarMonths} from 'date-fns'
  export = differenceInCalendarMonths
}

declare module 'date-fns/difference_in_calendar_quarters/index' {
  import {differenceInCalendarQuarters} from 'date-fns'
  export = differenceInCalendarQuarters
}

declare module 'date-fns/difference_in_calendar_weeks/index' {
  import {differenceInCalendarWeeks} from 'date-fns'
  export = differenceInCalendarWeeks
}

declare module 'date-fns/difference_in_calendar_years/index' {
  import {differenceInCalendarYears} from 'date-fns'
  export = differenceInCalendarYears
}

declare module 'date-fns/difference_in_days/index' {
  import {differenceInDays} from 'date-fns'
  export = differenceInDays
}

declare module 'date-fns/difference_in_hours/index' {
  import {differenceInHours} from 'date-fns'
  export = differenceInHours
}

declare module 'date-fns/difference_in_iso_years/index' {
  import {differenceInISOYears} from 'date-fns'
  export = differenceInISOYears
}

declare module 'date-fns/difference_in_milliseconds/index' {
  import {differenceInMilliseconds} from 'date-fns'
  export = differenceInMilliseconds
}

declare module 'date-fns/difference_in_minutes/index' {
  import {differenceInMinutes} from 'date-fns'
  export = differenceInMinutes
}

declare module 'date-fns/difference_in_months/index' {
  import {differenceInMonths} from 'date-fns'
  export = differenceInMonths
}

declare module 'date-fns/difference_in_quarters/index' {
  import {differenceInQuarters} from 'date-fns'
  export = differenceInQuarters
}

declare module 'date-fns/difference_in_seconds/index' {
  import {differenceInSeconds} from 'date-fns'
  export = differenceInSeconds
}

declare module 'date-fns/difference_in_weeks/index' {
  import {differenceInWeeks} from 'date-fns'
  export = differenceInWeeks
}

declare module 'date-fns/difference_in_years/index' {
  import {differenceInYears} from 'date-fns'
  export = differenceInYears
}

declare module 'date-fns/distance_in_words/index' {
  import {distanceInWords} from 'date-fns'
  export = distanceInWords
}

declare module 'date-fns/distance_in_words_strict/index' {
  import {distanceInWordsStrict} from 'date-fns'
  export = distanceInWordsStrict
}

declare module 'date-fns/distance_in_words_to_now/index' {
  import {distanceInWordsToNow} from 'date-fns'
  export = distanceInWordsToNow
}

declare module 'date-fns/each_day/index' {
  import {eachDay} from 'date-fns'
  export = eachDay
}

declare module 'date-fns/end_of_day/index' {
  import {endOfDay} from 'date-fns'
  export = endOfDay
}

declare module 'date-fns/end_of_hour/index' {
  import {endOfHour} from 'date-fns'
  export = endOfHour
}

declare module 'date-fns/end_of_iso_week/index' {
  import {endOfISOWeek} from 'date-fns'
  export = endOfISOWeek
}

declare module 'date-fns/end_of_iso_year/index' {
  import {endOfISOYear} from 'date-fns'
  export = endOfISOYear
}

declare module 'date-fns/end_of_minute/index' {
  import {endOfMinute} from 'date-fns'
  export = endOfMinute
}

declare module 'date-fns/end_of_month/index' {
  import {endOfMonth} from 'date-fns'
  export = endOfMonth
}

declare module 'date-fns/end_of_quarter/index' {
  import {endOfQuarter} from 'date-fns'
  export = endOfQuarter
}

declare module 'date-fns/end_of_second/index' {
  import {endOfSecond} from 'date-fns'
  export = endOfSecond
}

declare module 'date-fns/end_of_today/index' {
  import {endOfToday} from 'date-fns'
  export = endOfToday
}

declare module 'date-fns/end_of_tomorrow/index' {
  import {endOfTomorrow} from 'date-fns'
  export = endOfTomorrow
}

declare module 'date-fns/end_of_week/index' {
  import {endOfWeek} from 'date-fns'
  export = endOfWeek
}

declare module 'date-fns/end_of_year/index' {
  import {endOfYear} from 'date-fns'
  export = endOfYear
}

declare module 'date-fns/end_of_yesterday/index' {
  import {endOfYesterday} from 'date-fns'
  export = endOfYesterday
}

declare module 'date-fns/format/index' {
  import {format} from 'date-fns'
  export = format
}

declare module 'date-fns/get_date/index' {
  import {getDate} from 'date-fns'
  export = getDate
}

declare module 'date-fns/get_day/index' {
  import {getDay} from 'date-fns'
  export = getDay
}

declare module 'date-fns/get_day_of_year/index' {
  import {getDayOfYear} from 'date-fns'
  export = getDayOfYear
}

declare module 'date-fns/get_days_in_month/index' {
  import {getDaysInMonth} from 'date-fns'
  export = getDaysInMonth
}

declare module 'date-fns/get_days_in_year/index' {
  import {getDaysInYear} from 'date-fns'
  export = getDaysInYear
}

declare module 'date-fns/get_hours/index' {
  import {getHours} from 'date-fns'
  export = getHours
}

declare module 'date-fns/get_iso_day/index' {
  import {getISODay} from 'date-fns'
  export = getISODay
}

declare module 'date-fns/get_iso_week/index' {
  import {getISOWeek} from 'date-fns'
  export = getISOWeek
}

declare module 'date-fns/get_iso_weeks_in_year/index' {
  import {getISOWeeksInYear} from 'date-fns'
  export = getISOWeeksInYear
}

declare module 'date-fns/get_iso_year/index' {
  import {getISOYear} from 'date-fns'
  export = getISOYear
}

declare module 'date-fns/get_milliseconds/index' {
  import {getMilliseconds} from 'date-fns'
  export = getMilliseconds
}

declare module 'date-fns/get_minutes/index' {
  import {getMinutes} from 'date-fns'
  export = getMinutes
}

declare module 'date-fns/get_month/index' {
  import {getMonth} from 'date-fns'
  export = getMonth
}

declare module 'date-fns/get_overlapping_days_in_ranges/index' {
  import {getOverlappingDaysInRanges} from 'date-fns'
  export = getOverlappingDaysInRanges
}

declare module 'date-fns/get_quarter/index' {
  import {getQuarter} from 'date-fns'
  export = getQuarter
}

declare module 'date-fns/get_seconds/index' {
  import {getSeconds} from 'date-fns'
  export = getSeconds
}

declare module 'date-fns/get_time/index' {
  import {getTime} from 'date-fns'
  export = getTime
}

declare module 'date-fns/get_year/index' {
  import {getYear} from 'date-fns'
  export = getYear
}

declare module 'date-fns/is_after/index' {
  import {isAfter} from 'date-fns'
  export = isAfter
}

declare module 'date-fns/is_before/index' {
  import {isBefore} from 'date-fns'
  export = isBefore
}

declare module 'date-fns/is_date/index' {
  import {isDate} from 'date-fns'
  export = isDate
}

declare module 'date-fns/is_equal/index' {
  import {isEqual} from 'date-fns'
  export = isEqual
}

declare module 'date-fns/is_first_day_of_month/index' {
  import {isFirstDayOfMonth} from 'date-fns'
  export = isFirstDayOfMonth
}

declare module 'date-fns/is_friday/index' {
  import {isFriday} from 'date-fns'
  export = isFriday
}

declare module 'date-fns/is_future/index' {
  import {isFuture} from 'date-fns'
  export = isFuture
}

declare module 'date-fns/is_last_day_of_month/index' {
  import {isLastDayOfMonth} from 'date-fns'
  export = isLastDayOfMonth
}

declare module 'date-fns/is_leap_year/index' {
  import {isLeapYear} from 'date-fns'
  export = isLeapYear
}

declare module 'date-fns/is_monday/index' {
  import {isMonday} from 'date-fns'
  export = isMonday
}

declare module 'date-fns/is_past/index' {
  import {isPast} from 'date-fns'
  export = isPast
}

declare module 'date-fns/is_same_day/index' {
  import {isSameDay} from 'date-fns'
  export = isSameDay
}

declare module 'date-fns/is_same_hour/index' {
  import {isSameHour} from 'date-fns'
  export = isSameHour
}

declare module 'date-fns/is_same_iso_week/index' {
  import {isSameISOWeek} from 'date-fns'
  export = isSameISOWeek
}

declare module 'date-fns/is_same_iso_year/index' {
  import {isSameISOYear} from 'date-fns'
  export = isSameISOYear
}

declare module 'date-fns/is_same_minute/index' {
  import {isSameMinute} from 'date-fns'
  export = isSameMinute
}

declare module 'date-fns/is_same_month/index' {
  import {isSameMonth} from 'date-fns'
  export = isSameMonth
}

declare module 'date-fns/is_same_quarter/index' {
  import {isSameQuarter} from 'date-fns'
  export = isSameQuarter
}

declare module 'date-fns/is_same_second/index' {
  import {isSameSecond} from 'date-fns'
  export = isSameSecond
}

declare module 'date-fns/is_same_week/index' {
  import {isSameWeek} from 'date-fns'
  export = isSameWeek
}

declare module 'date-fns/is_same_year/index' {
  import {isSameYear} from 'date-fns'
  export = isSameYear
}

declare module 'date-fns/is_saturday/index' {
  import {isSaturday} from 'date-fns'
  export = isSaturday
}

declare module 'date-fns/is_sunday/index' {
  import {isSunday} from 'date-fns'
  export = isSunday
}

declare module 'date-fns/is_this_hour/index' {
  import {isThisHour} from 'date-fns'
  export = isThisHour
}

declare module 'date-fns/is_this_iso_week/index' {
  import {isThisISOWeek} from 'date-fns'
  export = isThisISOWeek
}

declare module 'date-fns/is_this_iso_year/index' {
  import {isThisISOYear} from 'date-fns'
  export = isThisISOYear
}

declare module 'date-fns/is_this_minute/index' {
  import {isThisMinute} from 'date-fns'
  export = isThisMinute
}

declare module 'date-fns/is_this_month/index' {
  import {isThisMonth} from 'date-fns'
  export = isThisMonth
}

declare module 'date-fns/is_this_quarter/index' {
  import {isThisQuarter} from 'date-fns'
  export = isThisQuarter
}

declare module 'date-fns/is_this_second/index' {
  import {isThisSecond} from 'date-fns'
  export = isThisSecond
}

declare module 'date-fns/is_this_week/index' {
  import {isThisWeek} from 'date-fns'
  export = isThisWeek
}

declare module 'date-fns/is_this_year/index' {
  import {isThisYear} from 'date-fns'
  export = isThisYear
}

declare module 'date-fns/is_thursday/index' {
  import {isThursday} from 'date-fns'
  export = isThursday
}

declare module 'date-fns/is_today/index' {
  import {isToday} from 'date-fns'
  export = isToday
}

declare module 'date-fns/is_tomorrow/index' {
  import {isTomorrow} from 'date-fns'
  export = isTomorrow
}

declare module 'date-fns/is_tuesday/index' {
  import {isTuesday} from 'date-fns'
  export = isTuesday
}

declare module 'date-fns/is_valid/index' {
  import {isValid} from 'date-fns'
  export = isValid
}

declare module 'date-fns/is_wednesday/index' {
  import {isWednesday} from 'date-fns'
  export = isWednesday
}

declare module 'date-fns/is_weekend/index' {
  import {isWeekend} from 'date-fns'
  export = isWeekend
}

declare module 'date-fns/is_within_range/index' {
  import {isWithinRange} from 'date-fns'
  export = isWithinRange
}

declare module 'date-fns/is_yesterday/index' {
  import {isYesterday} from 'date-fns'
  export = isYesterday
}

declare module 'date-fns/last_day_of_iso_week/index' {
  import {lastDayOfISOWeek} from 'date-fns'
  export = lastDayOfISOWeek
}

declare module 'date-fns/last_day_of_iso_year/index' {
  import {lastDayOfISOYear} from 'date-fns'
  export = lastDayOfISOYear
}

declare module 'date-fns/last_day_of_month/index' {
  import {lastDayOfMonth} from 'date-fns'
  export = lastDayOfMonth
}

declare module 'date-fns/last_day_of_quarter/index' {
  import {lastDayOfQuarter} from 'date-fns'
  export = lastDayOfQuarter
}

declare module 'date-fns/last_day_of_week/index' {
  import {lastDayOfWeek} from 'date-fns'
  export = lastDayOfWeek
}

declare module 'date-fns/last_day_of_year/index' {
  import {lastDayOfYear} from 'date-fns'
  export = lastDayOfYear
}

declare module 'date-fns/max/index' {
  import {max} from 'date-fns'
  export = max
}

declare module 'date-fns/min/index' {
  import {min} from 'date-fns'
  export = min
}

declare module 'date-fns/parse/index' {
  import {parse} from 'date-fns'
  export = parse
}

declare module 'date-fns/set_date/index' {
  import {setDate} from 'date-fns'
  export = setDate
}

declare module 'date-fns/set_day/index' {
  import {setDay} from 'date-fns'
  export = setDay
}

declare module 'date-fns/set_day_of_year/index' {
  import {setDayOfYear} from 'date-fns'
  export = setDayOfYear
}

declare module 'date-fns/set_hours/index' {
  import {setHours} from 'date-fns'
  export = setHours
}

declare module 'date-fns/set_iso_day/index' {
  import {setISODay} from 'date-fns'
  export = setISODay
}

declare module 'date-fns/set_iso_week/index' {
  import {setISOWeek} from 'date-fns'
  export = setISOWeek
}

declare module 'date-fns/set_iso_year/index' {
  import {setISOYear} from 'date-fns'
  export = setISOYear
}

declare module 'date-fns/set_milliseconds/index' {
  import {setMilliseconds} from 'date-fns'
  export = setMilliseconds
}

declare module 'date-fns/set_minutes/index' {
  import {setMinutes} from 'date-fns'
  export = setMinutes
}

declare module 'date-fns/set_month/index' {
  import {setMonth} from 'date-fns'
  export = setMonth
}

declare module 'date-fns/set_quarter/index' {
  import {setQuarter} from 'date-fns'
  export = setQuarter
}

declare module 'date-fns/set_seconds/index' {
  import {setSeconds} from 'date-fns'
  export = setSeconds
}

declare module 'date-fns/set_year/index' {
  import {setYear} from 'date-fns'
  export = setYear
}

declare module 'date-fns/start_of_day/index' {
  import {startOfDay} from 'date-fns'
  export = startOfDay
}

declare module 'date-fns/start_of_hour/index' {
  import {startOfHour} from 'date-fns'
  export = startOfHour
}

declare module 'date-fns/start_of_iso_week/index' {
  import {startOfISOWeek} from 'date-fns'
  export = startOfISOWeek
}

declare module 'date-fns/start_of_iso_year/index' {
  import {startOfISOYear} from 'date-fns'
  export = startOfISOYear
}

declare module 'date-fns/start_of_minute/index' {
  import {startOfMinute} from 'date-fns'
  export = startOfMinute
}

declare module 'date-fns/start_of_month/index' {
  import {startOfMonth} from 'date-fns'
  export = startOfMonth
}

declare module 'date-fns/start_of_quarter/index' {
  import {startOfQuarter} from 'date-fns'
  export = startOfQuarter
}

declare module 'date-fns/start_of_second/index' {
  import {startOfSecond} from 'date-fns'
  export = startOfSecond
}

declare module 'date-fns/start_of_today/index' {
  import {startOfToday} from 'date-fns'
  export = startOfToday
}

declare module 'date-fns/start_of_tomorrow/index' {
  import {startOfTomorrow} from 'date-fns'
  export = startOfTomorrow
}

declare module 'date-fns/start_of_week/index' {
  import {startOfWeek} from 'date-fns'
  export = startOfWeek
}

declare module 'date-fns/start_of_year/index' {
  import {startOfYear} from 'date-fns'
  export = startOfYear
}

declare module 'date-fns/start_of_yesterday/index' {
  import {startOfYesterday} from 'date-fns'
  export = startOfYesterday
}

declare module 'date-fns/sub_days/index' {
  import {subDays} from 'date-fns'
  export = subDays
}

declare module 'date-fns/sub_hours/index' {
  import {subHours} from 'date-fns'
  export = subHours
}

declare module 'date-fns/sub_iso_years/index' {
  import {subISOYears} from 'date-fns'
  export = subISOYears
}

declare module 'date-fns/sub_milliseconds/index' {
  import {subMilliseconds} from 'date-fns'
  export = subMilliseconds
}

declare module 'date-fns/sub_minutes/index' {
  import {subMinutes} from 'date-fns'
  export = subMinutes
}

declare module 'date-fns/sub_months/index' {
  import {subMonths} from 'date-fns'
  export = subMonths
}

declare module 'date-fns/sub_quarters/index' {
  import {subQuarters} from 'date-fns'
  export = subQuarters
}

declare module 'date-fns/sub_seconds/index' {
  import {subSeconds} from 'date-fns'
  export = subSeconds
}

declare module 'date-fns/sub_weeks/index' {
  import {subWeeks} from 'date-fns'
  export = subWeeks
}

declare module 'date-fns/sub_years/index' {
  import {subYears} from 'date-fns'
  export = subYears
}

declare module 'date-fns/add_days/index.js' {
  import {addDays} from 'date-fns'
  export = addDays
}

declare module 'date-fns/add_hours/index.js' {
  import {addHours} from 'date-fns'
  export = addHours
}

declare module 'date-fns/add_iso_years/index.js' {
  import {addISOYears} from 'date-fns'
  export = addISOYears
}

declare module 'date-fns/add_milliseconds/index.js' {
  import {addMilliseconds} from 'date-fns'
  export = addMilliseconds
}

declare module 'date-fns/add_minutes/index.js' {
  import {addMinutes} from 'date-fns'
  export = addMinutes
}

declare module 'date-fns/add_months/index.js' {
  import {addMonths} from 'date-fns'
  export = addMonths
}

declare module 'date-fns/add_quarters/index.js' {
  import {addQuarters} from 'date-fns'
  export = addQuarters
}

declare module 'date-fns/add_seconds/index.js' {
  import {addSeconds} from 'date-fns'
  export = addSeconds
}

declare module 'date-fns/add_weeks/index.js' {
  import {addWeeks} from 'date-fns'
  export = addWeeks
}

declare module 'date-fns/add_years/index.js' {
  import {addYears} from 'date-fns'
  export = addYears
}

declare module 'date-fns/are_ranges_overlapping/index.js' {
  import {areRangesOverlapping} from 'date-fns'
  export = areRangesOverlapping
}

declare module 'date-fns/closest_index_to/index.js' {
  import {closestIndexTo} from 'date-fns'
  export = closestIndexTo
}

declare module 'date-fns/closest_to/index.js' {
  import {closestTo} from 'date-fns'
  export = closestTo
}

declare module 'date-fns/compare_asc/index.js' {
  import {compareAsc} from 'date-fns'
  export = compareAsc
}

declare module 'date-fns/compare_desc/index.js' {
  import {compareDesc} from 'date-fns'
  export = compareDesc
}

declare module 'date-fns/difference_in_calendar_days/index.js' {
  import {differenceInCalendarDays} from 'date-fns'
  export = differenceInCalendarDays
}

declare module 'date-fns/difference_in_calendar_iso_weeks/index.js' {
  import {differenceInCalendarISOWeeks} from 'date-fns'
  export = differenceInCalendarISOWeeks
}

declare module 'date-fns/difference_in_calendar_iso_years/index.js' {
  import {differenceInCalendarISOYears} from 'date-fns'
  export = differenceInCalendarISOYears
}

declare module 'date-fns/difference_in_calendar_months/index.js' {
  import {differenceInCalendarMonths} from 'date-fns'
  export = differenceInCalendarMonths
}

declare module 'date-fns/difference_in_calendar_quarters/index.js' {
  import {differenceInCalendarQuarters} from 'date-fns'
  export = differenceInCalendarQuarters
}

declare module 'date-fns/difference_in_calendar_weeks/index.js' {
  import {differenceInCalendarWeeks} from 'date-fns'
  export = differenceInCalendarWeeks
}

declare module 'date-fns/difference_in_calendar_years/index.js' {
  import {differenceInCalendarYears} from 'date-fns'
  export = differenceInCalendarYears
}

declare module 'date-fns/difference_in_days/index.js' {
  import {differenceInDays} from 'date-fns'
  export = differenceInDays
}

declare module 'date-fns/difference_in_hours/index.js' {
  import {differenceInHours} from 'date-fns'
  export = differenceInHours
}

declare module 'date-fns/difference_in_iso_years/index.js' {
  import {differenceInISOYears} from 'date-fns'
  export = differenceInISOYears
}

declare module 'date-fns/difference_in_milliseconds/index.js' {
  import {differenceInMilliseconds} from 'date-fns'
  export = differenceInMilliseconds
}

declare module 'date-fns/difference_in_minutes/index.js' {
  import {differenceInMinutes} from 'date-fns'
  export = differenceInMinutes
}

declare module 'date-fns/difference_in_months/index.js' {
  import {differenceInMonths} from 'date-fns'
  export = differenceInMonths
}

declare module 'date-fns/difference_in_quarters/index.js' {
  import {differenceInQuarters} from 'date-fns'
  export = differenceInQuarters
}

declare module 'date-fns/difference_in_seconds/index.js' {
  import {differenceInSeconds} from 'date-fns'
  export = differenceInSeconds
}

declare module 'date-fns/difference_in_weeks/index.js' {
  import {differenceInWeeks} from 'date-fns'
  export = differenceInWeeks
}

declare module 'date-fns/difference_in_years/index.js' {
  import {differenceInYears} from 'date-fns'
  export = differenceInYears
}

declare module 'date-fns/distance_in_words/index.js' {
  import {distanceInWords} from 'date-fns'
  export = distanceInWords
}

declare module 'date-fns/distance_in_words_strict/index.js' {
  import {distanceInWordsStrict} from 'date-fns'
  export = distanceInWordsStrict
}

declare module 'date-fns/distance_in_words_to_now/index.js' {
  import {distanceInWordsToNow} from 'date-fns'
  export = distanceInWordsToNow
}

declare module 'date-fns/each_day/index.js' {
  import {eachDay} from 'date-fns'
  export = eachDay
}

declare module 'date-fns/end_of_day/index.js' {
  import {endOfDay} from 'date-fns'
  export = endOfDay
}

declare module 'date-fns/end_of_hour/index.js' {
  import {endOfHour} from 'date-fns'
  export = endOfHour
}

declare module 'date-fns/end_of_iso_week/index.js' {
  import {endOfISOWeek} from 'date-fns'
  export = endOfISOWeek
}

declare module 'date-fns/end_of_iso_year/index.js' {
  import {endOfISOYear} from 'date-fns'
  export = endOfISOYear
}

declare module 'date-fns/end_of_minute/index.js' {
  import {endOfMinute} from 'date-fns'
  export = endOfMinute
}

declare module 'date-fns/end_of_month/index.js' {
  import {endOfMonth} from 'date-fns'
  export = endOfMonth
}

declare module 'date-fns/end_of_quarter/index.js' {
  import {endOfQuarter} from 'date-fns'
  export = endOfQuarter
}

declare module 'date-fns/end_of_second/index.js' {
  import {endOfSecond} from 'date-fns'
  export = endOfSecond
}

declare module 'date-fns/end_of_today/index.js' {
  import {endOfToday} from 'date-fns'
  export = endOfToday
}

declare module 'date-fns/end_of_tomorrow/index.js' {
  import {endOfTomorrow} from 'date-fns'
  export = endOfTomorrow
}

declare module 'date-fns/end_of_week/index.js' {
  import {endOfWeek} from 'date-fns'
  export = endOfWeek
}

declare module 'date-fns/end_of_year/index.js' {
  import {endOfYear} from 'date-fns'
  export = endOfYear
}

declare module 'date-fns/end_of_yesterday/index.js' {
  import {endOfYesterday} from 'date-fns'
  export = endOfYesterday
}

declare module 'date-fns/format/index.js' {
  import {format} from 'date-fns'
  export = format
}

declare module 'date-fns/get_date/index.js' {
  import {getDate} from 'date-fns'
  export = getDate
}

declare module 'date-fns/get_day/index.js' {
  import {getDay} from 'date-fns'
  export = getDay
}

declare module 'date-fns/get_day_of_year/index.js' {
  import {getDayOfYear} from 'date-fns'
  export = getDayOfYear
}

declare module 'date-fns/get_days_in_month/index.js' {
  import {getDaysInMonth} from 'date-fns'
  export = getDaysInMonth
}

declare module 'date-fns/get_days_in_year/index.js' {
  import {getDaysInYear} from 'date-fns'
  export = getDaysInYear
}

declare module 'date-fns/get_hours/index.js' {
  import {getHours} from 'date-fns'
  export = getHours
}

declare module 'date-fns/get_iso_day/index.js' {
  import {getISODay} from 'date-fns'
  export = getISODay
}

declare module 'date-fns/get_iso_week/index.js' {
  import {getISOWeek} from 'date-fns'
  export = getISOWeek
}

declare module 'date-fns/get_iso_weeks_in_year/index.js' {
  import {getISOWeeksInYear} from 'date-fns'
  export = getISOWeeksInYear
}

declare module 'date-fns/get_iso_year/index.js' {
  import {getISOYear} from 'date-fns'
  export = getISOYear
}

declare module 'date-fns/get_milliseconds/index.js' {
  import {getMilliseconds} from 'date-fns'
  export = getMilliseconds
}

declare module 'date-fns/get_minutes/index.js' {
  import {getMinutes} from 'date-fns'
  export = getMinutes
}

declare module 'date-fns/get_month/index.js' {
  import {getMonth} from 'date-fns'
  export = getMonth
}

declare module 'date-fns/get_overlapping_days_in_ranges/index.js' {
  import {getOverlappingDaysInRanges} from 'date-fns'
  export = getOverlappingDaysInRanges
}

declare module 'date-fns/get_quarter/index.js' {
  import {getQuarter} from 'date-fns'
  export = getQuarter
}

declare module 'date-fns/get_seconds/index.js' {
  import {getSeconds} from 'date-fns'
  export = getSeconds
}

declare module 'date-fns/get_time/index.js' {
  import {getTime} from 'date-fns'
  export = getTime
}

declare module 'date-fns/get_year/index.js' {
  import {getYear} from 'date-fns'
  export = getYear
}

declare module 'date-fns/is_after/index.js' {
  import {isAfter} from 'date-fns'
  export = isAfter
}

declare module 'date-fns/is_before/index.js' {
  import {isBefore} from 'date-fns'
  export = isBefore
}

declare module 'date-fns/is_date/index.js' {
  import {isDate} from 'date-fns'
  export = isDate
}

declare module 'date-fns/is_equal/index.js' {
  import {isEqual} from 'date-fns'
  export = isEqual
}

declare module 'date-fns/is_first_day_of_month/index.js' {
  import {isFirstDayOfMonth} from 'date-fns'
  export = isFirstDayOfMonth
}

declare module 'date-fns/is_friday/index.js' {
  import {isFriday} from 'date-fns'
  export = isFriday
}

declare module 'date-fns/is_future/index.js' {
  import {isFuture} from 'date-fns'
  export = isFuture
}

declare module 'date-fns/is_last_day_of_month/index.js' {
  import {isLastDayOfMonth} from 'date-fns'
  export = isLastDayOfMonth
}

declare module 'date-fns/is_leap_year/index.js' {
  import {isLeapYear} from 'date-fns'
  export = isLeapYear
}

declare module 'date-fns/is_monday/index.js' {
  import {isMonday} from 'date-fns'
  export = isMonday
}

declare module 'date-fns/is_past/index.js' {
  import {isPast} from 'date-fns'
  export = isPast
}

declare module 'date-fns/is_same_day/index.js' {
  import {isSameDay} from 'date-fns'
  export = isSameDay
}

declare module 'date-fns/is_same_hour/index.js' {
  import {isSameHour} from 'date-fns'
  export = isSameHour
}

declare module 'date-fns/is_same_iso_week/index.js' {
  import {isSameISOWeek} from 'date-fns'
  export = isSameISOWeek
}

declare module 'date-fns/is_same_iso_year/index.js' {
  import {isSameISOYear} from 'date-fns'
  export = isSameISOYear
}

declare module 'date-fns/is_same_minute/index.js' {
  import {isSameMinute} from 'date-fns'
  export = isSameMinute
}

declare module 'date-fns/is_same_month/index.js' {
  import {isSameMonth} from 'date-fns'
  export = isSameMonth
}

declare module 'date-fns/is_same_quarter/index.js' {
  import {isSameQuarter} from 'date-fns'
  export = isSameQuarter
}

declare module 'date-fns/is_same_second/index.js' {
  import {isSameSecond} from 'date-fns'
  export = isSameSecond
}

declare module 'date-fns/is_same_week/index.js' {
  import {isSameWeek} from 'date-fns'
  export = isSameWeek
}

declare module 'date-fns/is_same_year/index.js' {
  import {isSameYear} from 'date-fns'
  export = isSameYear
}

declare module 'date-fns/is_saturday/index.js' {
  import {isSaturday} from 'date-fns'
  export = isSaturday
}

declare module 'date-fns/is_sunday/index.js' {
  import {isSunday} from 'date-fns'
  export = isSunday
}

declare module 'date-fns/is_this_hour/index.js' {
  import {isThisHour} from 'date-fns'
  export = isThisHour
}

declare module 'date-fns/is_this_iso_week/index.js' {
  import {isThisISOWeek} from 'date-fns'
  export = isThisISOWeek
}

declare module 'date-fns/is_this_iso_year/index.js' {
  import {isThisISOYear} from 'date-fns'
  export = isThisISOYear
}

declare module 'date-fns/is_this_minute/index.js' {
  import {isThisMinute} from 'date-fns'
  export = isThisMinute
}

declare module 'date-fns/is_this_month/index.js' {
  import {isThisMonth} from 'date-fns'
  export = isThisMonth
}

declare module 'date-fns/is_this_quarter/index.js' {
  import {isThisQuarter} from 'date-fns'
  export = isThisQuarter
}

declare module 'date-fns/is_this_second/index.js' {
  import {isThisSecond} from 'date-fns'
  export = isThisSecond
}

declare module 'date-fns/is_this_week/index.js' {
  import {isThisWeek} from 'date-fns'
  export = isThisWeek
}

declare module 'date-fns/is_this_year/index.js' {
  import {isThisYear} from 'date-fns'
  export = isThisYear
}

declare module 'date-fns/is_thursday/index.js' {
  import {isThursday} from 'date-fns'
  export = isThursday
}

declare module 'date-fns/is_today/index.js' {
  import {isToday} from 'date-fns'
  export = isToday
}

declare module 'date-fns/is_tomorrow/index.js' {
  import {isTomorrow} from 'date-fns'
  export = isTomorrow
}

declare module 'date-fns/is_tuesday/index.js' {
  import {isTuesday} from 'date-fns'
  export = isTuesday
}

declare module 'date-fns/is_valid/index.js' {
  import {isValid} from 'date-fns'
  export = isValid
}

declare module 'date-fns/is_wednesday/index.js' {
  import {isWednesday} from 'date-fns'
  export = isWednesday
}

declare module 'date-fns/is_weekend/index.js' {
  import {isWeekend} from 'date-fns'
  export = isWeekend
}

declare module 'date-fns/is_within_range/index.js' {
  import {isWithinRange} from 'date-fns'
  export = isWithinRange
}

declare module 'date-fns/is_yesterday/index.js' {
  import {isYesterday} from 'date-fns'
  export = isYesterday
}

declare module 'date-fns/last_day_of_iso_week/index.js' {
  import {lastDayOfISOWeek} from 'date-fns'
  export = lastDayOfISOWeek
}

declare module 'date-fns/last_day_of_iso_year/index.js' {
  import {lastDayOfISOYear} from 'date-fns'
  export = lastDayOfISOYear
}

declare module 'date-fns/last_day_of_month/index.js' {
  import {lastDayOfMonth} from 'date-fns'
  export = lastDayOfMonth
}

declare module 'date-fns/last_day_of_quarter/index.js' {
  import {lastDayOfQuarter} from 'date-fns'
  export = lastDayOfQuarter
}

declare module 'date-fns/last_day_of_week/index.js' {
  import {lastDayOfWeek} from 'date-fns'
  export = lastDayOfWeek
}

declare module 'date-fns/last_day_of_year/index.js' {
  import {lastDayOfYear} from 'date-fns'
  export = lastDayOfYear
}

declare module 'date-fns/max/index.js' {
  import {max} from 'date-fns'
  export = max
}

declare module 'date-fns/min/index.js' {
  import {min} from 'date-fns'
  export = min
}

declare module 'date-fns/parse/index.js' {
  import {parse} from 'date-fns'
  export = parse
}

declare module 'date-fns/set_date/index.js' {
  import {setDate} from 'date-fns'
  export = setDate
}

declare module 'date-fns/set_day/index.js' {
  import {setDay} from 'date-fns'
  export = setDay
}

declare module 'date-fns/set_day_of_year/index.js' {
  import {setDayOfYear} from 'date-fns'
  export = setDayOfYear
}

declare module 'date-fns/set_hours/index.js' {
  import {setHours} from 'date-fns'
  export = setHours
}

declare module 'date-fns/set_iso_day/index.js' {
  import {setISODay} from 'date-fns'
  export = setISODay
}

declare module 'date-fns/set_iso_week/index.js' {
  import {setISOWeek} from 'date-fns'
  export = setISOWeek
}

declare module 'date-fns/set_iso_year/index.js' {
  import {setISOYear} from 'date-fns'
  export = setISOYear
}

declare module 'date-fns/set_milliseconds/index.js' {
  import {setMilliseconds} from 'date-fns'
  export = setMilliseconds
}

declare module 'date-fns/set_minutes/index.js' {
  import {setMinutes} from 'date-fns'
  export = setMinutes
}

declare module 'date-fns/set_month/index.js' {
  import {setMonth} from 'date-fns'
  export = setMonth
}

declare module 'date-fns/set_quarter/index.js' {
  import {setQuarter} from 'date-fns'
  export = setQuarter
}

declare module 'date-fns/set_seconds/index.js' {
  import {setSeconds} from 'date-fns'
  export = setSeconds
}

declare module 'date-fns/set_year/index.js' {
  import {setYear} from 'date-fns'
  export = setYear
}

declare module 'date-fns/start_of_day/index.js' {
  import {startOfDay} from 'date-fns'
  export = startOfDay
}

declare module 'date-fns/start_of_hour/index.js' {
  import {startOfHour} from 'date-fns'
  export = startOfHour
}

declare module 'date-fns/start_of_iso_week/index.js' {
  import {startOfISOWeek} from 'date-fns'
  export = startOfISOWeek
}

declare module 'date-fns/start_of_iso_year/index.js' {
  import {startOfISOYear} from 'date-fns'
  export = startOfISOYear
}

declare module 'date-fns/start_of_minute/index.js' {
  import {startOfMinute} from 'date-fns'
  export = startOfMinute
}

declare module 'date-fns/start_of_month/index.js' {
  import {startOfMonth} from 'date-fns'
  export = startOfMonth
}

declare module 'date-fns/start_of_quarter/index.js' {
  import {startOfQuarter} from 'date-fns'
  export = startOfQuarter
}

declare module 'date-fns/start_of_second/index.js' {
  import {startOfSecond} from 'date-fns'
  export = startOfSecond
}

declare module 'date-fns/start_of_today/index.js' {
  import {startOfToday} from 'date-fns'
  export = startOfToday
}

declare module 'date-fns/start_of_tomorrow/index.js' {
  import {startOfTomorrow} from 'date-fns'
  export = startOfTomorrow
}

declare module 'date-fns/start_of_week/index.js' {
  import {startOfWeek} from 'date-fns'
  export = startOfWeek
}

declare module 'date-fns/start_of_year/index.js' {
  import {startOfYear} from 'date-fns'
  export = startOfYear
}

declare module 'date-fns/start_of_yesterday/index.js' {
  import {startOfYesterday} from 'date-fns'
  export = startOfYesterday
}

declare module 'date-fns/sub_days/index.js' {
  import {subDays} from 'date-fns'
  export = subDays
}

declare module 'date-fns/sub_hours/index.js' {
  import {subHours} from 'date-fns'
  export = subHours
}

declare module 'date-fns/sub_iso_years/index.js' {
  import {subISOYears} from 'date-fns'
  export = subISOYears
}

declare module 'date-fns/sub_milliseconds/index.js' {
  import {subMilliseconds} from 'date-fns'
  export = subMilliseconds
}

declare module 'date-fns/sub_minutes/index.js' {
  import {subMinutes} from 'date-fns'
  export = subMinutes
}

declare module 'date-fns/sub_months/index.js' {
  import {subMonths} from 'date-fns'
  export = subMonths
}

declare module 'date-fns/sub_quarters/index.js' {
  import {subQuarters} from 'date-fns'
  export = subQuarters
}

declare module 'date-fns/sub_seconds/index.js' {
  import {subSeconds} from 'date-fns'
  export = subSeconds
}

declare module 'date-fns/sub_weeks/index.js' {
  import {subWeeks} from 'date-fns'
  export = subWeeks
}

declare module 'date-fns/sub_years/index.js' {
  import {subYears} from 'date-fns'
  export = subYears
}

declare module 'date-fns/locale/ar' {}
declare module 'date-fns/locale/be' {}
declare module 'date-fns/locale/bg' {}
declare module 'date-fns/locale/ca' {}
declare module 'date-fns/locale/cs' {}
declare module 'date-fns/locale/da' {}
declare module 'date-fns/locale/de' {}
declare module 'date-fns/locale/el' {}
declare module 'date-fns/locale/en' {}
declare module 'date-fns/locale/eo' {}
declare module 'date-fns/locale/es' {}
declare module 'date-fns/locale/fi' {}
declare module 'date-fns/locale/fil' {}
declare module 'date-fns/locale/fr' {}
declare module 'date-fns/locale/hr' {}
declare module 'date-fns/locale/hu' {}
declare module 'date-fns/locale/id' {}
declare module 'date-fns/locale/is' {}
declare module 'date-fns/locale/it' {}
declare module 'date-fns/locale/ja' {}
declare module 'date-fns/locale/ko' {}
declare module 'date-fns/locale/mk' {}
declare module 'date-fns/locale/nb' {}
declare module 'date-fns/locale/nl' {}
declare module 'date-fns/locale/pl' {}
declare module 'date-fns/locale/pt' {}
declare module 'date-fns/locale/ro' {}
declare module 'date-fns/locale/ru' {}
declare module 'date-fns/locale/sk' {}
declare module 'date-fns/locale/sl' {}
declare module 'date-fns/locale/sr' {}
declare module 'date-fns/locale/sv' {}
declare module 'date-fns/locale/th' {}
declare module 'date-fns/locale/tr' {}
declare module 'date-fns/locale/zh_cn' {}
declare module 'date-fns/locale/zh_tw' {}
declare module 'date-fns/locale/ar/index' {}
declare module 'date-fns/locale/be/index' {}
declare module 'date-fns/locale/bg/index' {}
declare module 'date-fns/locale/ca/index' {}
declare module 'date-fns/locale/cs/index' {}
declare module 'date-fns/locale/da/index' {}
declare module 'date-fns/locale/de/index' {}
declare module 'date-fns/locale/el/index' {}
declare module 'date-fns/locale/en/index' {}
declare module 'date-fns/locale/eo/index' {}
declare module 'date-fns/locale/es/index' {}
declare module 'date-fns/locale/fi/index' {}
declare module 'date-fns/locale/fil/index' {}
declare module 'date-fns/locale/fr/index' {}
declare module 'date-fns/locale/hr/index' {}
declare module 'date-fns/locale/hu/index' {}
declare module 'date-fns/locale/id/index' {}
declare module 'date-fns/locale/is/index' {}
declare module 'date-fns/locale/it/index' {}
declare module 'date-fns/locale/ja/index' {}
declare module 'date-fns/locale/ko/index' {}
declare module 'date-fns/locale/mk/index' {}
declare module 'date-fns/locale/nb/index' {}
declare module 'date-fns/locale/nl/index' {}
declare module 'date-fns/locale/pl/index' {}
declare module 'date-fns/locale/pt/index' {}
declare module 'date-fns/locale/ro/index' {}
declare module 'date-fns/locale/ru/index' {}
declare module 'date-fns/locale/sk/index' {}
declare module 'date-fns/locale/sl/index' {}
declare module 'date-fns/locale/sr/index' {}
declare module 'date-fns/locale/sv/index' {}
declare module 'date-fns/locale/th/index' {}
declare module 'date-fns/locale/tr/index' {}
declare module 'date-fns/locale/zh_cn/index' {}
declare module 'date-fns/locale/zh_tw/index' {}
declare module 'date-fns/locale/ar/index.js' {}
declare module 'date-fns/locale/be/index.js' {}
declare module 'date-fns/locale/bg/index.js' {}
declare module 'date-fns/locale/ca/index.js' {}
declare module 'date-fns/locale/cs/index.js' {}
declare module 'date-fns/locale/da/index.js' {}
declare module 'date-fns/locale/de/index.js' {}
declare module 'date-fns/locale/el/index.js' {}
declare module 'date-fns/locale/en/index.js' {}
declare module 'date-fns/locale/eo/index.js' {}
declare module 'date-fns/locale/es/index.js' {}
declare module 'date-fns/locale/fi/index.js' {}
declare module 'date-fns/locale/fil/index.js' {}
declare module 'date-fns/locale/fr/index.js' {}
declare module 'date-fns/locale/hr/index.js' {}
declare module 'date-fns/locale/hu/index.js' {}
declare module 'date-fns/locale/id/index.js' {}
declare module 'date-fns/locale/is/index.js' {}
declare module 'date-fns/locale/it/index.js' {}
declare module 'date-fns/locale/ja/index.js' {}
declare module 'date-fns/locale/ko/index.js' {}
declare module 'date-fns/locale/mk/index.js' {}
declare module 'date-fns/locale/nb/index.js' {}
declare module 'date-fns/locale/nl/index.js' {}
declare module 'date-fns/locale/pl/index.js' {}
declare module 'date-fns/locale/pt/index.js' {}
declare module 'date-fns/locale/ro/index.js' {}
declare module 'date-fns/locale/ru/index.js' {}
declare module 'date-fns/locale/sk/index.js' {}
declare module 'date-fns/locale/sl/index.js' {}
declare module 'date-fns/locale/sr/index.js' {}
declare module 'date-fns/locale/sv/index.js' {}
declare module 'date-fns/locale/th/index.js' {}
declare module 'date-fns/locale/tr/index.js' {}
declare module 'date-fns/locale/zh_cn/index.js' {}
declare module 'date-fns/locale/zh_tw/index.js' {}
