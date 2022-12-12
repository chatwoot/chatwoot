import type { AnyFramework, DecoratorApplicator, StoryContext, StoryId, Args } from '@storybook/csf';
interface Hook {
    name: string;
    memoizedState?: any;
    deps?: any[] | undefined;
}
interface Effect {
    create: () => (() => void) | void;
    destroy?: (() => void) | void;
}
declare type AbstractFunction = (...args: any[]) => any;
export declare class HooksContext<TFramework extends AnyFramework> {
    hookListsMap: WeakMap<AbstractFunction, Hook[]>;
    mountedDecorators: Set<AbstractFunction>;
    prevMountedDecorators: Set<AbstractFunction>;
    currentHooks: Hook[];
    nextHookIndex: number;
    currentPhase: 'MOUNT' | 'UPDATE' | 'NONE';
    currentEffects: Effect[];
    prevEffects: Effect[];
    currentDecoratorName: string | null;
    hasUpdates: boolean;
    currentContext: StoryContext<TFramework> | null;
    renderListener: (storyId: StoryId) => void;
    constructor();
    init(): void;
    clean(): void;
    getNextHook(): Hook;
    triggerEffects(): void;
    addRenderListeners(): void;
    removeRenderListeners(): void;
}
export declare const applyHooks: <TFramework extends AnyFramework>(applyDecorators: DecoratorApplicator<TFramework, Args>) => DecoratorApplicator<TFramework, Args>;
export declare function useMemo<T>(nextCreate: () => T, deps?: any[]): T;
export declare function useCallback<T>(callback: T, deps?: any[]): T;
export declare function useRef<T>(initialValue: T): {
    current: T;
};
export declare function useState<S>(initialState: (() => S) | S): [S, (update: ((prevState: S) => S) | S) => void];
export declare function useReducer<S, A>(reducer: (state: S, action: A) => S, initialState: S): [S, (action: A) => void];
export declare function useReducer<S, I, A>(reducer: (state: S, action: A) => S, initialArg: I, init: (initialArg: I) => S): [S, (action: A) => void];
export declare function useEffect(create: () => (() => void) | void, deps?: any[]): void;
export interface Listener {
    (...args: any[]): void;
}
export interface EventMap {
    [eventId: string]: Listener;
}
export declare function useChannel(eventMap: EventMap, deps?: any[]): any;
export declare function useStoryContext<TFramework extends AnyFramework>(): StoryContext<TFramework>;
export declare function useParameter<S>(parameterKey: string, defaultValue?: S): S | undefined;
export declare function useArgs(): [Args, (newArgs: Args) => void, (argNames?: [string]) => void];
export declare function useGlobals(): [Args, (newGlobals: Args) => void];
export {};
