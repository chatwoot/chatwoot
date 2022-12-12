import { HooksContext, applyHooks, useMemo, useCallback, useRef, useState, useReducer, useEffect, useChannel, useStoryContext, useParameter, useArgs, useGlobals } from '@storybook/addons';
export { HooksContext, applyHooks, useMemo, useCallback, useRef, useState, useReducer, useEffect, useChannel, useStoryContext, useParameter, useArgs, useGlobals, };
export declare function useSharedState<S>(sharedId: string, defaultState?: S): [S, (s: S) => void];
export declare function useAddonState<S>(addonId: string, defaultState?: S): [S, (s: S) => void];
