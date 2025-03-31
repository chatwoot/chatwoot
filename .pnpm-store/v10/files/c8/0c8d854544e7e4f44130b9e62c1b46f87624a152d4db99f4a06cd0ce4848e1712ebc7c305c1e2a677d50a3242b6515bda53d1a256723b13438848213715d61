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
  NumberingPlan,
  ValidatePhoneNumberLengthResult
} from '../types.d.js';

// They say this re-export is required.
// https://github.com/catamphetamine/libphonenumber-js/pull/290#issuecomment-453281180
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
  ParseError,
  NumberFoundLegacy,
  NumberFound,
  NumberType,
  NumberFormat,
  NumberingPlan,
  ValidatePhoneNumberLengthResult
};

// `parsePhoneNumber()` named export has been renamed to `parsePhoneNumberWithError()`.
export function parsePhoneNumber(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }): PhoneNumber;

export function parsePhoneNumberWithError(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }): PhoneNumber;

// `parsePhoneNumberFromString()` named export is now considered legacy:
// it has been promoted to a default export due to being too verbose.
export function parsePhoneNumberFromString(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }): PhoneNumber | undefined;

export default parsePhoneNumberFromString;

export function isValidPhoneNumber(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }): boolean;
export function isPossiblePhoneNumber(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }): boolean;
export function validatePhoneNumberLength(text: string, defaultCountry?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }): ValidatePhoneNumberLengthResult | undefined;

export function findNumbers(text: string, options?: CountryCode): NumberFoundLegacy[];
export function searchNumbers(text: string, options?: CountryCode): IterableIterator<NumberFoundLegacy>;

export function findNumbers(text: string, options?: { defaultCountry?: CountryCode, v2: true }): NumberFound[];
export function searchNumbers(text: string, options?: { defaultCountry?: CountryCode, v2: true }): IterableIterator<NumberFound>;

export function findPhoneNumbersInText(text: string, options?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extended?: boolean }): NumberFound[];
export function searchPhoneNumbersInText(text: string, options?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extended?: boolean }): IterableIterator<NumberFound>;

export class PhoneNumberMatcher {
  constructor(text: string, options?: { defaultCountry?: CountryCode, v2: true });
  hasNext(): boolean;
  next(): NumberFound | undefined;
}

export function isSupportedCountry(countryCode: string): countryCode is CountryCode;
export function getCountries(): CountryCode[];
export function getCountryCallingCode(countryCode: CountryCode): CountryCallingCode;
export function getExtPrefix(countryCode: CountryCode): string;

export function getExampleNumber(country: CountryCode, examples: Examples): PhoneNumber | undefined;

export function formatIncompletePhoneNumber(number: string, defaultCountryCode?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }): string;
export function parseIncompletePhoneNumber(text: string): string;
export function parsePhoneNumberCharacter(character: string): string;
export function parseDigits(character: string): string;

export class AsYouType {
  constructor(defaultCountryCode?: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string });
  input(text: string): string;
  reset(): void;
  getNumber(): PhoneNumber | undefined;
  getNumberValue(): E164Number | undefined;
  getChars(): string;
  getTemplate(): string;
  getCallingCode(): string | undefined;
  getCountry(): CountryCode | undefined;
  isInternational(): boolean;
  isPossible(): boolean;
  isValid(): boolean;
}

export class Metadata {
  constructor();
  selectNumberingPlan(country: CountryCode): void;
  numberingPlan?: NumberingPlan;
}