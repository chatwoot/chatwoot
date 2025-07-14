import { Client, Scope as ScopeInterface } from '@sentry/types';
import { AsyncContextStrategy } from './types';
interface Layer {
    client?: Client;
    scope: ScopeInterface;
}
/**
 * This is an object that holds a stack of scopes.
 */
export declare class AsyncContextStack {
    private readonly _stack;
    private _isolationScope;
    constructor(scope?: ScopeInterface, isolationScope?: ScopeInterface);
    /**
     * Fork a scope for the stack.
     */
    withScope<T>(callback: (scope: ScopeInterface) => T): T;
    /**
     * Get the client of the stack.
     */
    getClient<C extends Client>(): C | undefined;
    /**
     * Returns the scope of the top stack.
     */
    getScope(): ScopeInterface;
    /**
     * Get the isolation scope for the stack.
     */
    getIsolationScope(): ScopeInterface;
    /**
     * Returns the topmost scope layer in the order domain > local > process.
     */
    getStackTop(): Layer;
    /**
     * Push a scope to the stack.
     */
    private _pushScope;
    /**
     * Pop a scope from the stack.
     */
    private _popScope;
}
/**
 * Get the stack-based async context strategy.
 */
export declare function getStackAsyncContextStrategy(): AsyncContextStrategy;
export {};
//# sourceMappingURL=stackStrategy.d.ts.map
