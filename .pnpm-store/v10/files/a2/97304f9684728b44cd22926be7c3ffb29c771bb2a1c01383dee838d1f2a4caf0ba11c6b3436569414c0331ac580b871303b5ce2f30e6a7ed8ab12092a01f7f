import { FormKitNode, FormKitEventListener } from '@formkit/core';

/**
 * FormKit Observer is a utility to wrap a FormKitNode in a dependency tracking observer proxy.
 *
 * @packageDocumentation
 */

/**
 * An API-compatible FormKitNode that is able to determine the full dependency
 * tree of nodes and their values.
 * @public
 */
interface FormKitObservedNode extends FormKitNode {
    _node: FormKitNode;
    deps: FormKitDependencies;
    kill: () => undefined;
    observe: () => void;
    receipts: FormKitObserverReceipts;
    stopObserve: () => FormKitDependencies;
    watch: <T extends FormKitWatchable>(block: T, after?: (value: ReturnType<T>) => void, pos?: 'push' | 'unshift') => void;
}
/**
 * The dependent nodes and the events that are required to watch for changes.
 *
 * @public
 */
type FormKitDependencies = Map<FormKitNode, Set<string>> & {
    active?: boolean;
};
/**
 * A Map of nodes with the values being Maps of eventsName: receipt
 *
 * @public
 */
type FormKitObserverReceipts = Map<FormKitNode, {
    [index: string]: string[];
}>;
/**
 * A callback to watch for nodes.
 * @public
 */
interface FormKitWatchable<T = unknown> {
    (node: FormKitObservedNode): T;
}
/**
 * Creates the observer.
 * @param node - The {@link @formkit/core#FormKitNode | FormKitNode} to observe.
 * @param dependencies - The dependent nodes and the events that are required to
 * watch for changes.
 * @returns Returns a {@link @formkit/observer#FormKitObservedNode | FormKitObservedNode}.
 * @public
 */
declare function createObserver(node: FormKitNode, dependencies?: FormKitDependencies): FormKitObservedNode;
/**
 * Given two maps (`toAdd` and `toRemove`), apply the dependencies as event
 * listeners on the underlying nodes.
 * @param node - The node to apply dependencies to.
 * @param deps - A tuple of toAdd and toRemove FormKitDependencies maps.
 * @param callback - The callback to add or remove.
 * @internal
 */
declare function applyListeners(node: FormKitObservedNode, [toAdd, toRemove]: [FormKitDependencies, FormKitDependencies], callback: FormKitEventListener, pos?: 'unshift' | 'push'): void;
/**
 * Remove all the receipts from the observed node and subtree.
 * @param receipts - The FormKit observer receipts to remove.
 * @public
 */
declare function removeListeners(receipts: FormKitObserverReceipts): void;
/**
 * Determines which nodes should be added as dependencies and which should be
 * removed.
 * @param previous - The previous watcher dependencies.
 * @param current - The new/current watcher dependencies.
 * @returns A tuple of maps: `toAdd` and `toRemove`.
 * @public
 */
declare function diffDeps(previous: FormKitDependencies, current: FormKitDependencies): [FormKitDependencies, FormKitDependencies];
/**
 * Checks if the given node is revoked.
 * @param node - Any observed node to check.
 * @returns A `boolean` indicating if the node is revoked.
 * @public
 */
declare function isKilled(node: FormKitNode | FormKitObservedNode): boolean;

export { type FormKitDependencies, type FormKitObservedNode, type FormKitObserverReceipts, type FormKitWatchable, applyListeners, createObserver, diffDeps, isKilled, removeListeners };
