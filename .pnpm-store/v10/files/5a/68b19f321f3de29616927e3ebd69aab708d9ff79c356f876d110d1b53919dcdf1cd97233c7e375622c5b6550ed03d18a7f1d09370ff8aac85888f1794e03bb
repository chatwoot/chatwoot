import { Emitter } from '../emitter';
/**
 * @internal
 */
export declare const ON_REMOVE_FROM_FUTURE = "onRemoveFromFuture";
interface QueueItem {
    id: string;
}
export declare class PriorityQueue<Item extends QueueItem = QueueItem> extends Emitter {
    protected future: Item[];
    protected queue: Item[];
    protected seen: Record<string, number>;
    maxAttempts: number;
    constructor(maxAttempts: number, queue: Item[], seen?: Record<string, number>);
    push(...items: Item[]): boolean[];
    pushWithBackoff(item: Item): boolean;
    getAttempts(item: Item): number;
    updateAttempts(item: Item): number;
    includes(item: Item): boolean;
    pop(): Item | undefined;
    get length(): number;
    get todo(): number;
}
export {};
//# sourceMappingURL=index.d.ts.map