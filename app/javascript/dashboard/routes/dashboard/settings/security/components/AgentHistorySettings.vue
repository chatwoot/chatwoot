<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import SectionLayout from '../../account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const { accountId } = useAccount();
const getAccount = useMapGetter('accounts/getAccount');
const uiFlags = useMapGetter('accounts/getUIFlags');

const agentHistoryDays = ref(30);

const initialize = () => {
  const account = getAccount.value(accountId.value) || {};
  const configuredDays = account.agent_history_days;
  agentHistoryDays.value =
    configuredDays === null || configuredDays === undefined
      ? 30
      : configuredDays;
};

onMounted(initialize);

const updateSettings = async () => {
  const days = Number(agentHistoryDays.value);
  if (Number.isNaN(days) || days < 0 || days > 365) {
    useAlert(t('SECURITY_SETTINGS.AGENT_HISTORY.VALIDATION_ERROR'));
    return;
  }

  try {
    await store.dispatch('accounts/update', {
      agent_history_days: days,
    });
    useAlert(t('SECURITY_SETTINGS.AGENT_HISTORY.SUCCESS'));
  } catch {
    useAlert(t('SECURITY_SETTINGS.AGENT_HISTORY.ERROR'));
  }
};
</script>

<template>
  <SectionLayout
    :title="t('SECURITY_SETTINGS.AGENT_HISTORY.TITLE')"
    :description="t('SECURITY_SETTINGS.AGENT_HISTORY.DESCRIPTION')"
  >
    <WithLabel
      :label="t('SECURITY_SETTINGS.AGENT_HISTORY.LABEL')"
      :help="t('SECURITY_SETTINGS.AGENT_HISTORY.HELP')"
    >
      <NextInput
        v-model.number="agentHistoryDays"
        type="number"
        min="0"
        max="365"
        class="w-full max-w-xs"
        :placeholder="t('SECURITY_SETTINGS.AGENT_HISTORY.PLACEHOLDER')"
      />
    </WithLabel>
    <NextButton
      class="mt-4"
      :label="t('SECURITY_SETTINGS.AGENT_HISTORY.UPDATE_BUTTON')"
      :is-loading="uiFlags.isUpdating"
      @click="updateSettings"
    />
  </SectionLayout>
</template>
