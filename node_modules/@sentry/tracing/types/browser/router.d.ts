import { Transaction, TransactionContext } from '@sentry/types';
/**
 * Default function implementing pageload and navigation transactions
 */
export declare function instrumentRoutingWithDefaults<T extends Transaction>(customStartTransaction: (context: TransactionContext) => T | undefined, startTransactionOnPageLoad?: boolean, startTransactionOnLocationChange?: boolean): void;
//# sourceMappingURL=router.d.ts.map