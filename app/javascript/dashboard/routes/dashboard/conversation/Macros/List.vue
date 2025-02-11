<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Draggable from 'vuedraggable';
import MacroItem from './MacroItem.vue';

defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { accountScopedUrl } = useAccount();
const { uiSettings, updateUISettings } = useUISettings();

const dragging = ref(false);

const macros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');

const MACROS_ORDER_KEY = 'macros_display_order';

const orderedMacros = computed({
  get: () => {
    const savedOrder = uiSettings.value?.[MACROS_ORDER_KEY] ?? [];
    const currentMacros = macros.value ?? [];

    // If no saved order or macros, return the current macros
    if (!savedOrder.length || !currentMacros.length) {
      return currentMacros;
    }

    // Sort macros based on saved order
    return [...currentMacros].sort((a, b) => {
      const aPos = savedOrder.indexOf(a.id);
      const bPos = savedOrder.indexOf(b.id);

      // Handle cases where one or both items are not in the saved order
      if (aPos === -1 && bPos === -1) return 0; // Both not in order
      if (aPos === -1) return 1; // Only `a` is not in order
      if (bPos === -1) return -1; // Only `b` is not in order

      return aPos - bPos; // Compare positions
    });
  },
  set: newOrder => {
    updateUISettings({
      [MACROS_ORDER_KEY]: newOrder.map(({ id }) => id),
    });
  },
});

const onDragEnd = () => {
  dragging.value = false;
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
        <woot-button variant="smooth" icon="add" size="tiny" class="mt-1">
          {{ $t('MACROS.HEADER_BTN_TXT') }}
        </woot-button>
      </router-link>
    </div>
    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('MACROS.LOADING')"
    />
    <Draggable
      v-if="!uiFlags.isFetching && macros.length"
      v-model="orderedMacros"
      :disabled="isMacroPreviewActive"
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
          class="drag-handle cursor-grab"
        />
      </template>
    </Draggable>
  </div>
</template>

<style scoped lang="scss">
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
