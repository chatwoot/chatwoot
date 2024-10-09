<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: String, default: null },
  children: { type: Array, default: () => [] },
});

defineOptions({
  inheritAttrs: false,
});

const [collapsed, toggleCollapse] = useToggle(false);

const hasChildren = computed(() => props.children && props.children.length);
</script>

<template>
  <li class="text-sm cursor-pointer select-none gap-1 grid">
    <div
      class="flex items-center gap-2 px-2 py-1.5"
      v-bind="$attrs"
      @click="toggleCollapse()"
    >
      <span v-if="icon" :class="icon" class="size-4" />
      <span class="text-sm font-medium leading-5 flex-grow">
        {{ name }}
      </span>
      <span
        v-show="hasChildren && !collapsed"
        class="i-lucide-chevron-up size-3"
      />
    </div>
    <transition name="fade">
      <ul
        v-show="hasChildren && !collapsed"
        class="list-none m-0 ml-3 pl-3 grid gap-1 relative before:absolute before:content-[''] before:w-0.5 before:h-full before:bg-radix-slate3 before:rounded before:left-0"
      >
        <li
          v-for="child in children"
          :key="child.name"
          class="flex items-center gap-2 px-2 py-1 hover:bg-gradient-to-r from-transparent via-radix-slate3/70 to-radix-slate3/70 rounded-lg"
        >
          {{ child.name }}
        </li>
      </ul>
    </transition>
  </li>
</template>

<style scoped>
.fade-leave-active,
.fade-enter-active {
  transition: all 0.15s ease-in-out;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
