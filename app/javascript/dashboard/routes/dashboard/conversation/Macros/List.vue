<script setup>
import { computed, onMounted, ref } from 'vue';
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

const store = useStore();
const { accountScopedUrl } = useAccount();
const { uiSettings, updateUISettings } = useUISettings();

const dragging = ref(false);

const macros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');

const MACROS_ORDER_KEY = 'macros_display_order';

const orderedMacros = computed({
  get: () => {
    // Get saved order array and current macros
    const savedOrder = uiSettings.value?.[MACROS_ORDER_KEY] ?? [];
    const currentMacros = macros.value ?? [];

    // Return unmodified macros if not present or macro is not available
    if (!savedOrder.length || !currentMacros.length) {
      return currentMacros;
    }

    // Create a Map of id -> position for faster lookups
    const orderMap = new Map(savedOrder.map((id, index) => [id, index]));

    return [...currentMacros].sort((a, b) => {
      // Use Infinity for items not in saved order (pushes them to end)
      const aPos = orderMap.get(a.id) ?? Infinity;
      const bPos = orderMap.get(b.id) ?? Infinity;
      return aPos - bPos;
    });
  },
  set: newOrder => {
    // Update settings with array of ids from new order
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
    <Draggable
      v-if="!uiFlags.isFetching && macros.length"
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
