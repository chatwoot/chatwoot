<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

const props = defineProps({
  items: {
    type: Array,
    default: () => [],
  },
});

const route = useRoute();

const activeIndex = computed(() => {
  return props.items.findIndex(i => i.route === route.name);
});

const isActive = item => {
  return props.items.indexOf(item) === activeIndex.value;
};

const isOver = item => {
  return props.items.indexOf(item) < activeIndex.value;
};
</script>

<template>
  <transition-group name="wizard-items w-full" tag="div">
    <div
      v-for="(item, index) in items"
      :key="item.route"
      class="cursor-pointer flex items-start gap-6 relative after:content-[''] after:absolute after:w-0.5 after:h-full after:top-5 ltr:after:left-4 rtl:after:right-4 before:content-[''] before:absolute before:w-0.5 before:h-4 before:top-0 before:left-4 rtl:before:right-4 last:after:hidden last:before:hidden"
      :class="
        isOver(item)
          ? 'after:bg-n-blue-9 before:bg-n-blue-9'
          : 'after:bg-n-weak before:bg-n-weak'
      "
    >
      <div
        class="rounded-2xl flex-shrink-0 size-8 flex items-center justify-center left-2 outline outline-2 leading-4 z-10 top-5 bg-n-background"
        :class="
          isActive(item) || isOver(item) ? 'outline-n-blue-9' : 'outline-n-weak'
        "
      >
        <span
          class="text-xs font-bold"
          :class="
            isActive(item) || isOver(item)
              ? 'text-n-blue-11'
              : 'text-n-slate-11'
          "
        >
          {{ index + 1 }}
        </span>
      </div>
      <div class="flex flex-col items-start gap-1.5 pb-10 pt-1">
        <div class="flex items-center">
          <h3
            class="text-sm font-medium overflow-hidden whitespace-nowrap mt-0.5 text-ellipsis leading-tight"
            :class="
              isActive(item) || isOver(item)
                ? 'text-n-blue-11'
                : 'text-n-slate-12'
            "
          >
            {{ item.title }}
          </h3>
        </div>
        <p class="m-0 mt-1.5 text-sm text-n-slate-11">
          {{ item.body }}
        </p>
      </div>
    </div>
  </transition-group>
</template>
