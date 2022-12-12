declare var Intl: any;

declare type Path = string;
declare type Locale = string;
declare type MessageContext = {
  list: (index: number) => mixed,
  named: (key: string) => mixed
}
declare type MessageFunction = (ctx: MessageContext) => string
declare type FallbackLocale = string | string[] | false | { [locale: string]: string[] };
declare type LocaleMessage = string | MessageFunction | LocaleMessageObject | LocaleMessageArray;
declare type LocaleMessageObject = { [key: Path]: LocaleMessage };
declare type LocaleMessageArray = Array<LocaleMessage>;
declare type LocaleMessages = { [key: Locale]: LocaleMessageObject };

// This options is the same as Intl.DateTimeFormat constructor options:
// http://www.ecma-international.org/ecma-402/2.0/#sec-intl-datetimeformat-constructor
declare type DateTimeFormatOptions = {
  year?: 'numeric' | '2-digit',
  month?: 'numeric' | '2-digit' | 'narrow' | 'short' | 'long',
  day?: 'numeric' | '2-digit',
  hour?: 'numeric' | '2-digit',
  minute?: 'numeric' | '2-digit',
  second?: 'numeric' | '2-digit',
  weekday?: 'narrow' | 'short' | 'long',
  hour12?: boolean,
  era?: 'narrow' | 'short' | 'long',
  timeZone?: string, // IANA time zone
  timeZoneName?: 'short' | 'long',
  localeMatcher?: 'lookup' | 'best fit',
  formatMatcher?: 'basic' | 'best fit'
};
declare type DateTimeFormat = { [key: string]: DateTimeFormatOptions };
declare type DateTimeFormats = { [key: Locale]: DateTimeFormat };

// This options is the same as Intl.NumberFormat constructor options:
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat
declare type NumberFormatOptions = {
  style?: 'decimal' | 'currency' | 'percent',
  currency?: string, // ISO 4217 currency codes
  currencyDisplay?: 'symbol' | 'code' | 'name',
  useGrouping?: boolean,
  minimumIntegerDigits?: number,
  minimumFractionDigits?: number,
  maximumFractionDigits?: number,
  minimumSignificantDigits?: number,
  maximumSignificantDigits?: number,
  localeMatcher?: 'lookup' | 'best fit',
  formatMatcher?: 'basic' | 'best fit'
};
declare type NumberFormat = { [key: string]: NumberFormatOptions };
declare type NumberFormats = { [key: Locale]: NumberFormat };
declare type Modifiers = { [key: string]: (str: string) => string };

declare type TranslateResult = string | LocaleMessages;
declare type DateTimeFormatResult = string;
declare type NumberFormatResult = string;
declare type MissingHandler = (locale: Locale, key: Path, vm?: any) => string | void;
declare type PostTranslationHandler = (str: string, key?: string) => string;
declare type GetChoiceIndex = (choice: number, choicesLength: number) => number
declare type ComponentInstanceCreatedListener = (newI18n: I18n, rootI18n: I18n) => void;

declare type FormattedNumberPartType = 'currency' | 'decimal' | 'fraction' | 'group' | 'infinity' | 'integer' | 'literal' | 'minusSign' | 'nan' | 'plusSign' | 'percentSign';
declare type FormattedNumberPart = {
  type: FormattedNumberPartType,
  value: string,
};
// This array is the same as Intl.NumberFormat.formatToParts() return value:
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat/formatToParts#Return_value
declare type NumberFormatToPartsResult = Array<FormattedNumberPart>;

declare type WarnHtmlInMessageLevel = 'off' | 'warn' | 'error';

declare type I18nOptions = {
  locale?: Locale,
  fallbackLocale?: FallbackLocale,
  messages?: LocaleMessages,
  dateTimeFormats?: DateTimeFormats,
  numberFormats?: NumberFormats,
  formatter?: Formatter,
  missing?: MissingHandler,
  modifiers?: Modifiers,
  root?: I18n, // for internal
  fallbackRoot?: boolean,
  formatFallbackMessages?: boolean,
  sync?: boolean,
  silentTranslationWarn?: boolean | RegExp,
  silentFallbackWarn?: boolean | RegExp,
  pluralizationRules?: PluralizationRules,
  preserveDirectiveContent?: boolean,
  warnHtmlInMessage?: WarnHtmlInMessageLevel,
  sharedMessages?: LocaleMessage,
  postTranslation?: PostTranslationHandler,
  componentInstanceCreatedListener?: ComponentInstanceCreatedListener,
  escapeParameterHtml?: boolean,
};

declare type IntlAvailability = {
  dateTimeFormat: boolean,
  numberFormat: boolean
};

declare type PluralizationRules = {
  [lang: string]: GetChoiceIndex,
}

declare interface I18n {
  static install: () => void, // for Vue plugin interface
  static version: string,
  static availabilities: IntlAvailability,
  get vm (): any, // for internal
  get locale (): Locale,
  set locale (locale: Locale): void,
  get fallbackLocale (): FallbackLocale,
  set fallbackLocale (locale: FallbackLocale): void,
  get messages (): LocaleMessages,
  get dateTimeFormats (): DateTimeFormats,
  get numberFormats (): NumberFormats,
  get availableLocales (): Locale[],
  get missing (): ?MissingHandler,
  set missing (handler: MissingHandler): void,
  get formatter (): Formatter,
  set formatter (formatter: Formatter): void,
  get formatFallbackMessages (): boolean,
  set formatFallbackMessages (fallback: boolean): void,
  get silentTranslationWarn (): boolean | RegExp,
  set silentTranslationWarn (silent: boolean | RegExp): void,
  get silentFallbackWarn (): boolean | RegExp,
  set silentFallbackWarn (slient: boolean | RegExp): void,
  get pluralizationRules (): PluralizationRules,
  set pluralizationRules (rules: PluralizationRules): void,
  get preserveDirectiveContent (): boolean,
  set preserveDirectiveContent (preserve: boolean): void,
  get warnHtmlInMessage (): WarnHtmlInMessageLevel,
  set warnHtmlInMessage (level: WarnHtmlInMessageLevel): void,
  get postTranslation (): ?PostTranslationHandler,
  set postTranslation (handler: PostTranslationHandler): void,

  getLocaleMessage (locale: Locale): LocaleMessageObject,
  setLocaleMessage (locale: Locale, message: LocaleMessageObject): void,
  mergeLocaleMessage (locale: Locale, message: LocaleMessageObject): void,
  t (key: Path, ...values: any): TranslateResult,
  i (key: Path, locale: Locale, values: Object): TranslateResult,
  tc (key: Path, choice?: number, ...values: any): TranslateResult,
  te (key: Path, locale?: Locale): boolean,
  getDateTimeFormat (locale: Locale): DateTimeFormat,
  setDateTimeFormat (locale: Locale, format: DateTimeFormat): void,
  mergeDateTimeFormat (locale: Locale, format: DateTimeFormat): void,
  d (value: number | Date, ...args: any): DateTimeFormatResult,
  getNumberFormat (locale: Locale): NumberFormat,
  setNumberFormat (locale: Locale, format: NumberFormat): void,
  mergeNumberFormat (locale: Locale, format: NumberFormat): void,
  n (value: number, ...args: any): NumberFormatResult,
  getChoiceIndex: GetChoiceIndex,
  pluralizationRules: PluralizationRules,
  preserveDirectiveContent: boolean
};

declare interface Formatter {
  interpolate (message: string, values: any, path: string): (Array<any> | null)
};
