<script setup>
import { computed, ref, onMounted, nextTick } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { useRouter } from 'vue-router';
import { useSidebarContext } from './provider';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';
import SidebarSortMenu from './SidebarSortMenu.vue';

const props = defineProps({
  label: { type: String, required: true },
  children: { type: Array, default: () => [] },
  activeChild: { type: Object, default: undefined },
  triggerRect: { type: Object, default: () => ({ top: 0, left: 0 }) },
});

const emit = defineEmits(['close', 'mouseenter', 'mouseleave', 'sortToggle']);

const router = useRouter();
const { isAllowed, sidebarWidth } = useSidebarContext();

const expandedSubGroup = ref(null);
const popoverRef = ref(null);
const topPosition = ref(0);
const isRTL = useMapGetter('accounts/isRTL');
const skipTransition = ref(true);

const toggleSubGroup = name => {
  expandedSubGroup.value = expandedSubGroup.value === name ? null : name;
};

const handleSortToggle = isSortOpen => {
  emit('sortToggle', isSortOpen);
};

onClickOutside(popoverRef, () => emit('close'), {
  ignore: ['[data-popover-content]'],
});

const navigateAndClose = to => {
  router.push(to);
  emit('close');
};

const isActive = child => props.activeChild?.name === child.name;

const getAccessibleSubChildren = children =>
  children.filter(c => isAllowed(c.to));

const renderIcon = icon => ({
  component: typeof icon === 'object' ? icon : Icon,
  props: typeof icon === 'string' ? { icon } : null,
});

const transition = computed(() =>
  skipTransition.value
    ? {}
    : {
        enterActiveClass: 'transition-all duration-200 ease-out',
        enterFromClass: 'opacity-0 -translate-y-2 max-h-0',
        enterToClass: 'opacity-100 translate-y-0 max-h-96',
        leaveActiveClass: 'transition-all duration-150 ease-in',
        leaveFromClass: 'opacity-100 translate-y-0 max-h-96',
        leaveToClass: 'opacity-0 -translate-y-2 max-h-0',
      }
);

const accessibleChildren = computed(() => {
  return props.children.filter(child => {
    if (child.children) {
      return child.children.some(subChild => isAllowed(subChild.to));
    }
    return child.to && isAllowed(child.to);
  });
});

onMounted(async () => {
  await nextTick();

  // Auto-expand subgroup if active child is inside it
  if (props.activeChild) {
    const parentGroup = props.children.find(child =>
      child.children?.some(subChild => subChild.name === props.activeChild.name)
    );
    if (parentGroup) {
      expandedSubGroup.value = parentGroup.name;
      // Wait for the subgroup expansion to render before measuring height
      await nextTick();
    }
  }

  if (!props.triggerRect) return;

  const viewportHeight = window.innerHeight;
  const popoverHeight = popoverRef.value?.offsetHeight || 300;
  const { top: triggerTop } = props.triggerRect;

  // Adjust position if popover would overflow viewport
  topPosition.value =
    triggerTop + popoverHeight > viewportHeight - 20
      ? Math.max(20, viewportHeight - popoverHeight - 20)
      : triggerTop;

  await nextTick();
  skipTransition.value = false;
});
</script>

<template>
  <TeleportWithDirection>
    <div
      ref="popoverRef"
      class="fixed z-[100] min-w-[200px] max-w-[280px]"
      :style="{
        [isRTL ? 'right' : 'left']: `${sidebarWidth + 8}px`,
        top: `${topPosition}px`,
      }"
      @mouseenter="emit('mouseenter')"
      @mouseleave="emit('mouseleave')"
    >
      <div
        class="bg-n-alpha-3 backdrop-blur-[100px] outline outline-1 -outline-offset-1 w-56 outline-n-weak rounded-xl shadow-lg py-2 px-2"
      >
        <div
          class="px-2 py-1.5 text-xs font-medium text-n-slate-11 uppercase tracking-wider border-b border-n-weak mb-1"
        >
          {{ label }}
        </div>
        <ul
          class="m-0 p-0 list-none max-h-[400px] overflow-y-auto no-scrollbar"
        >
          <template v-for="child in accessibleChildren" :key="child.name">
            <!-- SubGroup with children -->
            <li v-if="child.children" class="group/sidebar-section py-0.5">
              <div
                class="flex items-center rounded-lg text-n-slate-11 hover:bg-n-alpha-2 transition-colors duration-150 ease-out"
              >
                <button
                  class="flex flex-1 min-w-0 items-center gap-2 ps-2 py-1.5 text-left rtl:text-right"
                  @click="toggleSubGroup(child.name)"
                >
                  <Icon
                    v-if="child.icon"
                    :icon="child.icon"
                    class="size-4 flex-shrink-0"
                  />
                  <span class="flex-1 truncate text-sm">{{ child.label }}</span>
                </button>
                <div class="flex flex-shrink-0 items-center gap-1 pe-2">
                  <SidebarSortMenu
                    v-if="child.sortOptions?.length"
                    :active-sort="child.activeSort"
                    :options="child.sortOptions"
                    :open-on-hover="false"
                    @sort="child.onSortChange"
                    @toggle="handleSortToggle"
                  />
                  <button
                    type="button"
                    class="flex size-6 flex-shrink-0 items-center justify-center rounded-md text-n-slate-11 hover:bg-n-alpha-2 focus-visible:bg-n-alpha-2 focus-visible:outline-none"
                    @click.stop="toggleSubGroup(child.name)"
                  >
                    <span
                      class="size-4 flex-shrink-0 transition-transform i-lucide-chevron-down"
                      :class="{
                        'rotate-180': expandedSubGroup === child.name,
                      }"
                    />
                  </button>
                </div>
              </div>
              <Transition v-bind="transition">
                <ul
                  v-if="expandedSubGroup === child.name"
                  class="m-0 p-0 list-none ltr:pl-4 rtl:pr-4 mt-1 overflow-hidden"
                >
                  <li
                    v-for="subChild in getAccessibleSubChildren(child.children)"
                    :key="subChild.name"
                    class="py-0.5"
                  >
                    <button
                      class="flex items-center gap-2 px-2 py-1.5 w-full rounded-lg text-sm text-left rtl:text-right transition-colors duration-150 ease-out"
                      :class="{
                        'text-n-slate-12 bg-n-alpha-2': isActive(subChild),
                        'text-n-slate-11 hover:bg-n-alpha-2':
                          !isActive(subChild),
                      }"
                      @click="navigateAndClose(subChild.to)"
                    >
                      <component
                        :is="renderIcon(subChild.icon).component"
                        v-if="subChild.icon"
                        v-bind="renderIcon(subChild.icon).props"
                        class="size-4 flex-shrink-0"
                      />
                      <span class="flex-1 truncate">{{ subChild.label }}</span>
                      <SidebarUnreadBadge :count="subChild.badgeCount" />
                    </button>
                  </li>
                </ul>
              </Transition>
            </li>
            <!-- Direct child item -->
            <li v-else class="py-0.5">
              <button
                class="flex items-center gap-2 px-2 py-1.5 w-full rounded-lg text-sm text-left rtl:text-right transition-colors duration-150 ease-out"
                :class="{
                  'text-n-slate-12 bg-n-alpha-2': isActive(child),
                  'text-n-slate-11 hover:bg-n-alpha-2': !isActive(child),
                }"
                @click="navigateAndClose(child.to)"
              >
                <component
                  :is="renderIcon(child.icon).component"
                  v-if="child.icon"
                  v-bind="renderIcon(child.icon).props"
                  class="size-4 flex-shrink-0"
                />
                <span class="flex-1 truncate">{{ child.label }}</span>
                <SidebarUnreadBadge :count="child.badgeCount" />
              </button>
            </li>
          </template>
        </ul>
      </div>
    </div>
  </TeleportWithDirection>
</template>
