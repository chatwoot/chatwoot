<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

const route = useRoute();

const activeIndex = computed(() => {
  const index = props.items.findIndex(i => i.route === route.name);
  return index === -1 ? 0 : index;
});

const steps = computed(() =>
  props.items.map((item, index) => {
    const isActive = index === activeIndex.value;
    const isOver = index < activeIndex.value;
    return {
      ...item,
      index,
      isActive,
      isOver,
    };
  })
);
</script>

<template>
  <transition-group tag="div">
    <div
      v-for="step in steps"
      :key="step.route"
      class="cursor-pointer flex items-start gap-6 relative after:content-[''] after:absolute after:w-0.5 after:h-full after:top-5 ltr:after:left-4 rtl:after:right-4 before:content-[''] before:absolute before:w-0.5 before:h-4 before:top-0 before:left-4 rtl:before:right-4 last:after:hidden last:before:hidden after:bg-n-slate-3 before:bg-n-slate-3"
    >
      <!-- Circle -->
      <div
        class="rounded-2xl flex-shrink-0 size-8 border-2 border-n-slate-3 flex items-center justify-center left-2 leading-4 z-10 top-5 transition-all duration-300 ease-in-out"
        :class="{
          'bg-n-slate-3': step.isActive || step.isOver,
          'bg-n-background': !step.isActive && !step.isOver,
        }"
      >
        <span
          v-if="!step.isOver"
          :key="'num-' + step.index"
          class="text-xs font-bold transition-colors duration-300"
          :class="step.isActive ? 'text-n-blue-11' : 'text-n-slate-11'"
        >
          {{ step.index + 1 }}
        </span>
        <Icon
          v-else
          :key="'check-' + step.index"
          icon="i-lucide-check"
          class="text-n-slate-11 size-4"
        />
      </div>

      <!-- Content -->
      <div class="flex flex-col items-start gap-1.5 pb-10 pt-1">
        <div class="flex items-center">
          <h3
            class="text-sm font-medium overflow-hidden whitespace-nowrap mt-0.5 text-ellipsis leading-tight"
            :class="step.isActive ? 'text-n-blue-11' : 'text-n-slate-12'"
          >
            {{ step.title }}
          </h3>
        </div>
        <p class="m-0 mt-1.5 text-sm text-n-slate-11">
          {{ step.body }}
        </p>
      </div>
    </div>
  </transition-group>
</template>
