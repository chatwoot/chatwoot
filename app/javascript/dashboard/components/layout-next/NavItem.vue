<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';

import Icon from './Icon.vue';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
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
      <Icon v-if="icon" :icon="icon" class="size-4" />
      <span class="text-sm font-medium leading-5 flex-grow">
        {{ name }}
      </span>
      <span
        v-show="hasChildren && !collapsed"
        class="i-lucide-chevron-up size-3"
      />
    </div>
    <ul
      v-show="hasChildren && !collapsed"
      class="list-none m-0 ml-3 pl-3 grid gap-1 relative before:absolute before:content-[''] before:w-0.5 before:h-full before:bg-n-slate3 before:rounded before:left-0"
    >
      <transition v-for="child in children" :key="child.name" name="fade">
        <li
          v-if="!collapsed"
          class="flex items-center gap-2 px-2 py-1 hover:bg-gradient-to-r from-transparent via-n-slate3/70 to-n-slate3/70 rounded-lg"
        >
          <Icon v-if="child.icon" :icon="child.icon" class="size-4" />
          {{ child.name }}
        </li>
      </transition>
    </ul>
  </li>
</template>

<style scoped>
.fade-enter-active {
  transition: all 0.15s ease-in-out;
}

.fade-leave-active {
  transition: all 0.15s ease-out;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
