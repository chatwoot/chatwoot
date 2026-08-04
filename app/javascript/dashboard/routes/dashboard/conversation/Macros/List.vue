<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert, useTrack } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Draggable from 'vuedraggable';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MacroItem from './MacroItem.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const { accountScopedUrl } = useAccount();
const { uiSettings, updateUISettings } = useUISettings();
const { checkMissingAttributes } = useConversationRequiredAttributes();

const dragging = ref(false);
const executingMacroId = ref(null);
const pendingExecution = ref(null);
const resolveAttributesModalRef = ref(null);

const macros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');
const conversationById = useMapGetter('getConversationById');

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

const customAttributesFor = conversationId =>
  conversationById.value(conversationId)?.custom_attributes || {};

// change_status is not offered by the macro builder, but the API accepts it and
// it resolves the conversation just like resolve_conversation does. Its param is
// stored as raw JSON, so the status can be the enum name or its integer value.
const RESOLVED_STATUSES = ['resolved', 1];

const resolvesConversation = macro =>
  macro.actions.some(
    ({ action_name: name, action_params: params }) =>
      name === 'resolve_conversation' ||
      (name === 'change_status' && RESOLVED_STATUSES.includes(params?.[0]))
  );

const runMacro = async ({ macro, conversationId }, skippedResolve = false) => {
  try {
    executingMacroId.value = macro.id;
    await store.dispatch('macros/execute', {
      macroId: macro.id,
      conversationIds: [conversationId],
    });
    useTrack(CONVERSATION_EVENTS.EXECUTED_A_MACRO);
    useAlert(
      skippedResolve
        ? t('MACROS.EXECUTE.EXECUTED_WITHOUT_RESOLVING')
        : t('MACROS.EXECUTE.EXECUTED_SUCCESSFULLY')
    );
  } catch (error) {
    useAlert(t('MACROS.ERROR'));
  } finally {
    executingMacroId.value = null;
  }
};

const onExecuteMacro = macro => {
  const execution = { macro, conversationId: props.conversationId };

  if (!resolvesConversation(macro)) {
    runMacro(execution);
    return;
  }

  const customAttributes = customAttributesFor(execution.conversationId);
  const { hasMissing, missing } = checkMissingAttributes(customAttributes);
  if (!hasMissing) {
    runMacro(execution);
    return;
  }

  pendingExecution.value = execution;
  resolveAttributesModalRef.value?.open(missing, customAttributes);
};

const onAttributesSubmit = async ({ attributes }) => {
  const execution = pendingExecution.value;
  pendingExecution.value = null;

  try {
    await store.dispatch('updateCustomAttributes', {
      conversationId: execution.conversationId,
      customAttributes: {
        ...customAttributesFor(execution.conversationId),
        ...attributes,
      },
    });
  } catch (error) {
    useAlert(t('CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR'));
    return;
  }

  runMacro(execution);
};

// Dismissing the modal still runs the macro, the backend leaves the
// conversation unresolved while the required attributes are empty.
const onAttributesClose = () => {
  if (!pendingExecution.value) return;

  runMacro(pendingExecution.value, true);
  pendingExecution.value = null;
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
          :is-executing="executingMacroId === element.id"
          @execute="onExecuteMacro(element)"
        />
      </template>
    </Draggable>
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="onAttributesSubmit"
      @close="onAttributesClose"
    />
  </div>
</template>

<style scoped lang="scss">
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
