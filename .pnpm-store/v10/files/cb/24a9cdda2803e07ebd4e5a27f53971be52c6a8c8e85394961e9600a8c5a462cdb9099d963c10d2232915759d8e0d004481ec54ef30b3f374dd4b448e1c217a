// `/custom` export is deprecated.
// Use `/core` sub-package instead.

import {
  MetadataJson,
  Examples,
  PhoneNumber,
  E164Number,
  CountryCallingCode,
  CountryCode,
  CarrierCode,
  NationalNumber,
  Extension,
  ParseError,
  NumberFoundLegacy,
  NumberFound,
  NumberType,
  NumberFormat,
  NumberingPlan
} from './types.d.js';

import {
  ParsedNumber,
  FormatNumberOptions,
  ParseNumberOptions
} from './index.d.js';

export {
  MetadataJson,
  Examples,
  PhoneNumber,
  E164Number,
  CountryCallingCode,
  CountryCode,
  CarrierCode,
  NationalNumber,
  Extension,
  FormatNumberOptions,
  ParsedNumber,
  ParseNumberOptions,
  ParseError,
  NumberFoundLegacy,
  NumberFound,
  NumberFormat,
  NumberType,
  NumberingPlan
};

// `parsePhoneNumber()` named export has been renamed to `parsePhoneNumberWithError()`.
export function parsePhoneNumber(text: string, metadata: MetadataJson): PhoneNumber;
export function parsePhoneNumber(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber;

export function parsePhoneNumberWithError(text: string, metadata: MetadataJson): PhoneNumber;
export function parsePhoneNumberWithError(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber;

// `parsePhoneNumberFromString()` named export is now considered legacy:
// it has been promoted to a default export due to being too verbose.
export function parsePhoneNumberFromString(text: string, metadata: MetadataJson): PhoneNumber;
export function parsePhoneNumberFromString(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber;

export default parsePhoneNumberFromString;

export function getExampleNumber(country: CountryCode, examples: Examples, metadata: MetadataJson): PhoneNumber | undefined;

export function findPhoneNumbersInText(text: string, metadata: MetadataJson): NumberFound[];
export function findPhoneNumbersInText(text: string, options: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extended?: boolean }, metadata: MetadataJson): NumberFound[];

export function searchPhoneNumbersInText(text: string, metadata: MetadataJson): IterableIterator<NumberFound>;
export function searchPhoneNumbersInText(text: string, options: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extended?: boolean }, metadata: MetadataJson): IterableIterator<NumberFound>;

export class PhoneNumberMatcher {
  constructor(text: string, metadata: MetadataJson);
  constructor(text: string, options: { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson);
  hasNext(): boolean;
  next(): NumberFound | undefined;
}

export function getCountries(metadata: MetadataJson): CountryCode[];
export function getCountryCallingCode(countryCode: CountryCode, metadata: MetadataJson): CountryCallingCode;
export function getExtPrefix(countryCode: CountryCode, metadata: MetadataJson): string;
export function isSupportedCountry(countryCode: CountryCode, metadata: MetadataJson): boolean;

export function formatIncompletePhoneNumber(number: string, metadata: MetadataJson): string;
export function formatIncompletePhoneNumber(number: string, defaultCountryCode: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string } | undefined, metadata: MetadataJson): string;
export function parseIncompletePhoneNumber(text: string): string;
export function parsePhoneNumberCharacter(character: string): string;
export function parseDigits(character: string): string;

export class AsYouType {
  constructor(defaultCountryCode: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string } | undefined, metadata: MetadataJson);
  input(text: string): string;
  reset(): void;
  country: CountryCode | undefined;
  getNumber(): PhoneNumber | undefined;
  getNumberValue(): E164Number | undefined;
  getNationalNumber(): string;
  getChars(): string;
  getTemplate(): string;
  getCallingCode(): string | undefined;
  getCountry(): CountryCode | undefined;
  isInternational(): boolean;
  isPossible(): boolean;
  isValid(): boolean;
}

export class Metadata {
  constructor(metadata: MetadataJson);
  selectNumberingPlan(country: CountryCode): void;
  numberingPlan?: NumberingPlan;
}

// Deprecated
export function parse(text: string, metadata: MetadataJson): ParsedNumber;
export function parse(text: string, options: CountryCode | ParseNumberOptions, metadata: MetadataJson): ParsedNumber;

// Deprecated
export function parseNumber(text: string, metadata: MetadataJson): ParsedNumber | {};
export function parseNumber(text: string, options: CountryCode | ParseNumberOptions, metadata: MetadataJson): ParsedNumber | {};

// Deprecated
export function format(parsedNumber: ParsedNumber, format: NumberFormat, metadata: MetadataJson): string;
export function format(phone: string, format: NumberFormat, metadata: MetadataJson): string;
export function format(phone: string, country: CountryCode, format: NumberFormat, metadata: MetadataJson): string;

// Deprecated
export function formatNumber(parsedNumber: ParsedNumber, format: NumberFormat, metadata: MetadataJson): string;
export function formatNumber(parsedNumber: ParsedNumber, format: NumberFormat, options: FormatNumberOptions, metadata: MetadataJson): string;

// Deprecated
export function formatNumber(phone: string, format: NumberFormat, metadata: MetadataJson): string;
export function formatNumber(phone: string, format: NumberFormat, options: FormatNumberOptions, metadata: MetadataJson): string;

// Deprecated
export function formatNumber(phone: string, country: CountryCode, format: NumberFormat, metadata: MetadataJson): string;
export function formatNumber(phone: string, country: CountryCode, format: NumberFormat, options: FormatNumberOptions, metadata: MetadataJson): string;

// Deprecated
export function getNumberType(parsedNumber: ParsedNumber, metadata: MetadataJson): NumberType;
export function getNumberType(phone: string, metadata: MetadataJson): NumberType;
export function getNumberType(phone: string, country: CountryCode, metadata: MetadataJson): NumberType;

// Deprecated
export function isPossibleNumber(parsedNumber: ParsedNumber, metadata: MetadataJson): boolean;
export function isPossibleNumber(phone: string, metadata: MetadataJson): boolean;
export function isPossibleNumber(phone: string, country: CountryCode, metadata: MetadataJson): boolean;

// Deprecated
export function isValidNumber(parsedNumber: ParsedNumber, metadata: MetadataJson): boolean;
export function isValidNumber(phone: string, metadata: MetadataJson): boolean;
export function isValidNumber(phone: string, country: CountryCode, metadata: MetadataJson): boolean;

// Deprecated
export function isValidNumberForRegion(phone: string, country: CountryCode, metadata: MetadataJson): boolean;

// Deprecated
export function findParsedNumbers(text: string, metadata: MetadataJson): NumberFoundLegacy[];
export function findParsedNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode }, metadata: MetadataJson): NumberFoundLegacy[];

// Deprecated
export function searchParsedNumbers(text: string, metadata: MetadataJson): IterableIterator<NumberFoundLegacy>;
export function searchParsedNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode }, metadata: MetadataJson): IterableIterator<NumberFoundLegacy>;

// Deprecated
export class ParsedNumberSearch {
  constructor(text: string, metadata: MetadataJson);
  constructor(text: string, options: { defaultCountry?: CountryCode }, metadata: MetadataJson);
  hasNext(): boolean;
  next(): NumberFoundLegacy | undefined;
}

// Deprecated
export function findNumbers(text: string, metadata: MetadataJson): NumberFoundLegacy[];
export function findNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson): NumberFound[];

// Deprecated
export function searchNumbers(text: string, metadata: MetadataJson): IterableIterator<NumberFoundLegacy>;
export function searchNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson): IterableIterator<NumberFound>;

// Deprecated
export function getPhoneCode(countryCode: CountryCode, metadata: MetadataJson): CountryCallingCode;
