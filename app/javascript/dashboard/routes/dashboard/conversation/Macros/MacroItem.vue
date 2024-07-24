<template>
  <div class="macro button secondary clear">
    <span class="overflow-hidden whitespace-nowrap text-ellipsis">{{
      macro.name
    }}</span>
    <div class="flex items-center gap-1 macros-actions">
      <woot-button
        v-tooltip.left-start="$t('MACROS.EXECUTE.PREVIEW')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="info"
        @click="toggleMacroPreview(macro)"
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
      <macro-preview
        v-if="showPreview"
        v-on-clickaway="closeMacroPreview"
        :macro="macro"
      />
    </transition>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import MacroPreview from './MacroPreview.vue';
import { CONVERSATION_EVENTS } from '../../../../helper/AnalyticsHelper/events';

export default {
  components: {
    MacroPreview,
  },
  props: {
    macro: {
      type: Object,
      required: true,
    },
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      isExecuting: false,
      showPreview: false,
    };
  },
  methods: {
    async executeMacro(macro) {
      try {
        this.isExecuting = true;
        await this.$store.dispatch('macros/execute', {
          macroId: macro.id,
          conversationIds: [this.conversationId],
        });
        this.$track(CONVERSATION_EVENTS.EXECUTED_A_MACRO);
        useAlert(this.$t('MACROS.EXECUTE.EXECUTED_SUCCESSFULLY'));
      } catch (error) {
        useAlert(this.$t('MACROS.ERROR'));
      } finally {
        this.isExecuting = false;
      }
    },
    toggleMacroPreview() {
      this.showPreview = !this.showPreview;
    },
    closeMacroPreview() {
      this.showPreview = false;
    },
  },
};
</script>

<style scoped lang="scss">
.macro {
  @apply relative flex items-center justify-between leading-4;

  .macros-actions {
    @apply flex items-center justify-end;
  }
}
</style>
