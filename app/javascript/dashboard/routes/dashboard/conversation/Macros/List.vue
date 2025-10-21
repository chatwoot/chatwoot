<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import {
  useStore,
  useMapGetter,
  useStoreGetters,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Draggable from 'vuedraggable';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MacroItem from './MacroItem.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const getters = useStoreGetters();
const { accountScopedUrl } = useAccount();
const { uiSettings, updateUISettings } = useUISettings();

const dragging = ref(false);
const availableMacroIds = ref(null); // null = not loaded yet, [] = specific filter result

const allMacros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');
const sourceMappings = computed(() => store.state.macros.sourceMappings);
const inboxes = useMapGetter('inboxes/getInboxes');

const MACROS_ORDER_KEY = 'macros_display_order';

// Combined loading state - show loading only if store is fetching
const isLoading = computed(
  () => uiFlags.value.isFetching || uiFlags.value.isFetchingSources
);

// Filter macros based on source channel
const macros = computed(() => {
  const currentMacros = allMacros.value ?? [];

  // If still loading from store, return empty to avoid flash
  if (isLoading.value) {
    return [];
  }

  // If availableMacroIds is null, we haven't filtered yet - show all
  if (availableMacroIds.value === null) {
    return currentMacros;
  }

  // Filter macros based on the cached result from Vuex getter
  return currentMacros.filter(macro =>
    availableMacroIds.value.includes(macro.id)
  );
});

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

const loadAvailableMacros = () => {
  // Get the current conversation
  const conversation = getters.getConversationById.value(props.conversationId);
  if (!conversation || !conversation.inbox_id) {
    // If no conversation or inbox, show all macros
    availableMacroIds.value = [];
    return;
  }

  // Get the inbox to find the channel_id
  const allInboxes = getters['inboxes/getInboxes'].value;
  const inbox = allInboxes.find(i => i.id === conversation.inbox_id);

  if (!inbox || !inbox.channel_id) {
    // If no inbox or channel, show all macros
    availableMacroIds.value = [];
    return;
  }

  // Use cached data from Vuex store (already loaded on app init)
  // This is instant - no loading state needed
  availableMacroIds.value = getters['macros/getMacrosByChannel'].value(
    inbox.channel_id
  );
};

// Watch for conversation changes to reload macros
watch(
  () => props.conversationId,
  () => {
    loadAvailableMacros();
  }
);

// Watch for macros loading to complete, then filter
watch(
  () => isLoading.value,
  (loading, wasLoading) => {
    // When loading finishes, reload the available macros
    if (wasLoading && !loading) {
      loadAvailableMacros();
    }
  }
);

// Watch for sourceMappings to be populated
watch(
  sourceMappings,
  (newMappings, oldMappings) => {
    // When sourceMappings changes from empty to populated, reload
    const wasEmpty = !oldMappings || Object.keys(oldMappings).length === 0;
    const isPopulated = newMappings && Object.keys(newMappings).length > 0;
    if (wasEmpty && isPopulated) {
      loadAvailableMacros();
    }
  },
  { deep: true }
);

// Watch for inboxes to be loaded
watch(inboxes, (newInboxes, oldInboxes) => {
  // When inboxes load (from empty to populated), reload macros
  const wasEmpty = !oldInboxes || oldInboxes.length === 0;
  const isPopulated = newInboxes && newInboxes.length > 0;
  if (wasEmpty && isPopulated) {
    loadAvailableMacros();
  }
});

onMounted(() => {
  // Load available macros immediately (will use cached data if available)
  loadAvailableMacros();
});
</script>

<template>
  <div>
    <div v-if="!isLoading && !macros.length" class="p-3">
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
      v-if="isLoading"
      class="flex items-center gap-2 justify-center p-6 text-n-slate-12"
    >
      <span class="text-sm">{{ $t('MACROS.LOADING') }}</span>
      <Spinner class="size-5" />
    </div>
    <Draggable
      v-if="!isLoading && macros.length"
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
  </div>
</template>

<style scoped lang="scss">
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
