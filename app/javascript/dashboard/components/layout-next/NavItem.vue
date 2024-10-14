<script setup>
import { computed } from 'vue';
import { useSidebarContext } from './provider';
import { useToggle } from '@vueuse/core';
import { useRoute, useRouter } from 'vue-router';

import Icon from './Icon.vue';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  children: { type: Array, default: () => [] },
});

defineOptions({
  inheritAttrs: false,
});

const route = useRoute();
const router = useRouter();
const { expandedItem, setExpandedItem } = useSidebarContext();
const [transitioning, toggleTransition] = useToggle();

const resolvePath = to => router.resolve(to).path;
const toggleCollapse = () => {
  toggleTransition(true);
  setExpandedItem(props.name);
};

const isExpanded = computed(() => expandedItem.value === props.name);
const hasChildren = computed(() => props.children && props.children.length);
const isActive = computed(() => route?.name === props.to?.name);

const hasActiveChild = computed(() => {
  return props.children.some(child => {
    return child.to?.name === route.name;
  });
});

const activeChild = computed(() => {
  return props.children.find(child => {
    return child.to && resolvePath(child.to) === route.path;
  });
});
</script>

<template>
  <li class="text-sm cursor-pointer select-none gap-1 grid">
    <component
      :is="to ? 'router-link' : 'div'"
      :to="to"
      class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-auto"
      :class="{
        'text-n-blue bg-n-alpha-2 font-medium': isActive && !hasActiveChild,
        'text-n-slate12 font-medium': hasActiveChild,
        'text-n-slate11 hover:bg-n-alpha-2': !isActive && !hasActiveChild,
      }"
      @click="toggleCollapse()"
    >
      <Icon v-if="icon" :icon="icon" class="size-4" />
      <span class="text-sm font-medium leading-5 flex-grow">
        {{ name }}
      </span>
      <span
        v-show="hasChildren && isExpanded"
        class="i-lucide-chevron-up size-3"
      />
    </component>
    <ul
      v-show="hasChildren && (isExpanded || transitioning || hasActiveChild)"
      class="list-none max-h-[calc(32px*8+4px*7)] overflow-scroll m-0 ml-3 grid"
      @transitionend="toggleTransition(false)"
    >
      <transition
        v-for="(child, index) in children"
        :key="child.name"
        name="fade"
      >
        <!-- the py-0.5 is added to this becuase we want the before contents to be applied to uniformly event to elements outside the scroll area -->
        <li
          v-show="
            isExpanded || (hasActiveChild && activeChild.name === child.name)
          "
          :style="{ '--item-index': index }"
          class="py-0.5 pl-3 relative child-item before:bg-n-slate3 after:bg-transparent after:border-n-slate3"
        >
          <component
            :is="child.to ? 'router-link' : 'div'"
            :to="child.to"
            class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg"
            :class="{
              'text-n-blue bg-n-alpha-2 font-medium':
                hasActiveChild && activeChild.name === child.name,
              'hover:bg-gradient-to-r from-transparent via-n-slate3/70 to-n-slate3/70':
                hasActiveChild && activeChild.name !== child.name,
            }"
          >
            <Icon v-if="child.icon" :icon="child.icon" class="size-4" />
            {{ child.name }}
          </component>
        </li>
      </transition>
    </ul>
  </li>
</template>

<style scoped>
.fade-enter-active {
  transition: all 0.15s ease-in-out;
  transition-delay: calc(var(--item-index) * 0.025s);
}

.fade-leave-active {
  transition: all 0.02s ease-out;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}

.child-item::before {
  content: '';
  position: absolute;
  width: 0.125rem; /* 0.5px */
  height: 100%;
  left: 0;
}

.child-item:first-child::before {
  border-radius: 4px 4px 0 0;
}

.child-item:last-child::before {
  height: 20%;
}

.child-item:last-child::after {
  content: '';
  position: absolute;
  width: 12px;
  height: 12px;
  bottom: calc(50% - 2px);
  left: 0;
  border-bottom-width: 0.125rem;
  border-left-width: 0.125rem;
  border-right-width: 0px;
  border-top-width: 0px;
  border-radius: 0 0 0 4px;
}
</style>
