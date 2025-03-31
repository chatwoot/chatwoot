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
} from '../types.d.cjs';

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
export function parsePhoneNumber(text: string, metadata: MetadataJson): PhoneNumber;
export function parsePhoneNumber(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber;

export function parsePhoneNumberWithError(text: string, metadata: MetadataJson): PhoneNumber;
export function parsePhoneNumberWithError(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber;

// `parsePhoneNumberFromString()` named export is now considered legacy:
// it has been promoted to a default export due to being too verbose.
export function parsePhoneNumberFromString(text: string, metadata: MetadataJson): PhoneNumber | undefined;
export function parsePhoneNumberFromString(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string, extract?: boolean }, metadata: MetadataJson): PhoneNumber | undefined;

export default parsePhoneNumberFromString;

export function isValidPhoneNumber(text: string, metadata: MetadataJson): boolean;
export function isValidPhoneNumber(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }, metadata: MetadataJson): boolean;

export function isPossiblePhoneNumber(text: string, metadata: MetadataJson): boolean;
export function isPossiblePhoneNumber(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }, metadata: MetadataJson): boolean;

export function validatePhoneNumberLength(text: string, metadata: MetadataJson): ValidatePhoneNumberLengthResult | undefined;
export function validatePhoneNumberLength(text: string, defaultCountry: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string }, metadata: MetadataJson): ValidatePhoneNumberLengthResult | undefined;

export function findNumbers(text: string, metadata: MetadataJson): NumberFoundLegacy[];
export function findNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson): NumberFound[];

export function searchNumbers(text: string, metadata: MetadataJson): IterableIterator<NumberFoundLegacy>;
export function searchNumbers(text: string, options: CountryCode | { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson): IterableIterator<NumberFound>;

export function findPhoneNumbersInText(text: string, options: CountryCode | { defaultCountry?: CountryCode, extended?: boolean }, metadata: MetadataJson): NumberFound[];
export function findPhoneNumbersInText(text: string, metadata: MetadataJson): NumberFound[];

export function searchPhoneNumbersInText(text: string, options: CountryCode | { defaultCountry?: CountryCode, extended?: boolean }, metadata: MetadataJson): IterableIterator<NumberFound>;
export function searchPhoneNumbersInText(text: string, metadata: MetadataJson): IterableIterator<NumberFound>;

export class PhoneNumberMatcher {
  constructor(text: string, metadata: MetadataJson);
  constructor(text: string, options: { defaultCountry?: CountryCode, v2: true }, metadata: MetadataJson);
  hasNext(): boolean;
  next(): NumberFound | undefined;
}

export function isSupportedCountry(countryCode: CountryCode, metadata: MetadataJson): boolean;
export function getCountries(metadata: MetadataJson): CountryCode[];
export function getCountryCallingCode(countryCode: CountryCode, metadata: MetadataJson): CountryCallingCode;
export function getExtPrefix(countryCode: CountryCode, metadata: MetadataJson): string;

export function getExampleNumber(country: CountryCode, examples: Examples, metadata: MetadataJson): PhoneNumber | undefined;

export function formatIncompletePhoneNumber(number: string, metadata: MetadataJson): string;
export function formatIncompletePhoneNumber(number: string, defaultCountryCode: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string } | undefined, metadata: MetadataJson): string;
export function parseIncompletePhoneNumber(text: string): string;
export function parsePhoneNumberCharacter(character: string): string;
export function parseDigits(character: string): string;

export class AsYouType {
  constructor(defaultCountryCode: CountryCode | { defaultCountry?: CountryCode, defaultCallingCode?: string } | undefined, metadata: MetadataJson);
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
  constructor(metadata: MetadataJson);
  selectNumberingPlan(country: CountryCode): void;
  numberingPlan?: NumberingPlan;
}