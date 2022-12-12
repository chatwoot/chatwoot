import { popperGenerator, detectOverflow } from "./@popperjs-core-lib-createPopper";
export * from "./@popperjs-core-lib-types";
declare const defaultModifiers: (import("./@popperjs-core-lib-modifiers-popperOffsets").PopperOffsetsModifier | import("./@popperjs-core-lib-modifiers-eventListeners").EventListenersModifier | import("./@popperjs-core-lib-modifiers-computeStyles").ComputeStylesModifier | import("./@popperjs-core-lib-modifiers-applyStyles").ApplyStylesModifier)[];
declare const createPopper: <TModifier extends Partial<import("./@popperjs-core-lib-types").Modifier<any, any>>>(reference: Element | import("./@popperjs-core-lib-types").VirtualElement, popper: HTMLElement, options?: Partial<import("./@popperjs-core-lib-types").OptionsGeneric<TModifier>>) => import("./@popperjs-core-lib-types").Instance;
export { createPopper, popperGenerator, defaultModifiers, detectOverflow };
