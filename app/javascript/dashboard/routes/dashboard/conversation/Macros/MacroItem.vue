<template>
  <div class="macro button secondary clear ">
    <span class="text-truncate">{{ macro.name }}</span>
    <div class="macros-actions">
      <woot-button
        v-tooltip.left-start="$t('MACROS.EXECUTE.PREVIEW')"
        size="tiny"
        variant="smooth"
        color-scheme="secondary"
        icon="info"
        class="margin-right-smaller"
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
import alertMixin from 'shared/mixins/alertMixin';
import { mixin as clickaway } from 'vue-clickaway';
import MacroPreview from './MacroPreview';
import AnalyticsHelper, {
  ANALYTICS_EVENTS,
} from '../../../../helper/AnalyticsHelper';
export default {
  components: {
    MacroPreview,
  },
  mixins: [alertMixin, clickaway],
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
        AnalyticsHelper.track(ANALYTICS_EVENTS.EXECUTED_A_MACRO);
        this.showAlert(this.$t('MACROS.EXECUTE.EXECUTED_SUCCESSFULLY'));
      } catch (error) {
        this.showAlert(this.$t('MACROS.ERROR'));
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
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  line-height: var(--space-normal);

  .macros-actions {
    display: flex;
    align-items: center;
    justify-content: flex-end;
  }
}
</style>
