<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  searchKey: {
    type: String,
    default: '',
  },
  enabledMenuOptions: {
    type: Array,
    default: () => [],
  },
  position: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['selectAction']);

const { t } = useI18n();

const EDITOR_ACTIONS = [
  {
    value: 'h1',
    labelKey: 'SLASH_COMMANDS.HEADING_1',
    icon: 'i-lucide-heading-1',
    menuKey: 'h1',
  },
  {
    value: 'h2',
    labelKey: 'SLASH_COMMANDS.HEADING_2',
    icon: 'i-lucide-heading-2',
    menuKey: 'h2',
  },
  {
    value: 'h3',
    labelKey: 'SLASH_COMMANDS.HEADING_3',
    icon: 'i-lucide-heading-3',
    menuKey: 'h3',
  },
  {
    value: 'strong',
    labelKey: 'SLASH_COMMANDS.BOLD',
    icon: 'i-lucide-bold',
    menuKey: 'strong',
  },
  {
    value: 'em',
    labelKey: 'SLASH_COMMANDS.ITALIC',
    icon: 'i-lucide-italic',
    menuKey: 'em',
  },
  {
    value: 'insertTable',
    labelKey: 'SLASH_COMMANDS.TABLE',
    icon: 'i-lucide-table',
    menuKey: 'insertTable',
  },
  {
    value: 'strike',
    labelKey: 'SLASH_COMMANDS.STRIKETHROUGH',
    icon: 'i-lucide-strikethrough',
    menuKey: 'strike',
  },
  {
    value: 'code',
    labelKey: 'SLASH_COMMANDS.CODE',
    icon: 'i-lucide-code',
    menuKey: 'code',
  },
  {
    value: 'bulletList',
    labelKey: 'SLASH_COMMANDS.BULLET_LIST',
    icon: 'i-lucide-list',
    menuKey: 'bulletList',
  },
  {
    value: 'orderedList',
    labelKey: 'SLASH_COMMANDS.ORDERED_LIST',
    icon: 'i-lucide-list-ordered',
    menuKey: 'orderedList',
  },
];

const listContainerRef = ref(null);
const selectedIndex = ref(0);

const items = computed(() => {
  const search = props.searchKey.toLowerCase();
  return EDITOR_ACTIONS.filter(action => {
    if (!props.enabledMenuOptions.includes(action.menuKey)) return false;
    if (!search) return true;
    return t(action.labelKey).toLowerCase().includes(search);
  });
});

const hasItems = computed(() => items.value.length > 0);

const menuStyle = computed(() => {
  if (!props.position) return {};
  const style = { top: `${props.position.top}px` };
  if (props.position.right != null) {
    style.right = `${props.position.right}px`;
  } else {
    style.left = `${props.position.left}px`;
  }
  return style;
});

const adjustScroll = () => {
  nextTick(() => {
    const container = listContainerRef.value;
    if (!container) return;
    const el = container.querySelector(`#slash-item-${selectedIndex.value}`);
    if (el) {
      el.scrollIntoView({ block: 'nearest', behavior: 'auto' });
    }
  });
};

const onSelect = () => {
  const item = items.value[selectedIndex.value];
  if (item) emit('selectAction', item.value);
};

useKeyboardNavigableList({
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
});

// Reset selection when filtered items change
watch(items, () => {
  selectedIndex.value = 0;
});

const onHover = index => {
  selectedIndex.value = index;
};

const onItemClick = index => {
  selectedIndex.value = index;
  onSelect();
};

defineExpose({ hasItems });
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="hasItems"
    ref="listContainerRef"
    class="bg-n-alpha-3 backdrop-blur-[100px] outline outline-1 outline-n-container absolute rounded-xl z-50 flex flex-col min-w-[10rem] shadow-lg p-2 overflow-auto max-h-[15rem]"
    :style="menuStyle"
  >
    <button
      v-for="(item, index) in items"
      :id="`slash-item-${index}`"
      :key="item.value"
      type="button"
      class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 border-0 rounded-lg text-n-slate-12 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2"
      :class="{
        'bg-n-alpha-1 dark:bg-n-alpha-2': index === selectedIndex,
      }"
      @mouseover="onHover(index)"
      @click="onItemClick(index)"
    >
      <Icon :icon="item.icon" class="flex-shrink-0 size-3.5" />
      <span class="min-w-0 text-sm truncate">
        {{ t(item.labelKey) }}
      </span>
    </button>
  </div>
</template>
