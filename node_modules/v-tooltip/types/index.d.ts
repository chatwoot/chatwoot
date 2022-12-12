import Vue, { VueConstructor, DirectiveOptions, PluginFunction } from 'vue';

interface DelayConfig {
  show?: number
  hide?: number
}

export interface GlobalVTooltipOptions {
  /**
   * Default tooltip placement relative to target element
   * @default 'top'
   */
  defaultPlacement: string

  /**
   * Default CSS classes applied to the tooltip element
   * @default 'vue-tooltip-theme'
   */
  defaultClass: string

  /**
   * Default CSS classes applied to the target element of the tooltip
   * @default 'has-tooltip'
   */
  defaultTargetClass: string

  /**
   * Is the content HTML by default?
   * @default true
   */
  defaultHtml: boolean

  /**
   * Default HTML template of the tooltip element
   * It must include `tooltip-arrow` & `tooltip-inner` CSS classes (can be configured, see below)
   * Change if the classes conflict with other libraries (for example bootstrap)
   * @default '<div class="tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
   */
  defaultTemplate: string

  /**
   * Selector used to get the arrow element in the tooltip template
   * @default '.tooltip-arrow, .tooltip__arrow'
   */
  defaultArrowSelector: string

  /**
   * Selector used to get the inner content element in the tooltip template
   * @default '.tooltip-inner, .tooltip__inner'
   */
  defaultInnerSelector: string

  /**
   * Delay (ms)
   * @default 0
   */
  defaultDelay: number | DelayConfig

  /**
   * Default events that trigger the tooltip
   * @default 'hover focus'
   */
  defaultTrigger: string

  /**
   * Default position offset (px)
   * @default 0
   */
  defaultOffset: number | string

  /**
   * Default container where the tooltip will be appended
   * @default 'body'
   */
  defaultContainer: string | HTMLElement | false

  defaultBoundariesElement: string | HTMLElement

  defaultPopperOptions: any

  /**
   * Class added when content is loading
   * @default 'tooltip-loading'
   */
  defaultLoadingClass: string

  /**
   * Displayed when tooltip content is loading
   * @default '...'
   */
  defaultLoadingContent: string

  /**
   * Hide on mouseover tooltip
   * @default true
   */
  autoHide: boolean

  /**
   * Close tooltip on click on tooltip target?
   * @default true
   */
  defaultHideOnTargetClick: boolean

  /**
   * Auto destroy tooltip DOM nodes (ms)
   * @default 5000
   */
  disposeTimeout: number

  /**
   * Options for popover
   */
  popover: Partial<GlobalVTooltipPopoverOptions>
}

export interface GlobalVTooltipPopoverOptions {
  /**
   * @default 'bottom'
   */
  defaultPlacement: string,

  /**
   * Use the `popoverClass` prop for theming
   * @default 'vue-popover-theme'
   */
  defaultClass: string,

  /**
   * Base class (change if conflicts with other libraries)
   * @default 'tooltip popover'
   */
  defaultBaseClass: string,

  /**
   * Wrapper class (contains arrow and inner)
   * @default 'wrapper'
   */
  defaultWrapperClass: string,

  /**
   * Inner content class
   * @default 'tooltip-inner popover-inner'
   */
  defaultInnerClass: string,

  /**
   * Arrow class
   * @default 'tooltip-arrow popover-arrow'
   */
  defaultArrowClass: string,

  /**
   * Class added when popover is open
   * @default 'open'
   */
  defaultOpenClass: string,

  /**
   * @default 0
   */
  defaultDelay: number | DelayConfig,

  /**
   * @default 'click'
   */
  defaultTrigger: string,

  /**
   * @default 0
   */
  defaultOffset: number | string,

  /**
   * @default 'body'
   */
  defaultContainer: string | HTMLElement | false,

  defaultBoundariesElement: string | HTMLElement,

  defaultPopperOptions: any,

  /**
   * Hides if clicked outside of popover
   * @default true
   */
  defaultAutoHide: boolean,

  /**
   * Update popper on content resize
   * @default true
   */
  defaultHandleResize: boolean,
}

export interface GlobalVTooltip {
  enabled?: boolean
  options?: Partial<GlobalVTooltipOptions>
}

declare const vToolTip: PluginFunction<Partial<GlobalVTooltipOptions>> & GlobalVTooltip;
export default vToolTip;

export const VPopover: VueConstructor<Vue>;
export const VClosePopover: DirectiveOptions;
export const VTooltip: DirectiveOptions;