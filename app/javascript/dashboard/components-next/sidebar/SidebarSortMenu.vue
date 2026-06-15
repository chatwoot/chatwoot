<script setup>
import { computed, nextTick, onBeforeUnmount, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';
import { SIDEBAR_SORT_KEYS } from 'dashboard/helper/sidebarSort';

const props = defineProps({
  activeSort: {
    type: String,
    default: '',
  },
  options: {
    type: Array,
    default: () => [],
  },
  openOnHover: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['sort', 'toggle']);

const SORT_OPTION_GROUPS = [
  {
    key: 'created',
    options: [SIDEBAR_SORT_KEYS.CREATED_DESC, SIDEBAR_SORT_KEYS.CREATED_ASC],
  },
  {
    key: 'alphabetical',
    options: [
      SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC,
      SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC,
    ],
  },
  {
    key: 'unread_count',
    options: [
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC,
      SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC,
    ],
  },
];

const { t } = useI18n();
const isOpen = ref(false);
const triggerRef = ref(null);
const popoverRef = ref(null);
let closeTimer;

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  popoverRef,
  isOpen,
  { align: 'start' }
);

const getSortOptionLabel = option => {
  if (option === SIDEBAR_SORT_KEYS.CREATED_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.CREATED_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.CREATED_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.CREATED_ASC');
  }

  if (option === SIDEBAR_SORT_KEYS.ALPHABETICAL_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.ALPHABETICAL_ASC');
  }

  if (option === SIDEBAR_SORT_KEYS.ALPHABETICAL_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.ALPHABETICAL_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.UNREAD_COUNT_DESC) {
    return t('SIDEBAR.SORT_OPTIONS.UNREAD_COUNT_DESC');
  }

  if (option === SIDEBAR_SORT_KEYS.UNREAD_COUNT_ASC) {
    return t('SIDEBAR.SORT_OPTIONS.UNREAD_COUNT_ASC');
  }

  return '';
};

const getSortGroupLabel = groupKey => {
  if (groupKey === 'created') {
    return t('SIDEBAR.SORT_GROUPS.CREATED');
  }

  if (groupKey === 'alphabetical') {
    return t('SIDEBAR.SORT_GROUPS.ALPHABETICAL');
  }

  if (groupKey === 'unread_count') {
    return t('SIDEBAR.SORT_GROUPS.UNREAD_COUNT');
  }

  return '';
};

const sortMenuSections = computed(() =>
  SORT_OPTION_GROUPS.map(group => ({
    title: getSortGroupLabel(group.key),
    items: group.options
      .filter(option => props.options.includes(option))
      .map(option => ({
        label: getSortOptionLabel(option),
        value: option,
        action: 'sort',
        isActive: option === props.activeSort,
      })),
  })).filter(section => section.items.length)
);

const clearCloseTimer = () => {
  if (closeTimer) {
    clearTimeout(closeTimer);
    closeTimer = null;
  }
};

const openMenu = async () => {
  clearCloseTimer();
  isOpen.value = true;
  emit('toggle', true);

  await nextTick();
  updatePosition();
};

const closeMenu = () => {
  clearCloseTimer();
  isOpen.value = false;
  emit('toggle', false);
};

const scheduleClose = () => {
  clearCloseTimer();
  closeTimer = setTimeout(closeMenu, 150);
};

const handleTriggerEnter = () => {
  if (props.openOnHover) openMenu();
};

const handleTriggerLeave = () => {
  if (props.openOnHover) scheduleClose();
};

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  closeMenu();
};

const handleSortChange = ({ value }) => {
  emit('sort', value);
  closeMenu();
};

onBeforeUnmount(clearCloseTimer);
</script>

<template>
  <div
    ref="triggerRef"
    class="relative invisible flex-shrink-0 opacity-0 pointer-events-none transition-opacity duration-150 group-hover/sidebar-section:visible group-hover/sidebar-section:opacity-100 group-hover/sidebar-section:pointer-events-auto"
    :class="{ '!visible !opacity-100 !pointer-events-auto': isOpen }"
    @mouseenter="handleTriggerEnter"
    @mouseleave="handleTriggerLeave"
  >
    <Button
      :title="t('SIDEBAR.SORT_TOOLTIP')"
      icon="i-lucide-arrow-up-down"
      ghost
      slate
      xs
      class="!size-6 !text-n-slate-11 hover:!text-n-slate-12"
      :class="{ '!bg-n-alpha-2': isOpen }"
      @click.stop="openMenu"
    />
    <TeleportWithDirection>
      <DropdownMenu
        v-if="isOpen"
        ref="popoverRef"
        v-on-click-outside="handleClickOutside"
        data-popover-content
        :menu-sections="sortMenuSections"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="w-60 !fixed"
        @action="handleSortChange"
        @mouseenter="clearCloseTimer"
        @mouseleave="handleTriggerLeave"
      >
        <template #trailing-icon="{ item }">
          <span
            v-if="item.isActive"
            class="i-lucide-check ms-auto size-4 flex-shrink-0 text-n-slate-11"
          />
        </template>
      </DropdownMenu>
    </TeleportWithDirection>
  </div>
</template>
