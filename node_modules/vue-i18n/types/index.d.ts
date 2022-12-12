import Vue, { PluginFunction } from 'vue';

declare namespace VueI18n {
  type Path = string;
  type Locale = string;
  type FallbackLocale = string | string[] | false | { [locale: string]: string[] }
  type Values = any[] | { [key: string]: any };
  type Choice = number;
  interface MessageContext {
    list(index: number): unknown
    named(key: string): unknown
  }
  type MessageFunction = (ctx: MessageContext) => string;
  type LocaleMessage = string | MessageFunction | LocaleMessageObject | LocaleMessageArray;
  interface LocaleMessageObject { [key: string]: LocaleMessage; }
  interface LocaleMessageArray { [index: number]: LocaleMessage; }
  interface LocaleMessages { [key: string]: LocaleMessageObject; }
  type TranslateResult = string | LocaleMessages;

  type LocaleMatcher = 'lookup' | 'best fit';
  type FormatMatcher = 'basic' | 'best fit';

  type DateTimeHumanReadable = 'long' | 'short' | 'narrow';
  type DateTimeDigital = 'numeric' | '2-digit';

  interface SpecificDateTimeFormatOptions extends Intl.DateTimeFormatOptions {
    year?: DateTimeDigital;
    month?: DateTimeDigital | DateTimeHumanReadable;
    day?: DateTimeDigital;
    hour?: DateTimeDigital;
    minute?: DateTimeDigital;
    second?: DateTimeDigital;
    weekday?: DateTimeHumanReadable;
    era?: DateTimeHumanReadable;
    timeZoneName?: 'long' | 'short';
    localeMatcher?: LocaleMatcher;
    formatMatcher?: FormatMatcher;
  }

  type DateTimeFormatOptions = Intl.DateTimeFormatOptions | SpecificDateTimeFormatOptions;

  interface DateTimeFormat { [key: string]: DateTimeFormatOptions; }
  interface DateTimeFormats { [locale: string]: DateTimeFormat; }
  type DateTimeFormatResult = string;

  type CurrencyDisplay = 'symbol' | 'code' | 'name';

  interface SpecificNumberFormatOptions extends Intl.NumberFormatOptions {
    style?: 'decimal' | 'percent';
    currency?: string;
    currencyDisplay?: CurrencyDisplay;
    localeMatcher?: LocaleMatcher;
    formatMatcher?: FormatMatcher;
  }

  interface CurrencyNumberFormatOptions extends Intl.NumberFormatOptions {
    style: 'currency';
    currency: string; // Obligatory if style is 'currency'
    currencyDisplay?: CurrencyDisplay;
    localeMatcher?: LocaleMatcher;
    formatMatcher?: FormatMatcher;
  }

  type NumberFormatOptions = Intl.NumberFormatOptions | SpecificNumberFormatOptions | CurrencyNumberFormatOptions;

  interface NumberFormat { [key: string]: NumberFormatOptions; }
  interface NumberFormats { [locale: string]: NumberFormat; }
  type NumberFormatResult = string;
  type PluralizationRulesMap = {
    /**
     * @param choice {number} a choice index given by the input to $tc: `$tc('path.to.rule', choiceIndex)`
     * @param choicesLength {number} an overall amount of available choices
     * @returns a final choice index
    */
    [lang: string]: (choice: number, choicesLength: number) => number;
  };
  type Modifiers = { [key: string]: (str : string) => string };

  type FormattedNumberPartType = 'currency' | 'decimal' | 'fraction' | 'group' | 'infinity' | 'integer' | 'literal' | 'minusSign' | 'nan' | 'plusSign' | 'percentSign';

  type WarnHtmlInMessageLevel = 'off' | 'warn' | 'error';

  interface FormattedNumberPart {
    type: FormattedNumberPartType;
    value: string;
  }
  interface NumberFormatToPartsResult { [index: number]: FormattedNumberPart; }

  interface Formatter {
    interpolate(message: string, values: Values | undefined, path: string): (any[] | null);
  }

  type MissingHandler = (locale: Locale, key: Path, vm: Vue | null, values: any) => string | void;
  type PostTranslationHandler = (str: string, key?: string) => string;
  type ComponentInstanceCreatedListener = (newVm: VueI18n & IVueI18n, rootVm: VueI18n & IVueI18n) => void;

  interface IntlAvailability {
    dateTimeFormat: boolean;
    numberFormat: boolean;
  }

  // tslint:disable-next-line:interface-name
  interface I18nOptions {
    locale?: Locale;
    fallbackLocale?: FallbackLocale;
    messages?: LocaleMessages;
    dateTimeFormats?: DateTimeFormats;
    numberFormats?: NumberFormats;
    formatter?: Formatter;
    modifiers?: Modifiers,
    missing?: MissingHandler;
    fallbackRoot?: boolean;
    formatFallbackMessages?: boolean;
    sync?: boolean;
    silentTranslationWarn?: boolean | RegExp;
    silentFallbackWarn?: boolean | RegExp;
    preserveDirectiveContent?: boolean;
    pluralizationRules?: PluralizationRulesMap;
    warnHtmlInMessage?: WarnHtmlInMessageLevel;
    sharedMessages?: LocaleMessages;
    postTranslation?: PostTranslationHandler;
    componentInstanceCreatedListener?: ComponentInstanceCreatedListener;
    escapeParameterHtml?: boolean;
  }
}

export type Path = VueI18n.Path;
export type Locale = VueI18n.Locale;
export type FallbackLocale = VueI18n.FallbackLocale;
export type Values = VueI18n.Values;
export type Choice = VueI18n.Choice;
export type MessageContext = VueI18n.MessageContext;
export type MessageFunction = VueI18n.MessageFunction;
export type LocaleMessage = VueI18n.LocaleMessage;
export type LocaleMessageObject = VueI18n.LocaleMessageObject;
export type LocaleMessageArray = VueI18n.LocaleMessageArray;
export type LocaleMessages = VueI18n.LocaleMessages;
export type TranslateResult = VueI18n.TranslateResult;
export type DateTimeFormatOptions = VueI18n.DateTimeFormatOptions;
export type DateTimeFormat = VueI18n.DateTimeFormat;
export type DateTimeFormats = VueI18n.DateTimeFormats;
export type DateTimeFormatResult = VueI18n.DateTimeFormatResult;
export type NumberFormatOptions = VueI18n.NumberFormatOptions;
export type NumberFormat = VueI18n.NumberFormat;
export type NumberFormats = VueI18n.NumberFormats;
export type NumberFormatResult = VueI18n.NumberFormatResult;
export type NumberFormatToPartsResult = VueI18n.NumberFormatToPartsResult;
export type WarnHtmlInMessageLevel = VueI18n.WarnHtmlInMessageLevel;
export type Formatter = VueI18n.Formatter;
export type MissingHandler = VueI18n.MissingHandler;
export type PostTranslationHandler = VueI18n.PostTranslationHandler;
export type IntlAvailability = VueI18n.IntlAvailability;
export type I18nOptions = VueI18n.I18nOptions;

export declare interface IVueI18n {
  readonly messages: VueI18n.LocaleMessages;
  readonly dateTimeFormats: VueI18n.DateTimeFormats;
  readonly numberFormats: VueI18n.NumberFormats;

  locale: VueI18n.Locale;
  fallbackLocale: VueI18n.FallbackLocale;
  missing: VueI18n.MissingHandler;
  formatter: VueI18n.Formatter;
  formatFallbackMessages: boolean;
  silentTranslationWarn: boolean | RegExp;
  silentFallbackWarn: boolean | RegExp;
  preserveDirectiveContent: boolean;
  pluralizationRules: VueI18n.PluralizationRulesMap;
  warnHtmlInMessage: VueI18n.WarnHtmlInMessageLevel;
  postTranslation: VueI18n.PostTranslationHandler;
  t(key: VueI18n.Path, values?: VueI18n.Values): VueI18n.TranslateResult;
  t(key: VueI18n.Path, locale: VueI18n.Locale, values?: VueI18n.Values): VueI18n.TranslateResult;
  tc(key: VueI18n.Path, choice?: VueI18n.Choice, values?: VueI18n.Values): string;
  tc(
    key: VueI18n.Path,
    choice: VueI18n.Choice,
    locale: VueI18n.Locale,
    values?: VueI18n.Values,
  ): string;
  te(key: VueI18n.Path, locale?: VueI18n.Locale): boolean;
  d(
    value: number | Date,
    key?: VueI18n.Path,
    locale?: VueI18n.Locale,
  ): VueI18n.DateTimeFormatResult;
  d(value: number | Date, args?: { [key: string]: string }): VueI18n.DateTimeFormatResult;
  d(value: number | Date, options?: VueI18n.DateTimeFormatOptions): VueI18n.DateTimeFormatResult;
  n(value: number, key?: VueI18n.Path, locale?: VueI18n.Locale): VueI18n.NumberFormatResult;
  n(value: number, args?: { [key: string]: string }): VueI18n.NumberFormatResult;
  n(value: number, options?: VueI18n.NumberFormatOptions): VueI18n.NumberFormatResult;
  getLocaleMessage(locale: VueI18n.Locale): VueI18n.LocaleMessageObject;
  setLocaleMessage(locale: VueI18n.Locale, message: VueI18n.LocaleMessageObject): void;
  mergeLocaleMessage(locale: VueI18n.Locale, message: VueI18n.LocaleMessageObject): void;
  getDateTimeFormat(locale: VueI18n.Locale): VueI18n.DateTimeFormat;
  setDateTimeFormat(locale: VueI18n.Locale, format: VueI18n.DateTimeFormat): void;
  mergeDateTimeFormat(locale: VueI18n.Locale, format: VueI18n.DateTimeFormat): void;
  getNumberFormat(locale: VueI18n.Locale): VueI18n.NumberFormat;
  setNumberFormat(locale: VueI18n.Locale, format: VueI18n.NumberFormat): void;
  mergeNumberFormat(locale: VueI18n.Locale, format: VueI18n.NumberFormat): void;
  getChoiceIndex: (choice: number, choicesLength: number) => number;
}

declare class VueI18n {
  constructor(options?: VueI18n.I18nOptions)

  readonly messages: VueI18n.LocaleMessages;
  readonly dateTimeFormats: VueI18n.DateTimeFormats;
  readonly numberFormats: VueI18n.NumberFormats;
  readonly availableLocales: VueI18n.Locale[];

  locale: VueI18n.Locale;
  fallbackLocale: VueI18n.FallbackLocale;
  missing: VueI18n.MissingHandler;
  formatter: VueI18n.Formatter;
  formatFallbackMessages: boolean;
  silentTranslationWarn: boolean | RegExp;
  silentFallbackWarn: boolean | RegExp;
  preserveDirectiveContent: boolean;
  pluralizationRules: VueI18n.PluralizationRulesMap;
  warnHtmlInMessage: VueI18n.WarnHtmlInMessageLevel;
  postTranslation: VueI18n.PostTranslationHandler;

  t(key: VueI18n.Path, values?: VueI18n.Values): VueI18n.TranslateResult;
  t(key: VueI18n.Path, locale: VueI18n.Locale, values?: VueI18n.Values): VueI18n.TranslateResult;
  tc(key: VueI18n.Path, choice?: VueI18n.Choice, values?: VueI18n.Values): string;
  tc(key: VueI18n.Path, choice: VueI18n.Choice, locale: VueI18n.Locale, values?: VueI18n.Values): string;
  te(key: VueI18n.Path, locale?: VueI18n.Locale): boolean;
  d(value: number | Date, key?: VueI18n.Path, locale?: VueI18n.Locale): VueI18n.DateTimeFormatResult;
  d(value: number | Date, args?: { [key: string]: string }): VueI18n.DateTimeFormatResult;
  d(value: number | Date, options?: VueI18n.DateTimeFormatOptions): VueI18n.DateTimeFormatResult;  
  n(value: number, key?: VueI18n.Path, locale?: VueI18n.Locale): VueI18n.NumberFormatResult;
  n(value: number, args?: { [key: string]: string }): VueI18n.NumberFormatResult;
  n(value: number, options?: VueI18n.NumberFormatOptions): VueI18n.NumberFormatResult;

  getLocaleMessage(locale: VueI18n.Locale): VueI18n.LocaleMessageObject;
  setLocaleMessage(locale: VueI18n.Locale, message: VueI18n.LocaleMessageObject): void;
  mergeLocaleMessage(locale: VueI18n.Locale, message: VueI18n.LocaleMessageObject): void;

  getDateTimeFormat(locale: VueI18n.Locale): VueI18n.DateTimeFormat;
  setDateTimeFormat(locale: VueI18n.Locale, format: VueI18n.DateTimeFormat): void;
  mergeDateTimeFormat(locale: VueI18n.Locale, format: VueI18n.DateTimeFormat): void;

  getNumberFormat(locale: VueI18n.Locale): VueI18n.NumberFormat;
  setNumberFormat(locale: VueI18n.Locale, format: VueI18n.NumberFormat): void;
  mergeNumberFormat(locale: VueI18n.Locale, format: VueI18n.NumberFormat): void;

  /**
   * @param choice {number} a choice index given by the input to $tc: `$tc('path.to.rule', choiceIndex)`
   * @param choicesLength {number} an overall amount of available choices
   * @returns a final choice index
  */
  getChoiceIndex: (choice: number, choicesLength: number) => number;

  static install: PluginFunction<never>;
  static version: string;
  static availabilities: VueI18n.IntlAvailability;
}

declare module 'vue/types/vue' {
  interface Vue {
    readonly $i18n: VueI18n & IVueI18n;
    $t: typeof VueI18n.prototype.t;
    $tc: typeof VueI18n.prototype.tc;
    $te: typeof VueI18n.prototype.te;
    $d: typeof VueI18n.prototype.d;
    $n: typeof VueI18n.prototype.n;
  }
}

declare module 'vue/types/options' {
  interface ComponentOptions<V extends Vue> {
    i18n?: {
      messages?: VueI18n.LocaleMessages;
      dateTimeFormats?: VueI18n.DateTimeFormats;
      numberFormats?: VueI18n.NumberFormats;
      sharedMessages?: VueI18n.LocaleMessages;
    };
  }
}

export default VueI18n;
