import { Transaction, TransactionContext } from '@sentry/types';
export declare type VueRouterInstrumentation = <T extends Transaction>(startTransaction: (context: TransactionContext) => T | undefined, startTransactionOnPageLoad?: boolean, startTransactionOnLocationChange?: boolean) => void;
declare type Route = {
    params: any;
    query: any;
    name?: any;
    path: any;
    matched: any[];
};
interface VueRouter {
    onError: (fn: (err: Error) => void) => void;
    beforeEach: (fn: (to: Route, from: Route, next: () => void) => void) => void;
}
/**
 * Creates routing instrumentation for Vue Router v2
 *
 * @param router The Vue Router instance that is used
 */
export declare function vueRouterInstrumentation(router: VueRouter): VueRouterInstrumentation;
export {};
//# sourceMappingURL=router.d.ts.map