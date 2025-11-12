import { Ref } from 'vue';
/**
 * Support placement as directive modifier
 */
export declare function getPlacement(options: any, modifiers: any): any;
export declare function getOptions(el: any, value: any, modifiers: any): any;
export declare function createTooltip(el: any, value: any, modifiers: any): {
    options: any;
    item: {
        id: number;
        options: any;
        shown: Ref<boolean>;
    };
    show(): void;
    hide(): void;
};
export declare function destroyTooltip(el: any): void;
export declare function bind(el: any, { value, modifiers }: {
    value: any;
    modifiers: any;
}): void;
declare const _default: {
    beforeMount: typeof bind;
    updated: typeof bind;
    beforeUnmount(el: any): void;
};
export default _default;
