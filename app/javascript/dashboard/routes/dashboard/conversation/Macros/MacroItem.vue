<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import MacroPreview from './MacroPreview.vue';
import { CONVERSATION_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const isExecuting = ref(false);
const showPreview = ref(false);

const executeMacro = async macro => {
  try {
    isExecuting.value = true;
    await store.dispatch('macros/execute', {
      macroId: macro.id,
      conversationIds: [props.conversationId],
    });
    useTrack(CONVERSATION_EVENTS.EXECUTED_A_MACRO);
    useAlert(t('MACROS.EXECUTE.EXECUTED_SUCCESSFULLY'));
  } catch (error) {
    useAlert(t('MACROS.ERROR'));
  } finally {
    isExecuting.value = false;
  }
};

const toggleMacroPreview = () => {
  showPreview.value = !showPreview.value;
};

const closeMacroPreview = () => {
  showPreview.value = false;
};
</script>

<template>
  <div
    class="relative flex items-center justify-between leading-4 rounded-md button secondary clear"
  >
    <span class="overflow-hidden whitespace-nowrap text-ellipsis">
      {{ macro.name }}
    </span>
    <div class="flex items-center gap-1 justify-end">
      <woot-button
        v-tooltip.left-start="$t('MACROS.EXECUTE.PREVIEW')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="info"
        @click="toggleMacroPreview"
      />
      <woot-button
        v-tooltip.left-start="$t('MACROS.EXECUTE.BUTTON_TOOLTIP')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="play-circle"
        :is-loading="isExecuting"
        @click="executeMacro(macro)"
      />
    </div>
    <transition name="menu-slide">
      <MacroPreview
        v-if="showPreview"
        v-on-clickaway="closeMacroPreview"
        :macro="macro"
      />
    </transition>
  </div>
</template>
