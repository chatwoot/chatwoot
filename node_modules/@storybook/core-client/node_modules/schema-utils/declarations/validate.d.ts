export type JSONSchema4 = import("json-schema").JSONSchema4;
export type JSONSchema6 = import("json-schema").JSONSchema6;
export type JSONSchema7 = import("json-schema").JSONSchema7;
export type ErrorObject = import("ajv").ErrorObject;
export type Extend = {
  formatMinimum?: number | undefined;
  formatMaximum?: number | undefined;
  formatExclusiveMinimum?: boolean | undefined;
  formatExclusiveMaximum?: boolean | undefined;
  link?: string | undefined;
};
export type Schema = (JSONSchema4 | JSONSchema6 | JSONSchema7) & Extend;
export type SchemaUtilErrorObject = ErrorObject & {
  children?: Array<ErrorObject>;
};
export type PostFormatter = (
  formattedError: string,
  error: SchemaUtilErrorObject
) => string;
export type ValidationErrorConfiguration = {
  name?: string | undefined;
  baseDataPath?: string | undefined;
  postFormatter?: PostFormatter | undefined;
};
/**
 * @param {Schema} schema
 * @param {Array<object> | object} options
 * @param {ValidationErrorConfiguration=} configuration
 * @returns {void}
 */
export function validate(
  schema: Schema,
  options: Array<object> | object,
  configuration?: ValidationErrorConfiguration | undefined
): void;
import ValidationError from "./ValidationError";
export { ValidationError };
