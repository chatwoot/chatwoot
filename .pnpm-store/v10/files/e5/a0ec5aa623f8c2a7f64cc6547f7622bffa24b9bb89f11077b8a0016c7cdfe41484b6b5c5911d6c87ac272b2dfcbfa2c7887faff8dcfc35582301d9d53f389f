import { CustomScrollBehaviorCallback, Options as BaseOptions, ScrollBehavior } from './types';
export interface StandardBehaviorOptions extends BaseOptions {
    behavior?: ScrollBehavior;
}
export interface CustomBehaviorOptions<T> extends BaseOptions {
    behavior: CustomScrollBehaviorCallback<T>;
}
export interface Options<T = any> extends BaseOptions {
    behavior?: ScrollBehavior | CustomScrollBehaviorCallback<T>;
}
declare function scrollIntoView<T>(target: Element, options: CustomBehaviorOptions<T>): T;
declare function scrollIntoView(target: Element, options?: Options | boolean): void;
export default scrollIntoView;
