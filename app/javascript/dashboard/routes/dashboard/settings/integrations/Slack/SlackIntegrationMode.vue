<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  hook: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const modeOptions = computed(() => [
  {
    value: 'two_way',
    label: t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.TWO_WAY.LABEL'),
    description: t(
      'INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.TWO_WAY.DESCRIPTION'
    ),
  },
  {
    value: 'alerts_only',
    label: t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.ALERTS_ONLY.LABEL'),
    description: t(
      'INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.ALERTS_ONLY.DESCRIPTION'
    ),
  },
]);

const selectedMode = computed(
  () => props.hook.settings?.integration_mode || 'two_way'
);

const updateMode = async mode => {
  if (mode === selectedMode.value) return;
  try {
    await store.dispatch('integrations/updateHook', {
      hookId: props.hook.id,
      settings: { ...props.hook.settings, integration_mode: mode },
    });
    useAlert(
      t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.API.SUCCESS_MESSAGE')
    );
  } catch (error) {
    useAlert(
      t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.API.ERROR_MESSAGE')
    );
  }
};
</script>

<template>
  <div
    class="px-6 py-5 outline outline-n-container outline-1 bg-n-card rounded-xl"
  >
    <h5 class="mb-1 text-n-slate-12 text-heading-2">
      {{ t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.TITLE') }}
    </h5>
    <p class="text-n-slate-11 text-body-main">
      {{ t('INTEGRATION_SETTINGS.SLACK.INTEGRATION_MODE.DESCRIPTION') }}
    </p>
    <div class="flex flex-col gap-3 mt-4">
      <label
        v-for="option in modeOptions"
        :key="option.value"
        class="flex items-start gap-3 cursor-pointer"
      >
        <input
          type="radio"
          name="slack-integration-mode"
          :value="option.value"
          :checked="selectedMode === option.value"
          class="mt-1"
          @change="updateMode(option.value)"
        />
        <div>
          <span class="text-n-slate-12 text-body-main font-medium">
            {{ option.label }}
          </span>
          <p class="mb-0 text-n-slate-11 text-body-main">
            {{ option.description }}
          </p>
        </div>
      </label>
    </div>
  </div>
</template>
