<script setup>
import { computed } from 'vue';
import { useSidebarContext } from './provider';
import { useToggle } from '@vueuse/core';
import { useRoute, useRouter } from 'vue-router';
import Policy from 'dashboard/components/policy.vue';

import Icon from './Icon.vue';

const props = defineProps({
  name: { type: String, required: true },
  icon: { type: [String, Object, Function], default: null },
  to: { type: Object, default: null },
  children: { type: Array, default: undefined },
});

defineOptions({
  inheritAttrs: false,
});

const route = useRoute();
const router = useRouter();
const { expandedItem, setExpandedItem } = useSidebarContext();
const [transitioning, toggleTransition] = useToggle(false);

const resolvePath = to => router.resolve(to).path;

const resolvePermissions = to => {
  if (!to) return [];

  return router.resolve(to).meta?.permissions ?? [];
};

const resolveFeatureFlag = to => {
  if (!to) return '';

  return router.resolve(to).meta?.featureFlag ?? '';
};

const toggleCollapse = () => {
  toggleTransition(true);
  setExpandedItem(props.name);
};

const isExpanded = computed(() => expandedItem.value === props.name);
const isExpandable = computed(() => props.children);
const hasChildren = computed(
  () => Array.isArray(props.children) && props.children.length > 0
);
const isActive = computed(
  () => props.to && route.path === resolvePath(props.to)
);

const hasActiveChild = computed(() => {
  return (
    hasChildren.value &&
    props.children.some(child => {
      return child.to?.name === route.name;
    })
  );
});

const activeChild = computed(() => {
  return hasChildren.value
    ? props.children.find(child => {
        return child.to && resolvePath(child.to) === route.path;
      })
    : null;
});
</script>

<template>
  <Policy
    as="li"
    :permissions="resolvePermissions(to)"
    :feature-flag="resolveFeatureFlag(to)"
    class="text-sm cursor-pointer select-none gap-1 grid"
  >
    <component
      :is="to ? 'router-link' : 'div'"
      role="button"
      :to="to"
      class="flex items-center gap-2 px-2 py-1.5 rounded-lg h-auto"
      :class="{
        'text-n-blue bg-n-alpha-2 font-medium': isActive && !hasActiveChild,
        'text-n-slate-12 font-medium': hasActiveChild,
        'text-n-slate-11 hover:bg-n-alpha-2': !isActive && !hasActiveChild,
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
      v-if="hasChildren && (isExpanded || transitioning || hasActiveChild)"
      class="list-none max-h-[calc(32px*8+4px*7)] overflow-scroll m-0 ml-3 grid"
      @transitionend="toggleTransition(false)"
    >
      <transition
        v-for="(child, index) in children"
        :key="child.name"
        name="fade"
      >
        <Policy
          v-show="isExpanded || activeChild?.name === child.name"
          as="li"
          :permissions="resolvePermissions(child.to)"
          :feature-flag="resolveFeatureFlag(to)"
          :style="{ '--item-index': index }"
          class="py-0.5 pl-3 relative child-item before:bg-n-slate-3 after:bg-transparent after:border-n-slate-3"
        >
          <!-- the py-0.5 is added to this becuase we want the before contents to be applied to uniformly event to elements outside the scroll area -->

          <component
            :is="child.to ? 'router-link' : 'div'"
            :to="child.to"
            :title="child.name"
            class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg max-w-[151px] hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70"
            :class="{
              'text-n-blue bg-n-alpha-2 font-medium':
                activeChild?.name === child.name,
            }"
          >
            <div>
              <Icon
                v-if="child.icon"
                :icon="child.icon"
                class="size-4 inline-block"
                :class="
                  activeChild?.name === child.name
                    ? 'bg-n-blue/20'
                    : 'bg-n-alpha-2'
                "
              />
            </div>
            <div class="flex-1 truncate min-w-0">{{ child.name }}</div>
          </component>
        </Policy>
      </transition>
    </ul>
    <ul v-else-if="isExpandable && isExpanded">
      <li
        class="py-1 pl-3 text-n-slate-10 border rounded-lg border-dashed text-center border-n-alpha-2 text-xs h-8 grid place-content-center"
      >
        {{ 'No items' }}
      </li>
    </ul>
  </Policy>
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
  width: 10px;
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
