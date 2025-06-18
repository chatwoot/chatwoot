<script>
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAI } from 'dashboard/composables/useAI';
import { OPEN_AI_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  emits: ['close'],

  setup() {
    const { updateUISettings } = useUISettings();
    const { recordAnalytics } = useAI();
    const v$ = useVuelidate();

    return { updateUISettings, v$, recordAnalytics };
  },
  data() {
    return {
      value: '',
    };
  },
  validations: {
    value: {
      required,
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },

    onDismiss() {
      useAlert(
        this.$t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.DISMISS_MESSAGE')
      );
      this.updateUISettings({
        is_open_ai_cta_modal_dismissed: true,
      });
      this.onClose();
    },

    async finishOpenAI() {
      const payload = {
        app_id: 'openai',
        settings: {
          api_key: this.value,
        },
      };
      try {
        await this.$store.dispatch('integrations/createHook', payload);
        this.alertMessage = this.$t(
          'INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.SUCCESS_MESSAGE'
        );
        this.recordAnalytics(
          OPEN_AI_EVENTS.ADDED_AI_INTEGRATION_VIA_CTA_BUTTON
        );
        this.onClose();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.ADD.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
    openOpenAIDoc() {
      window.open('https://www.chatwoot.com/blog/v2-17', '_blank');
    },
  },
};
</script>

<template>
  <div class="flex-1 min-w-0 px-0">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.TITLE')"
      :header-content="$t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.DESC')"
    />
    <form
      class="flex flex-col flex-wrap modal-content"
      @submit.prevent="finishOpenAI"
    >
      <div class="w-full mt-2">
        <woot-input
          v-model="value"
          type="text"
          :class="{ error: v$.value.$error }"
          :placeholder="
            $t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.KEY_PLACEHOLDER')
          "
          @blur="v$.value.$touch"
        />
      </div>
      <div class="flex flex-row justify-between w-full gap-2 px-0 py-2">
        <NextButton
          ghost
          type="button"
          class="!px-3"
          :label="
            $t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.BUTTONS.NEED_HELP')
          "
          @click.prevent="openOpenAIDoc"
        />
        <div class="flex items-center gap-1">
          <NextButton
            faded
            slate
            type="reset"
            :label="
              $t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.BUTTONS.DISMISS')
            "
            @click.prevent="onDismiss"
          />
          <NextButton
            type="submit"
            :disabled="v$.value.$invalid"
            :label="$t('INTEGRATION_SETTINGS.OPEN_AI.CTA_MODAL.BUTTONS.FINISH')"
          />
        </div>
      </div>
    </form>
  </div>
</template>
