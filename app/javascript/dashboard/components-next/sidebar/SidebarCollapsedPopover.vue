<script setup>
import { computed, ref, onMounted, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { useSidebarContext } from './provider';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  label: { type: String, required: true },
  children: { type: Array, default: () => [] },
  activeChild: { type: Object, default: undefined },
  triggerRect: { type: Object, default: () => ({ top: 0, left: 0 }) },
});

const emit = defineEmits(['close', 'mouseenter', 'mouseleave']);

const router = useRouter();
const { isAllowed, sidebarWidth } = useSidebarContext();

const expandedSubGroup = ref(null);
const popoverRef = ref(null);
const topPosition = ref(0);
const isRTL = useMapGetter('accounts/isRTL');

const toggleSubGroup = name => {
  expandedSubGroup.value = expandedSubGroup.value === name ? null : name;
};

const navigateAndClose = to => {
  router.push(to);
  emit('close');
};

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
  // Position the popover based on the trigger's position
  if (props.triggerRect) {
    const viewportHeight = window.innerHeight;
    const popoverHeight = popoverRef.value?.offsetHeight || 300;
    let top = props.triggerRect.top;

    // If popover would go below viewport, adjust upward
    if (top + popoverHeight > viewportHeight - 20) {
      top = Math.max(20, viewportHeight - popoverHeight - 20);
    }
    topPosition.value = top;
  }
});
</script>

<template>
  <Teleport to="body">
    <div
      ref="popoverRef"
      class="fixed z-[100] min-w-[200px] max-w-[280px]"
      :dir="isRTL ? 'rtl' : 'ltr'"
      :style="{
        left: isRTL ? 'auto' : `${sidebarWidth + 8}px`,
        right: isRTL ? `${sidebarWidth + 8}px` : 'auto',
        top: `${topPosition}px`,
      }"
      @mouseenter="emit('mouseenter')"
      @mouseleave="emit('mouseleave')"
    >
      <div
        class="bg-n-alpha-3 backdrop-blur-[100px] border border-n-weak rounded-xl shadow-lg py-2 px-2"
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
            <li v-if="child.children" class="py-0.5">
              <button
                class="flex items-center gap-2 px-2 py-1.5 w-full rounded-lg text-n-slate-11 hover:bg-n-alpha-2 text-left rtl:text-right"
                @click="toggleSubGroup(child.name)"
              >
                <Icon
                  v-if="child.icon"
                  :icon="child.icon"
                  class="size-4 flex-shrink-0"
                />
                <span class="flex-1 truncate text-sm">{{ child.label }}</span>
                <span
                  class="size-3 transition-transform"
                  :class="[
                    isRTL ? 'i-lucide-chevron-left' : 'i-lucide-chevron-right',
                    { 'rotate-90': expandedSubGroup === child.name },
                  ]"
                />
              </button>
              <ul
                v-if="expandedSubGroup === child.name"
                class="m-0 p-0 list-none ltr:pl-4 rtl:pr-4 mt-1"
              >
                <li
                  v-for="subChild in child.children.filter(c =>
                    isAllowed(c.to)
                  )"
                  :key="subChild.name"
                  class="py-0.5"
                >
                  <button
                    class="flex items-center gap-2 px-2 py-1.5 w-full rounded-lg text-sm text-left rtl:text-right"
                    :class="{
                      'text-n-slate-12 bg-n-alpha-2':
                        activeChild?.name === subChild.name,
                      'text-n-slate-11 hover:bg-n-alpha-2':
                        activeChild?.name !== subChild.name,
                    }"
                    @click="navigateAndClose(subChild.to)"
                  >
                    <component
                      :is="
                        typeof subChild.icon === 'object' ? subChild.icon : Icon
                      "
                      v-if="subChild.icon"
                      :icon="
                        typeof subChild.icon === 'string' ? subChild.icon : null
                      "
                      class="size-4 flex-shrink-0"
                    />
                    <span class="flex-1 truncate">{{ subChild.label }}</span>
                  </button>
                </li>
              </ul>
            </li>
            <!-- Direct child item -->
            <li v-else class="py-0.5">
              <button
                class="flex items-center gap-2 px-2 py-1.5 w-full rounded-lg text-sm text-left rtl:text-right"
                :class="{
                  'text-n-slate-12 bg-n-alpha-2':
                    activeChild?.name === child.name,
                  'text-n-slate-11 hover:bg-n-alpha-2':
                    activeChild?.name !== child.name,
                }"
                @click="navigateAndClose(child.to)"
              >
                <component
                  :is="typeof child.icon === 'object' ? child.icon : Icon"
                  v-if="child.icon"
                  :icon="typeof child.icon === 'string' ? child.icon : null"
                  class="size-4 flex-shrink-0"
                />
                <span class="flex-1 truncate">{{ child.label }}</span>
              </button>
            </li>
          </template>
        </ul>
      </div>
    </div>
  </Teleport>
</template>
