declare module 'vuedraggable' {
  import Vue, { VueConstructor } from 'vue';

  type CombinedVueInstance<
    Instance extends Vue,
    Data,
    Methods,
    Computed,
    Props
  > = Data & Methods & Computed & Props & Instance;

  type ExtendedVue<
    Instance extends Vue,
    Data,
    Methods,
    Computed,
    Props
  > = VueConstructor<
    CombinedVueInstance<Instance, Data, Methods, Computed, Props> & Vue
  >;

  export type DraggedContext<T> = {
    index: number;
    futureIndex: number;
    element: T;
  };

  export type DropContext<T> = {
    index: number;
    component: Vue;
    element: T;
  };

  export type Rectangle = {
    top: number;
    right: number;
    bottom: number;
    left: number;
    width: number;
    height: number;
  };

  export type MoveEvent<T> = {
    originalEvent: DragEvent;
    dragged: Element;
    draggedContext: DraggedContext<T>;
    draggedRect: Rectangle;
    related: Element;
    relatedContext: DropContext<T>;
    relatedRect: Rectangle;
    from: Element;
    to: Element;
    willInsertAfter: boolean;
    isTrusted: boolean;
  };

  const draggable: ExtendedVue<
    Vue,
    {},
    {},
    {},
    {
      options: any;
      list: any[];
      value: any[];
      noTransitionOnDrag?: boolean;
      clone: any;
      tag?: string | null;
      move: any;
      componentData: any;
    }
  >;

  export default draggable;
}
