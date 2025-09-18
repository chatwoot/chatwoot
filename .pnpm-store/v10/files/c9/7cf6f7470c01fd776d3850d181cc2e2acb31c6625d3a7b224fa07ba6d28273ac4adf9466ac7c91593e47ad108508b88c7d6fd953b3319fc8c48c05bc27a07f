import {
  ValidationRuleWithoutParams,
  ValidationRuleWithParams,
  ValidationRule,
  ValidationArgs
} from '@vuelidate/core';
import { Ref } from 'vue-demi';

// Rules
export const alpha: ValidationRuleWithoutParams;
export const alphaNum: ValidationRuleWithoutParams;
export const and: <T = unknown>(
  ...validators: ValidationRule<T>[]
) => ValidationRuleWithoutParams;
export const between: (
  min: number | Ref<number>,
  max: number | Ref<number>
) => ValidationRuleWithParams<{ min: number, max: number }>;
export const decimal: ValidationRuleWithoutParams;
export const email: ValidationRuleWithoutParams;
export const integer: ValidationRuleWithoutParams;
export const ipAddress: ValidationRuleWithoutParams;
export const macAddress: (separator: string | Ref<string>) => ValidationRuleWithoutParams;
export const maxLength: (
  max: number | Ref<number>
) => ValidationRuleWithParams<{ max: number }>;
export const maxValue: (
  max: number | Ref<number> | string | Ref<string>
) => ValidationRuleWithParams<{ max: number }>;
export const minLength: (
  min: number | Ref<number>
) => ValidationRuleWithParams<{ min: number }>;
export const minValue: (
  min: number | Ref<number> | string | Ref<string>
) => ValidationRuleWithParams<{ min: number }>;
export const not: <T = unknown>(validator: ValidationRule<T>) => ValidationRuleWithoutParams;
export const numeric: ValidationRuleWithoutParams;
export const or: <T = unknown>(
  ...validators: ValidationRule<T>[]
) => ValidationRuleWithoutParams;
export const required: ValidationRuleWithoutParams;
export const requiredIf: (prop: boolean | Ref<boolean> | string | (() => boolean | Promise<boolean>)) => ValidationRuleWithoutParams;
export const requiredUnless: (prop: boolean | Ref<boolean> | string | (() => boolean | Promise<boolean>)) => ValidationRuleWithoutParams;
export const sameAs: <E = unknown>(
  equalTo: E | Ref<E>,
  otherName?: string
) => ValidationRuleWithParams<{ equalTo: E, otherName: string }>;
export const url: ValidationRuleWithoutParams;
export const helpers: {
  withParams: <T = unknown>(params: object, validator: ValidationRule<T>) => ValidationRuleWithParams
  withMessage: <T = unknown>(message: string | ((params: MessageProps) => string), validator: ValidationRule<T>) => ValidationRuleWithParams
  req: Function
  len: Function
  regex: Function
  unwrap: Function
  withAsync: Function,
  forEach: (validators: ValidationArgs) => { $validator: ValidationRule, $message: () => string }
}

export function TranslationFunction(path: string, params: { model: string, property: string, [key: string]: any }): string

export function messagePathFactory(params: MessageProps): string;

export interface MessageParams {
  model: unknown;
  property: string;
  invalid: boolean;
  pending: boolean;
  propertyPath: string;
  response: unknown;
  validator: string;
  [key: string]: any;
}

export function messageParamsFactory(params: MessageParams): MessageParams;

export interface MessageProps {
  $model: string;
  $property: string;
  $params: { [attr: string] : any };
  $validator: string;
  $pending: boolean;
  $invalid: boolean;
  $response: unknown;
  $propertyPath: string;
}

export type ValidatorWrapper = (...args: any[]) => ValidationRule ;

declare function withI18nMessage <T extends (ValidationRule | ValidatorWrapper)>(
  validator: T,
  options?: {
    withArguments?: boolean,
    messagePath?: typeof messagePathFactory,
    messageParams?: typeof messageParamsFactory,
  }): T

export function createI18nMessage({ t, messagePath, messageParams }: {
  t: typeof TranslationFunction;
  messagePath?: typeof messagePathFactory;
  messageParams?: typeof messageParamsFactory;
}): typeof withI18nMessage

