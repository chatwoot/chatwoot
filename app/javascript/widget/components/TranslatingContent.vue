<script setup>
import { ref, computed, watch, nextTick, onBeforeUnmount } from 'vue';

const props = defineProps({
  translating: { type: Boolean, default: false },
  translated: { type: Boolean, default: false },
});
const TEXT_DOTS_CLASS =
  'select-none bg-clip-text !text-transparent [&_*]:!text-transparent [&_*]:!bg-transparent bg-[image:linear-gradient(90deg,transparent_30%,rgb(var(--iris-7))_50%,transparent_70%),radial-gradient(circle,rgb(var(--iris-10))_0.09375rem,transparent_0.125rem)] [background-size:250%_100%,0.25rem_0.25rem] animate-text-dots motion-reduce:animate-none';
const TEXT_SOLIDIFY_CLASS =
  'bg-clip-text !text-transparent [&_*]:!text-transparent [&_*]:!bg-transparent bg-[image:linear-gradient(90deg,rgb(var(--slate-12))_45%,transparent_55%),radial-gradient(circle,rgb(var(--iris-10))_0.09375rem,transparent_0.125rem)] [background-size:200%_100%,0.25rem_0.25rem] animate-text-solidify motion-reduce:animate-none';
const REVEAL_MS = 600;
const HEIGHT_MORPH = {
  duration: 350,
  easing: 'cubic-bezier(0.22, 1, 0.36, 1)',
};

const wrap = ref(null);
const revealing = ref(false);
let revealTimer = null;
const active = computed(
  () => props.translating || props.translated || revealing.value
);

const morphHeight = async () => {
  const el = wrap.value;
  if (!el?.animate) return;
  const from = el.offsetHeight;
  await nextTick();
  const to = el.offsetHeight;
  if (from === to) return;
  el.animate([{ height: `${from}px` }, { height: `${to}px` }], HEIGHT_MORPH);
};

watch(
  () => props.translating,
  (now, before) => {
    if (!before || now) return;
    morphHeight();
    revealing.value = true;
    clearTimeout(revealTimer);
    revealTimer = setTimeout(() => {
      revealing.value = false;
    }, REVEAL_MS);
  }
);

onBeforeUnmount(() => clearTimeout(revealTimer));
</script>

<template>
  <div
    v-if="active"
    ref="wrap"
    class="relative"
    :class="{ 'overflow-hidden': revealing }"
  >
    <div
      :class="{
        [TEXT_DOTS_CLASS]: translating,
        [TEXT_SOLIDIFY_CLASS]: revealing,
      }"
    >
      <slot />
    </div>
    <div
      v-if="translating"
      class="mt-1 flex items-center gap-1 text-xs text-n-iris-11"
    >
      <span
        class="i-lucide-sparkles size-3 animate-twinkle motion-reduce:animate-none"
        aria-hidden="true"
      />
      {{ $t('TRANSLATING') }}
    </div>
  </div>
  <slot v-else />
</template>
