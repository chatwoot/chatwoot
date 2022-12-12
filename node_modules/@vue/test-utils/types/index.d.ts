import Vue, { VNodeData, ComponentOptions, FunctionalComponentOptions, Component, RenderContext } from 'vue'
import { DefaultProps, PropsDefinition } from 'vue/types/options'
import { ExtendedVue, CombinedVueInstance } from 'vue/types/vue'

/**
 * Utility type to declare an extended Vue constructor
 */
type VueClass<V extends Vue> = (new (...args: any[]) => V) & typeof Vue

/**
 * Utility type for a selector
 */
type Selector = string | Component

/**
 * Utility type for slots
 */
type Slots = {
  [key: string]: (Component | string)[] | Component | string
}

/**
 * Utility type for stubs which can be a string of template as a shorthand
 * If it is an array of string, the specified children are replaced by blank components
 */
type Stubs = {
  [key: string]: Component | string | boolean
} | string[]

/**
 * Utility type for ref options object that can be used as a Selector
 */
type RefSelector = {
  ref: string
}

/**
 * Utility type for name options object that can be used as a Selector
 */
type NameSelector = {
  name: string
}

/**
 * Base class of Wrapper and WrapperArray
 * It has common methods on both Wrapper and WrapperArray
 */
interface BaseWrapper {
  contains (selector: Selector): boolean
  exists (): boolean
  isVisible (): boolean

  attributes(): { [name: string]: string }
  attributes(key: string): string | void
  classes(): Array<string>
  classes(className: string): boolean
  props(): { [name: string]: any }
  props(key: string): any | void
  overview(): void

  is (selector: Selector): boolean
  isEmpty (): boolean
  isVueInstance (): boolean

  setData (data: object): Promise<void> | void
  setMethods (data: object): void
  setProps (props: object): Promise<void> | void

  setValue (value: any): Promise<void> | void
  setChecked (checked?: boolean): Promise<void> | void
  setSelected (): Promise<void> | void

  trigger (eventName: string, options?: object): Promise<void> | void
  destroy (): void
  selector: Selector | void
}

export interface Wrapper<V extends Vue | null> extends BaseWrapper {
  readonly vm: V
  readonly element: HTMLElement
  readonly options: WrapperOptions

  get<R extends Vue> (selector: VueClass<R>): Wrapper<R>
  get<R extends Vue> (selector: ComponentOptions<R>): Wrapper<R>
  get<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): Wrapper<Vue>
  get (selector: string): Wrapper<Vue>
  get (selector: RefSelector): Wrapper<Vue>
  get (selector: NameSelector): Wrapper<Vue>

  getComponent<R extends Vue> (selector: VueClass<R>): Wrapper<R>
  getComponent<R extends Vue> (selector: ComponentOptions<R>): Wrapper<R>
  getComponent<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): Wrapper<Vue>
  getComponent (selector: RefSelector): Wrapper<Vue>
  getComponent (selector: NameSelector): Wrapper<Vue>

  find<R extends Vue> (selector: VueClass<R>): Wrapper<R>
  find<R extends Vue> (selector: ComponentOptions<R>): Wrapper<R>
  find<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): Wrapper<Vue>
  find (selector: string): Wrapper<Vue>
  find (selector: RefSelector): Wrapper<Vue>
  find (selector: NameSelector): Wrapper<Vue>

  findAll<R extends Vue> (selector: VueClass<R>): WrapperArray<R>
  findAll<R extends Vue> (selector: ComponentOptions<R>): WrapperArray<R>
  findAll<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): WrapperArray<Vue>
  findAll (selector: string): WrapperArray<Vue>
  findAll (selector: RefSelector): WrapperArray<Vue>
  findAll (selector: NameSelector): WrapperArray<Vue>

  findComponent<R extends Vue> (selector: VueClass<R>): Wrapper<R>
  findComponent<R extends Vue> (selector: ComponentOptions<R>): Wrapper<R>
  findComponent<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): Wrapper<Vue>
  findComponent (selector: RefSelector): Wrapper<Vue>
  findComponent (selector: NameSelector): Wrapper<Vue>

  findAllComponents<R extends Vue> (selector: VueClass<R>): WrapperArray<R>
  findAllComponents<R extends Vue> (selector: ComponentOptions<R>): WrapperArray<R>
  findAllComponents<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(selector: FunctionalComponentOptions<Props, PropDefs>): WrapperArray<Vue>
  findAllComponents(selector: RefSelector): WrapperArray<Vue>
  findAllComponents(selector: NameSelector): WrapperArray<Vue>

  html (): string
  text (): string
  name (): string

  emitted (): { [name: string]: Array<Array<any>>|undefined }
  emitted (event: string): Array<any>|undefined
  emittedByOrder (): Array<{ name: string, args: Array<any> }>
}

export interface WrapperArray<V extends Vue> extends BaseWrapper {
  readonly length: number;
  readonly wrappers: Array<Wrapper<V>>;

  at(index: number): Wrapper<V>;
  filter(
    predicate: (
      value: Wrapper<V>,
      index: number,
      array: Wrapper<V>[]
    ) => any
  ): WrapperArray<Vue>;
}

interface WrapperOptions {
  attachedToDocument?: boolean
}

interface MountOptions<V extends Vue> extends ComponentOptions<V> {
  attachToDocument?: boolean
  attachTo?: Element | string
  context?: VNodeData
  localVue?: typeof Vue
  mocks?: object | false
  parentComponent?: Component
  slots?: Slots
  scopedSlots?: Record<string, string | Function>
  stubs?: Stubs | false,
  attrs?: Record<string, string>
  listeners?: Record<string, Function | Function[]>
}

type ThisTypedMountOptions<V extends Vue> = MountOptions<V> & ThisType<V>

interface FunctionalComponentMountOptions<V extends Vue> extends MountOptions<V> {
  context?: Partial<RenderContext>
}

type ShallowMountOptions<V extends Vue> = MountOptions<V>

type ThisTypedShallowMountOptions<V extends Vue> = ShallowMountOptions<V> & ThisType<V>

interface FunctionalComponentShallowMountOptions<V extends Vue> extends ShallowMountOptions<V> {
  context?: Partial<RenderContext>
}

interface VueTestUtilsConfigOptions {
  stubs: Record<string, Component | boolean | string>
  mocks: Record<string, any>
  methods: Record<string, Function>
  provide?: Record<string, any>,
  showDeprecationWarnings?: boolean
  deprecationWarningHandler?: Function
}

export declare function createLocalVue (): typeof Vue
export declare let config: VueTestUtilsConfigOptions

export declare function mount<V extends Vue> (component: VueClass<V>, options?: ThisTypedMountOptions<V>): Wrapper<V>
export declare function mount<V extends Vue> (component: ComponentOptions<V>, options?: ThisTypedMountOptions<V>): Wrapper<V>
export declare function mount<V extends Vue, Data, Methods, Computed, Props> (component: ExtendedVue<V, Data, Methods, Computed, Props>, options?: ThisTypedMountOptions<V>): Wrapper<CombinedVueInstance<V, Data, Methods, Computed, Props> & Vue>
export declare function mount<Props = DefaultProps, PropDefs = PropsDefinition<Props>> (component: FunctionalComponentOptions<Props, PropDefs>, options?: MountOptions<Vue>): Wrapper<Vue>
export declare function mount<V extends Vue, Props = DefaultProps> (component: ExtendedVue<V, {}, {}, {}, Props>, options?: FunctionalComponentMountOptions<V>): Wrapper<CombinedVueInstance<V, {}, {}, {}, Props> & Vue>

export declare function shallowMount<V extends Vue> (component: VueClass<V>, options?: ThisTypedShallowMountOptions<V>): Wrapper<V>
export declare function shallowMount<V extends Vue> (component: ComponentOptions<V>, options?: ThisTypedShallowMountOptions<V>): Wrapper<V>
export declare function shallowMount<V extends Vue, Data, Methods, Computed, Props> (component: ExtendedVue<V, Data, Methods, Computed, Props>, options?: ThisTypedShallowMountOptions<V>): Wrapper<CombinedVueInstance<V, Data, Methods, Computed, Props> & Vue>
export declare function shallowMount<Props = DefaultProps, PropDefs = PropsDefinition<Props>>(component: FunctionalComponentOptions<Props, PropDefs>, options?: ShallowMountOptions<Vue>): Wrapper<Vue>
export declare function shallowMount<V extends Vue, Props = DefaultProps> (component: ExtendedVue<V, {}, {}, {}, Props>, options?: FunctionalComponentShallowMountOptions<V>): Wrapper<CombinedVueInstance<V, {}, {}, {}, Props> & Vue>

export declare function createWrapper(node: Vue, options?: WrapperOptions): Wrapper<Vue>
export declare function createWrapper(node: HTMLElement, options?: WrapperOptions): Wrapper<null>

export declare function enableAutoDestroy(hook: (...args: any[]) => any): void
export declare function resetAutoDestroyState(hook: (...args: any[]) => any): void

export declare let RouterLinkStub: VueClass<Vue>
