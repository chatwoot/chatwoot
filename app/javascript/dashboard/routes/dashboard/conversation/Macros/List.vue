<script setup>
import { onMounted, ref } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMacroExecution } from 'dashboard/composables/useMacroExecution';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';

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
const { accountScopedUrl } = useAccount();
const { orderedMacros } = useOrderedMacros();
const {
  executingMacroId,
  execute,
  submitPendingAttributes,
  dismissPendingAttributes,
} = useMacroExecution();

const dragging = ref(false);
const resolveAttributesModalRef = ref(null);

const macros = useMapGetter('macros/getMacros');
const uiFlags = useMapGetter('macros/getUIFlags');

const onDragEnd = () => {
  dragging.value = false;
};

const onExecuteMacro = macro => {
  const pending = execute(macro, props.conversationId);
  if (pending) {
    resolveAttributesModalRef.value?.open(
      pending.missing,
      pending.customAttributes
    );
  }
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
      @submit="submitPendingAttributes"
      @close="dismissPendingAttributes"
    />
  </div>
</template>

<style scoped lang="scss">
.ghost {
  @apply opacity-50 bg-n-slate-3 dark:bg-n-slate-9;
}
</style>
