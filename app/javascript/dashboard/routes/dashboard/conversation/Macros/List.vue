<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Draggable from 'vuedraggable';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MacroItem from './MacroItem.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { accountScopedUrl } = useAccount();
const { uiSettings, updateUISettings } = useUISettings();

const dragging = ref(false);
const collapsedFolders = ref({});

const macros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');

const MACROS_ORDER_KEY = 'macros_display_order';

const orderedMacros = computed({
  get: () => {
    const savedOrder = uiSettings.value?.[MACROS_ORDER_KEY] ?? [];
    const currentMacros = macros.value ?? [];

    if (!savedOrder.length || !currentMacros.length) {
      return currentMacros;
    }

    const orderMap = new Map(savedOrder.map((id, index) => [id, index]));

    return [...currentMacros].sort((a, b) => {
      const aPos = orderMap.get(a.id) ?? Infinity;
      const bPos = orderMap.get(b.id) ?? Infinity;
      return aPos - bPos;
    });
  },
  set: newOrder => {
    updateUISettings({
      [MACROS_ORDER_KEY]: newOrder.map(({ id }) => id),
    });
  },
});

const folderGroups = computed(() => {
  const groups = new Map();
  orderedMacros.value.forEach(macro => {
    const folder = (macro.folder || '').trim();
    const key = folder || '__uncategorized__';
    if (!groups.has(key)) {
      groups.set(key, {
        key,
        label: folder || t('MACROS.UNCATEGORIZED'),
        macros: [],
      });
    }
    groups.get(key).macros.push(macro);
  });

  return [...groups.values()].sort((a, b) => {
    if (a.key === '__uncategorized__') return 1;
    if (b.key === '__uncategorized__') return -1;
    return a.label.localeCompare(b.label);
  });
});

const hasMultipleFolders = computed(() => folderGroups.value.length > 1);

const toggleFolder = key => {
  const currentlyCollapsed = collapsedFolders.value[key] ?? true;
  collapsedFolders.value = {
    ...collapsedFolders.value,
    [key]: !currentlyCollapsed,
  };
};

// Collapsed by default so agents open folders in order.
const isFolderCollapsed = key => collapsedFolders.value[key] ?? true;

const onDragEnd = () => {
  dragging.value = false;
};

const onFolderOrderChange = (folderKey, newFolderMacros) => {
  const other = orderedMacros.value.filter(macro => {
    const key = (macro.folder || '').trim() || '__uncategorized__';
    return key !== folderKey;
  });
  orderedMacros.value = [...other, ...newFolderMacros];
};

onMounted(() => {
  store.dispatch('macros/get');
});
</script>

<template>
  <div>
    <div v-if="!uiFlags.isFetching && !macros.length" class="p-3">
      <p class="flex flex-col items-center justify-center h-full">
        {{ $t('MACROS.LIST.404') }}
      </p>
      <router-link :to="accountScopedUrl('settings/macros')">
        <NextButton
          faded
          xs
          icon="i-lucide-plus"
          class="mt-1"
          :label="$t('MACROS.HEADER_BTN_TXT')"
        />
      </router-link>
    </div>
    <div
      v-if="uiFlags.isFetching"
      class="flex items-center gap-2 justify-center p-6 text-n-slate-12"
    >
      <span class="text-sm">{{ $t('MACROS.LOADING') }}</span>
      <Spinner class="size-5" />
    </div>

    <template v-if="!uiFlags.isFetching && macros.length">
      <div v-if="hasMultipleFolders" class="flex flex-col gap-1 p-1">
        <div v-for="group in folderGroups" :key="group.key">
          <button
            type="button"
            class="flex w-full items-center justify-between gap-2 px-2 py-1.5 rounded-md text-start hover:bg-n-alpha-2"
            @click="toggleFolder(group.key)"
          >
            <span class="text-xs font-medium text-n-slate-11 truncate">
              {{ group.label }}
              <span class="font-normal">({{ group.macros.length }})</span>
            </span>
            <span
              class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform shrink-0"
              :class="{ '-rotate-90': isFolderCollapsed(group.key) }"
            />
          </button>
          <Draggable
            v-show="!isFolderCollapsed(group.key)"
            :model-value="group.macros"
            class="pl-1"
            animation="200"
            ghost-class="ghost"
            handle=".drag-handle"
            item-key="id"
            @update:model-value="
              value => onFolderOrderChange(group.key, value)
            "
            @start="dragging = true"
            @end="onDragEnd"
          >
            <template #item="{ element }">
              <MacroItem
                :key="element.id"
                :macro="element"
                :conversation-id="conversationId"
              />
            </template>
          </Draggable>
        </div>
      </div>
      <Draggable
        v-else
        v-model="orderedMacros"
        class="p-1"
        animation="200"
        ghost-class="ghost"
        handle=".drag-handle"
        item-key="id"
        @start="dragging = true"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <MacroItem
            :key="element.id"
            :macro="element"
            :conversation-id="conversationId"
          />
        </template>
      </Draggable>
    </template>
  </div>
</template>

<style scoped lang="scss">
.ghost {
  @apply opacity-50;
}
</style>
