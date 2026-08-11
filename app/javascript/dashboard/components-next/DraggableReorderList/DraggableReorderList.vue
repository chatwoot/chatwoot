<script setup>
import { computed, ref, watch, nextTick, onBeforeUnmount } from 'vue';
import { useEventListener, onKeyStroke, useRafFn } from '@vueuse/core';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// Reorderable list with cross-page drag. It must stay mounted during a page
// fetch — hide the list spinner while `dragging`, or the held item is lost.
const props = defineProps({
  items: { type: Array, required: true },
  itemKey: { type: String, default: 'id' },
  disabled: { type: Boolean, default: false },
  currentPage: { type: Number, default: 1 },
  totalPages: { type: Number, default: 1 },
});
const emit = defineEmits(['reorder', 'navigatePage', 'dragging']);

const DRAG_THRESHOLD = 5;
const EDGE_BAND = 72; // px from a side that arms a page turn
const AUTO_PAGE_DELAY = 600; // ms hovering an edge before it flips
const SCROLL_BAND = 60; // px from top/bottom that autoscrolls the list
const SCROLL_STEP = 10; // px scrolled per frame while parked at an edge
const PILL = 36; // px, the page-turn arrow button on each edge

const root = ref(null);
const isDragging = ref(false);
const dragged = ref(null);
const pointer = ref({ x: 0, y: 0 });
const insertBefore = ref(null); // key the gap sits before, null = end of list
const activeEdge = ref(null);
const bounds = ref({ left: 0, right: 0, top: 0, bottom: 0 }); // visible list rect
const grab = ref({ dx: 0, dy: 0 }); // cursor offset inside the grabbed card
const dragHeight = ref(0);

let press = null; // pending press, before it becomes a drag
let dwell = null; // timer that flips the page after hovering an edge
let paging = false; // waiting for a flipped page to load
let scroller = null; // scrollable ancestor, found when a drag begins
let scrollDir = 0; // -1 up, +1 down, 0 idle
let sourcePage = 1; // page the drag started on, to resolve cross-page end-drops

const keyOf = item => String(item?.[props.itemKey]);
const others = item => props.items.filter(o => keyOf(o) !== keyOf(item));
const isRTL = () =>
  document.querySelector('#app[dir]')?.getAttribute('dir') === 'rtl';
const canPage = dir =>
  dir === 'next' ? props.currentPage < props.totalPages : props.currentPage > 1;

// Key of the item after `key` in `list`, or null when it is the last one.
const keyAfter = (list, key) => {
  const next = list[list.findIndex(o => keyOf(o) === key) + 1];
  return next ? keyOf(next) : null;
};

const edges = computed(() =>
  ['prev', 'next'].filter(canPage).map(dir => {
    const onLeft = isRTL() ? dir === 'next' : dir === 'prev';
    return {
      dir,
      onLeft,
      icon: onLeft ? 'i-lucide-chevrons-left' : 'i-lucide-chevrons-right',
    };
  })
);

// Cursor overlay: an edge glow band, a page-turn arrow per edge, and a ghost of
// the dragged row that follows the cursor and shrinks when aimed at an edge.
const EDGE_BAND_W = 80; // px width of the glow band on each pageable edge
const bandStyle = onLeft => {
  const x = onLeft ? bounds.value.left : bounds.value.right - EDGE_BAND_W;
  return {
    width: `${EDGE_BAND_W}px`,
    height: `${bounds.value.bottom - bounds.value.top}px`,
    transform: `translate(${x}px, ${bounds.value.top}px)`,
  };
};
const pillStyle = onLeft => {
  const x = onLeft ? bounds.value.left + 12 : bounds.value.right - PILL - 12;
  return { transform: `translate(${x}px, ${pointer.value.y - PILL / 2}px)` };
};
const ghostStyle = computed(() => ({
  width: `${bounds.value.right - bounds.value.left}px`,
  transform: `translate(${pointer.value.x - grab.value.dx}px, ${pointer.value.y - grab.value.dy}px)`,
}));
const scaleStyle = computed(() => ({
  transformOrigin: `${grab.value.dx}px ${grab.value.dy}px`,
}));

// The list as shown mid-drag: the dragged row slotted into the gap at `insertBefore`.
const displayItems = computed(() => {
  if (!isDragging.value || !dragged.value) return props.items;
  const rest = others(dragged.value);
  const at = rest.findIndex(o => keyOf(o) === insertBefore.value);
  rest.splice(at === -1 ? rest.length : at, 0, dragged.value);
  return rest;
});

// Move the gap when the cursor crosses the midpoint of the card it is over.
const aim = () => {
  const card = document
    .elementFromPoint(pointer.value.x, pointer.value.y)
    ?.closest('[data-drag-id]');
  const key = card?.dataset.dragId;
  if (!key || key === keyOf(dragged.value)) return;

  const { top, height } = card.getBoundingClientRect();
  const above = pointer.value.y < top + height / 2;
  insertBefore.value = above ? key : keyAfter(others(dragged.value), key);
};

const flip = dir => {
  if (paging || !isDragging.value) return;
  paging = true;
  emit('navigatePage', props.currentPage + (dir === 'next' ? 1 : -1));
};

const aimEdge = x => {
  const rect = root.value?.getBoundingClientRect();
  if (!rect) return;
  // Clip the list rect to the scroll viewport so the glow band and its top/bottom
  // fade always sit on the visible edges, not the far ends of the full content.
  const view = scroller?.getBoundingClientRect();
  const viewTop = Math.max(view?.top ?? 0, 0);
  const viewBottom = Math.min(
    view?.bottom ?? window.innerHeight,
    window.innerHeight
  );
  bounds.value = {
    left: rect.left,
    right: rect.right,
    top: Math.max(rect.top, viewTop),
    bottom: Math.min(rect.bottom, viewBottom),
  };

  let dir = null;
  if (x <= rect.left + EDGE_BAND) dir = isRTL() ? 'next' : 'prev';
  else if (x >= rect.right - EDGE_BAND) dir = isRTL() ? 'prev' : 'next';
  if (dir && !canPage(dir)) dir = null;
  if (dir === activeEdge.value) return;

  activeEdge.value = dir;
  clearTimeout(dwell);
  if (dir) dwell = setTimeout(() => flip(dir), AUTO_PAGE_DELAY);
};

// Nearest scrollable ancestor, so a drag can reach rows that are off-screen.
const scrollParent = () => {
  let el = root.value?.parentElement;
  while (el) {
    const { overflowY } = getComputedStyle(el);
    if (overflowY === 'auto' || overflowY === 'scroll') return el;
    el = el.parentElement;
  }
  return null;
};

// While parked at the top/bottom edge, keep scrolling and re-aim as rows slide by.
const { pause: pauseScroll, resume: resumeScroll } = useRafFn(
  () => {
    if (!scroller || !scrollDir) return;
    scroller.scrollTop += scrollDir * SCROLL_STEP;
    aim();
    aimEdge(pointer.value.x);
  },
  { immediate: false }
);

const updateAutoScroll = y => {
  if (!scroller) return;
  const rect = scroller.getBoundingClientRect();
  const atTop = scroller.scrollTop <= 0;
  const atBottom =
    scroller.scrollTop >= scroller.scrollHeight - scroller.clientHeight;
  if (y < rect.top + SCROLL_BAND && !atTop) scrollDir = -1;
  else if (y > rect.bottom - SCROLL_BAND && !atBottom) scrollDir = 1;
  else scrollDir = 0;
  if (scrollDir) resumeScroll();
  else pauseScroll();
};

const reset = () => {
  isDragging.value = false;
  dragged.value = null;
  insertBefore.value = null;
  activeEdge.value = null;
  clearTimeout(dwell);
  paging = false;
  scrollDir = 0;
  scroller = null;
  pauseScroll();
  document.body.classList.remove('select-none');
  emit('dragging', false);
};

// Positions sit on a gap-of-10 grid; a midpoint (±5 at the ends) slots between two rows.
// Cross-page end-drops are the tricky case: moving an item off its source page pulls the
// target page's boundary row into the vacated slot. So at the leading edge after moving
// DOWN (or the trailing edge after moving UP) we land between the two boundary rows, or
// the item sorts onto the adjacent page and vanishes from view.
const drop = (item, rawBefore) => {
  const pos = o => o?.position || 0;
  const mid = (a, b) => Math.floor((pos(a) + pos(b)) / 2);
  const rest = others(item);
  // No other rows to position against — e.g. the lone article on a page dropped
  // without crossing to another page. Leave the order untouched.
  if (!rest.length) return;
  // A page flip can leave the aimed key pointing at a row that is no longer on
  // this page. Like displayItems, resolve an unknown key to null (end of list),
  // so what the user sees and what we save agree.
  const before = rest.some(o => keyOf(o) === rawBefore) ? rawBefore : null;
  const movedDown = props.currentPage > sourcePage;
  const movedUp = props.currentPage < sourcePage;

  let position;
  if (before === null) {
    position =
      movedUp && rest.length >= 2
        ? mid(rest.at(-2), rest.at(-1))
        : pos(rest.at(-1)) + 5;
  } else {
    const i = rest.findIndex(o => keyOf(o) === before);
    if (i > 0) {
      position = mid(rest[i - 1], rest[i]);
    } else if (movedDown) {
      // Top-of-page after moving down: the old first row slid up into the source
      // page's gap, so land just after it to stay this page's first.
      position = rest.length >= 2 ? mid(rest[0], rest[1]) : pos(rest[0]) + 5;
    } else {
      position = pos(rest[0]) - 5;
    }
  }
  emit('reorder', { [item[props.itemKey]]: position });
};

const startDrag = () => {
  isDragging.value = true;
  dragged.value = press.item;
  grab.value = { dx: press.dx, dy: press.dy };
  dragHeight.value = press.h;
  insertBefore.value = keyAfter(props.items, keyOf(press.item));
  sourcePage = props.currentPage;
  scroller = scrollParent();
  document.body.classList.add('select-none');
  emit('dragging', true);
};

const onPointerDown = (item, e) => {
  if (e.button !== 0 || props.disabled) return;
  if (e.target.closest('button, a, input, [role="button"]')) return;
  const rect = e.currentTarget.getBoundingClientRect();
  press = {
    item,
    x: e.clientX,
    y: e.clientY,
    dx: e.clientX - rect.left,
    dy: e.clientY - rect.top,
    h: rect.height,
  };
};

useEventListener(window, 'pointermove', e => {
  if (!press) return;
  if (!isDragging.value) {
    const moved = Math.hypot(e.clientX - press.x, e.clientY - press.y);
    if (moved < DRAG_THRESHOLD) return;
    startDrag();
  }
  e.preventDefault();
  pointer.value = { x: e.clientX, y: e.clientY };
  aim();
  aimEdge(e.clientX);
  updateAutoScroll(e.clientY);
});

useEventListener(window, 'pointerup', () => {
  if (!press) return;
  press = null;
  if (!isDragging.value) return; // a press without movement is a click
  const item = dragged.value;
  const before = insertBefore.value;
  const flipping = paging;
  reset();
  if (!flipping) drop(item, before);
});

// When the flipped page loads, re-aim under the held cursor so a parked edge keeps flipping.
watch(
  () => props.items,
  () => {
    if (!isDragging.value || !paging) return;
    paging = false;
    nextTick(() => {
      if (!isDragging.value) return;
      aim();
      activeEdge.value = null;
      aimEdge(pointer.value.x);
    });
  }
);

onKeyStroke('Escape', () => {
  if (!isDragging.value) return;
  press = null;
  reset();
});

onBeforeUnmount(() => {
  clearTimeout(dwell);
  document.body.classList.remove('select-none');
});
</script>

<template>
  <div ref="root" class="relative w-full h-full">
    <ul class="w-full h-full space-y-4">
      <li
        v-for="(item, index) in displayItems"
        :key="keyOf(item)"
        :data-drag-id="keyOf(item)"
        class="relative list-none"
        :class="{ 'cursor-grab': !disabled && !isDragging }"
        @pointerdown="onPointerDown(item, $event)"
        @dragstart.prevent
      >
        <div
          v-if="isDragging && keyOf(item) === keyOf(dragged)"
          :style="{ height: `${dragHeight}px` }"
          class="border-2 border-dashed rounded-2xl border-n-brand/50 bg-n-brand/5"
        />
        <slot v-else name="item" :item="item" :index="index" />
      </li>
    </ul>

    <Teleport v-if="isDragging" to="body">
      <div
        v-for="edge in edges"
        :key="`band-${edge.dir}`"
        :style="bandStyle(edge.onLeft)"
        class="fixed top-0 left-0 z-40 pointer-events-none from-n-brand/15 to-transparent transition-opacity duration-200 [mask-image:linear-gradient(to_bottom,transparent,#000_56px,#000_calc(100%_-_56px),transparent)] [-webkit-mask-image:linear-gradient(to_bottom,transparent,#000_56px,#000_calc(100%_-_56px),transparent)]"
        :class="[
          edge.onLeft ? 'bg-gradient-to-r' : 'bg-gradient-to-l',
          activeEdge === edge.dir ? 'opacity-100' : 'opacity-0',
        ]"
      />

      <div
        v-for="edge in edges"
        :key="edge.dir"
        :style="pillStyle(edge.onLeft)"
        class="fixed top-0 left-0 z-50 flex items-center justify-center transition-all duration-150 border rounded-full pointer-events-none size-9 backdrop-blur-sm"
        :class="
          activeEdge === edge.dir
            ? 'scale-110 border-n-brand bg-n-brand/20 text-n-brand shadow-md'
            : 'opacity-70 border-n-weak/60 bg-n-solid-1/70 text-n-slate-10'
        "
      >
        <Icon
          :icon="edge.icon"
          class="size-4"
          :class="activeEdge === edge.dir && 'animate-pulse'"
        />
      </div>

      <div
        v-if="dragged"
        :style="ghostStyle"
        class="fixed top-0 left-0 z-50 pointer-events-none select-none"
      >
        <div
          :style="scaleStyle"
          class="transition-transform duration-150 shadow-2xl rounded-2xl"
          :class="{ 'scale-50': activeEdge }"
        >
          <slot name="ghost" :item="dragged" />
        </div>
      </div>
    </Teleport>
  </div>
</template>
