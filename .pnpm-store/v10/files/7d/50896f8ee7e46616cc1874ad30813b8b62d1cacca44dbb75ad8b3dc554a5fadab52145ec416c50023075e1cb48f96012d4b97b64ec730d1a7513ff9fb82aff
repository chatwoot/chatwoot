import { FormKitHandlerPayload } from '@formkit/core';

/**
 * Catalog of the error message codes in FormKit.
 * @public
 */
declare const errors: Record<string | number, string | ((error: FormKitHandlerPayload) => string)>;
/**
 * Catalog of the warning message codes in FormKit.
 * @public
 */
declare const warnings: Record<string | number, string | ((error: FormKitHandlerPayload) => string)>;
/**
 * Register the dev handler (idempotent).
 *
 * @public
 */
declare function register(): void;

export { errors, register, warnings };
