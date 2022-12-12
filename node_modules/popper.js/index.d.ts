/**
 * @fileoverview This file only declares the public portions of the API.
 * It should not define internal pieces such as utils or modifier details.
 *
 * Original definitions by: edcarroll <https://github.com/edcarroll>, ggray <https://github.com/giladgray>, rhysd <https://rhysd.github.io>, joscha <https://github.com/joscha>, seckardt <https://github.com/seckardt>, marcfallows <https://github.com/marcfallows>
 */

/**
 * This kind of namespace declaration is not necessary, but is kept here for backwards-compatibility with
 * popper.js 1.x. It can be removed in 2.x so that the default export is simply the Popper class
 * and all the types / interfaces are top-level named exports.
 */
declare namespace Popper {
  export type Position = 'top' | 'right' | 'bottom' | 'left';

  export type Placement = 'auto-start'
    | 'auto'
    | 'auto-end'
    | 'top-start'
    | 'top'
    | 'top-end'
    | 'right-start'
    | 'right'
    | 'right-end'
    | 'bottom-end'
    | 'bottom'
    | 'bottom-start'
    | 'left-end'
    | 'left'
    | 'left-start';

  export type Boundary = 'scrollParent' | 'viewport' | 'window';

  export type Behavior = 'flip' | 'clockwise' | 'counterclockwise';

  export type ModifierFn = (data: Data, options: Object) => Data;

  export interface Attributes {
    'x-out-of-boundaries': '' | false;
    'x-placement': Placement;
  }

  export interface Padding {
    top?: number,
    bottom?: number,
    left?: number,
    right?: number,
  }

  export interface BaseModifier {
    order?: number;
    enabled?: boolean;
    fn?: ModifierFn;
  }

  export interface Modifiers {
    shift?: BaseModifier;
    offset?: BaseModifier & {
      offset?: number | string,
    };
    preventOverflow?: BaseModifier & {
      priority?: Position[],
      padding?: number | Padding,
      boundariesElement?: Boundary | Element,
      escapeWithReference?: boolean
    };
    keepTogether?: BaseModifier;
    arrow?: BaseModifier & {
      element?: string | Element,
    };
    flip?: BaseModifier & {
      behavior?: Behavior | Position[],
      padding?: number | Padding,
      boundariesElement?: Boundary | Element,
      flipVariations?: boolean,
      flipVariationsByContent?: boolean,
    };
    inner?: BaseModifier;
    hide?: BaseModifier;
    applyStyle?: BaseModifier & {
      onLoad?: Function,
      gpuAcceleration?: boolean,
    };
    computeStyle?: BaseModifier & {
      gpuAcceleration?: boolean;
      x?: 'bottom' | 'top',
      y?: 'left' | 'right'
    };

    [name: string]: (BaseModifier & Record<string, any>) | undefined;
  }

  export interface Offset {
    top: number;
    left: number;
    width: number;
    height: number;
  }

  export interface Data {
    instance: Popper;
    placement: Placement;
    originalPlacement: Placement;
    flipped: boolean;
    hide: boolean;
    arrowElement: Element;
    styles: CSSStyleDeclaration;
    arrowStyles: CSSStyleDeclaration;
    attributes: Attributes;
    boundaries: Object;
    offsets: {
      popper: Offset,
      reference: Offset,
      arrow: {
        top: number,
        left: number,
      },
    };
  }

  export interface PopperOptions {
    placement?: Placement;
    positionFixed?: boolean;
    eventsEnabled?: boolean;
    modifiers?: Modifiers;
    removeOnDestroy?: boolean;

    onCreate?(data: Data): void;

    onUpdate?(data: Data): void;
  }

  export interface ReferenceObject {
    clientHeight: number;
    clientWidth: number;
    referenceNode?: Node;

    getBoundingClientRect(): ClientRect;
  }
}

// Re-export types in the Popper namespace so that they can be accessed as top-level named exports.
// These re-exports should be removed in 2.x when the "declare namespace Popper" syntax is removed.
export type Padding = Popper.Padding;
export type Position = Popper.Position;
export type Placement = Popper.Placement;
export type Boundary = Popper.Boundary;
export type Behavior = Popper.Behavior;
export type ModifierFn = Popper.ModifierFn;
export type BaseModifier = Popper.BaseModifier;
export type Modifiers = Popper.Modifiers;
export type Offset = Popper.Offset;
export type Data = Popper.Data;
export type PopperOptions = Popper.PopperOptions;
export type ReferenceObject = Popper.ReferenceObject;

declare class Popper {
  static modifiers: (BaseModifier & { name: string })[];
  static placements: Placement[];
  static Defaults: PopperOptions;

  options: PopperOptions;
  popper: Element;
  reference: Element | ReferenceObject;

  constructor(reference: Element | ReferenceObject, popper: Element, options?: PopperOptions);

  destroy(): void;

  update(): void;

  scheduleUpdate(): void;

  enableEventListeners(): void;

  disableEventListeners(): void;
}

export default Popper;
