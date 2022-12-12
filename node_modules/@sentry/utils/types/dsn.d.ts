import { DsnComponents, DsnLike } from '@sentry/types';
/**
 * Renders the string representation of this Dsn.
 *
 * By default, this will render the public representation without the password
 * component. To get the deprecated private representation, set `withPassword`
 * to true.
 *
 * @param withPassword When set to true, the password will be included.
 */
export declare function dsnToString(dsn: DsnComponents, withPassword?: boolean): string;
/** The Sentry Dsn, identifying a Sentry instance and project. */
export declare function makeDsn(from: DsnLike): DsnComponents;
//# sourceMappingURL=dsn.d.ts.map