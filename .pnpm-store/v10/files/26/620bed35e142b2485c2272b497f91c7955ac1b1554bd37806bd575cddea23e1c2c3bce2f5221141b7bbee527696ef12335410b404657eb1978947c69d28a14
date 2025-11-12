type ScrollLogicalPosition = 'start' | 'center' | 'end' | 'nearest';
type ScrollMode = 'always' | 'if-needed';
type SkipOverflowHiddenElements = boolean;
interface Options {
    block?: ScrollLogicalPosition;
    inline?: ScrollLogicalPosition;
    scrollMode?: ScrollMode;
    boundary?: CustomScrollBoundary;
    skipOverflowHiddenElements?: SkipOverflowHiddenElements;
}
type CustomScrollBoundaryCallback = (parent: Element) => boolean;
type CustomScrollBoundary = Element | CustomScrollBoundaryCallback | null;
interface CustomScrollAction {
    el: Element;
    top: number;
    left: number;
}
declare const _default: (target: Element, options: Options) => CustomScrollAction[];
export default _default;
