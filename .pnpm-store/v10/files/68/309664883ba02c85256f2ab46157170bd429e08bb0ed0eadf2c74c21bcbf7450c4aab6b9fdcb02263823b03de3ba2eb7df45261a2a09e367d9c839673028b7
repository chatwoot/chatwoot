interface Interaction {
    id: number;
    latency: number;
    entries: PerformanceEventTiming[];
}
interface EntryPreProcessingHook {
    (entry: PerformanceEventTiming): void;
}
export declare const longestInteractionList: Interaction[];
export declare const longestInteractionMap: Map<number, Interaction>;
export declare const DEFAULT_DURATION_THRESHOLD = 40;
export declare const resetInteractions: () => void;
/**
 * Returns the estimated p98 longest interaction based on the stored
 * interaction candidates and the interaction count for the current page.
 */
export declare const estimateP98LongestInteraction: () => Interaction;
/**
 * A list of callback functions to run before each entry is processed.
 * Exposing this list allows the attribution build to hook into the
 * entry processing pipeline.
 */
export declare const entryPreProcessingCallbacks: EntryPreProcessingHook[];
/**
 * Takes a performance entry and adds it to the list of worst interactions
 * if its duration is long enough to make it among the worst. If the
 * entry is part of an existing interaction, it is merged and the latency
 * and entries list is updated as needed.
 */
export declare const processInteractionEntry: (entry: PerformanceEventTiming) => void;
export {};
