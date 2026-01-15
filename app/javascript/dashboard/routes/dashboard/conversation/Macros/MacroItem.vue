<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { CONVERSATION_EVENTS } from '../../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

import NextButton from 'dashboard/components-next/button/Button.vue';
import MacroPreview from './MacroPreview.vue';

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
const triggerRef = ref(null);
const dropdownRef = ref(null);

const { position } = useDropdownPosition(triggerRef, dropdownRef, showPreview);

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
    class="relative flex items-center justify-between leading-4 rounded-md h-10"
    :class="showPreview ? 'cursor-default' : 'drag-handle cursor-grab'"
  >
    <div class="flex items-center justify-start gap-1">
      <NextButton
        ref="triggerRef"
        v-tooltip.top-start="$t('MACROS.EXECUTE.PREVIEW')"
        icon="i-lucide-info"
        slate
        :variant="!showPreview ? 'ghost' : 'faded'"
        xs
        class="[&>span]:size-3.5"
        @click="toggleMacroPreview"
      />
      <span class="text-body-main text-n-slate-12 truncate">
        {{ macro.name }}
      </span>
    </div>

    <NextButton
      :label="$t('MACROS.EXECUTE.RUN')"
      slate
      link
      sm
      class="hover:!no-underline !text-n-slate-11 !py-2"
      :is-loading="isExecuting"
      @click="executeMacro(macro)"
    />
    <transition name="menu-slide">
      <MacroPreview
        v-if="showPreview"
        ref="dropdownRef"
        v-on-clickaway="closeMacroPreview"
        :macro="macro"
        class="ltr:ml-8 rtl:mr-8 !-mt-8 ltr:left-1 rtl:right-1"
        :class="position.class"
      />
    </transition>
  </div>
</template>
