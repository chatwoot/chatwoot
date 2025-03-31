export type ScrollBehavior = 'auto' | 'smooth';
export type ScrollLogicalPosition = 'start' | 'center' | 'end' | 'nearest';
export type ScrollMode = 'always' | 'if-needed';
export type SkipOverflowHiddenElements = boolean;
export interface Options {
    block?: ScrollLogicalPosition;
    inline?: ScrollLogicalPosition;
    scrollMode?: ScrollMode;
    boundary?: CustomScrollBoundary;
    skipOverflowHiddenElements?: SkipOverflowHiddenElements;
}
export type CustomScrollBoundaryCallback = (parent: Element) => boolean;
export type CustomScrollBoundary = Element | CustomScrollBoundaryCallback | null;
export interface CustomScrollAction {
    el: Element;
    top: number;
    left: number;
}
export type CustomScrollBehaviorCallback<T> = (actions: CustomScrollAction[]) => T;
