<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle']);

const onToggle = () => {
  emit('toggle');
};
</script>

<template>
  <div
    class="text-sm mx-4 grid gap-2 py-3 rounded-[0.625rem] outline outline-1 outline-n-weak -outline-offset-1"
  >
    <button
      class="flex items-center select-none w-full m-0 cursor-grab justify-between drag-handle px-3 py-0 focus-visible:outline-none outline-none !transition-none"
      @click.stop="onToggle"
    >
      <h5 class="text-n-slate-12 text-heading-3 mb-0 py-0 pr-2 pl-0">
        {{ title }}
      </h5>
      <div
        class="flex justify-end w-3 text-n-blue-text flex-shrink-0 cursor-pointer size-4"
      >
        <Icon
          v-if="isOpen"
          icon="i-lucide-chevron-up"
          class="size-4 text-n-slate-11"
        />
        <Icon
          v-else
          icon="i-lucide-chevron-down"
          class="size-4 text-n-slate-11"
        />
      </div>
    </button>
    <Transition
      enter-active-class="transition-[grid-template-rows,opacity,transform] duration-[400ms] ease-[cubic-bezier(0.23,1,0.32,1)]"
      enter-from-class="grid-rows-[0fr] opacity-0 scale-[0.96] -translate-y-2"
      enter-to-class="grid-rows-[1fr] opacity-100 scale-100 translate-y-0"
      leave-active-class="transition-[grid-template-rows,opacity,transform] duration-[250ms] ease-[cubic-bezier(0.4,0,1,1)]"
      leave-from-class="grid-rows-[1fr] opacity-100 scale-100"
      leave-to-class="grid-rows-[0fr] opacity-0 scale-[0.96] -translate-y-1"
      @before-enter="
        el => {
          el.style.overflow = 'hidden';
          el.style.willChange = 'grid-template-rows, opacity, transform';
        }
      "
      @after-enter="
        el => {
          el.style.overflow = 'visible';
          el.style.willChange = 'auto';
        }
      "
      @before-leave="
        el => {
          el.style.overflow = 'hidden';
          el.style.willChange = 'grid-template-rows, opacity, transform';
        }
      "
      @after-leave="
        el => {
          el.style.willChange = 'auto';
        }
      "
    >
      <div v-if="isOpen" class="grid origin-top">
        <div class="min-h-0" :class="[compact ? 'px-0' : 'px-3']">
          <slot />
        </div>
      </div>
    </Transition>
  </div>
</template>
