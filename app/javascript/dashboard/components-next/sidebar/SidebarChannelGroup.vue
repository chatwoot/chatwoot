<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useSidebarContext } from './provider';
import SidebarGroupLeaf from './SidebarGroupLeaf.vue';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const props = defineProps({
  name: { type: String, required: true },
  label: { type: String, required: true },
  to: { type: Object, required: true },
  children: { type: Array, default: () => [] },
  badgeCount: { type: Number, default: 0 },
  activeChild: { type: Object, default: undefined },
});

const { t } = useI18n();
const { expandedChannelGroups, toggleChannelGroup, isAllowed } =
  useSidebarContext();

const isExpanded = computed(() =>
  expandedChannelGroups.value.includes(props.name)
);
const accessibleChildren = computed(() =>
  props.children.filter(child => isAllowed(child.to))
);
const isActive = computed(
  () =>
    props.activeChild?.name === props.name ||
    accessibleChildren.value.some(
      child => child.name === props.activeChild?.name
    )
);
</script>

<template>
  <li class="list-none min-w-0 py-0.5">
    <div
      class="flex items-center min-w-0 rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
      :class="{ 'bg-n-alpha-2 text-n-slate-12': isActive }"
    >
      <RouterLink
        :to="to"
        :title="label"
        class="flex min-w-0 flex-1 items-center gap-2 px-2 py-1.5"
      >
        <span class="i-lucide-folder size-4 flex-shrink-0" />
        <span class="truncate flex-1 text-sm">{{ label }}</span>
        <SidebarUnreadBadge :count="badgeCount" />
      </RouterLink>
      <button
        type="button"
        class="flex items-center justify-center size-7 me-1 rounded-md hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-n-brand"
        :aria-label="
          isExpanded
            ? t('SIDEBAR.CHANNEL_GROUP.COLLAPSE', { name: label })
            : t('SIDEBAR.CHANNEL_GROUP.EXPAND', { name: label })
        "
        :aria-expanded="isExpanded"
        @click="toggleChannelGroup(name)"
      >
        <span
          class="size-3"
          :class="
            isExpanded
              ? 'i-lucide-chevron-down'
              : 'i-lucide-chevron-right rtl:rotate-180'
          "
        />
      </button>
    </div>
    <ul v-if="isExpanded" class="m-0 p-0 list-none">
      <SidebarGroupLeaf
        v-for="child in accessibleChildren"
        :key="child.name"
        v-bind="child"
        :active="activeChild?.name === child.name"
        thin-tree-line
      />
    </ul>
  </li>
</template>
