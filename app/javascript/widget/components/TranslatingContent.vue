<script setup>
import { ref } from 'vue';

defineProps({
  translating: { type: Boolean, default: false },
  translated: { type: Boolean, default: false },
});
const TEXT_SHIMMER_CLASS =
  'bg-clip-text bg-gradient-to-r from-n-iris-11 from-35% via-n-iris-7 to-n-iris-11 to-65% bg-[length:300%_100%] animate-text-shimmer motion-reduce:animate-none [&_*]:!text-transparent [&_*]:!bg-transparent';
const HEIGHT_MORPH = {
  duration: 300,
  easing: 'cubic-bezier(0.2, 0.8, 0.2, 1)',
};

const wrap = ref(null);
let heightBeforeChange = 0;

const measureHeight = () => {
  heightBeforeChange = wrap.value.offsetHeight;
};

const morphHeight = () => {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  wrap.value.animate(
    { height: [`${heightBeforeChange}px`, `${wrap.value.offsetHeight}px`] },
    HEIGHT_MORPH
  );
};
</script>

<template>
  <div
    v-if="translating || translated"
    ref="wrap"
    class="overflow-hidden"
    :aria-busy="translating"
  >
    <Transition
      mode="out-in"
      enter-from-class="opacity-0 blur-[0.125rem]"
      enter-active-class="transition duration-300 ease-out motion-reduce:transition-none"
      leave-active-class="transition duration-150 ease-in motion-reduce:transition-none"
      leave-to-class="opacity-0 blur-[0.125rem]"
      @before-leave="measureHeight"
      @enter="morphHeight"
    >
      <div :key="translating ? 'translating' : 'translated'">
        <div :class="{ [TEXT_SHIMMER_CLASS]: translating }">
          <slot />
        </div>
        <div
          v-if="translating"
          class="mt-1 flex items-center gap-1.5 text-xs text-n-slate-11 select-none"
        >
          <span
            class="i-lucide-sparkles size-3 text-n-iris-9 animate-twinkle motion-reduce:animate-none"
            aria-hidden="true"
          />
          <span
            class="bg-clip-text text-transparent bg-gradient-to-r from-n-iris-11 from-35% via-n-iris-7 to-n-iris-11 to-65% bg-[length:300%_100%] animate-text-shimmer motion-reduce:animate-none"
          >
            {{ $t('TRANSLATING') }}
          </span>
        </div>
      </div>
    </Transition>
  </div>
  <slot v-else />
</template>
