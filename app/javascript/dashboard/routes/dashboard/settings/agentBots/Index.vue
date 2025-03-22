<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';

import AgentBotRow from './components/AgentBotRow.vue';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const accountId = useMapGetter('getCurrentAccountId');
const agentBots = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const confirmDialog = ref(null);

const onConfigureNewBot = () => {
  router.push({
    name: 'agent_bots_csml_new',
  });
};

onMounted(() => {
  store.dispatch('agentBots/get');
});

const onDeleteAgentBot = async bot => {
  const ok = await confirmDialog.value.showConfirmation();

  if (ok) {
    try {
      await store.dispatch('agentBots/delete', bot.id);
      useAlert(t('AGENT_BOTS.DELETE.API.SUCCESS_MESSAGE'));
    } catch (error) {
      useAlert(t('AGENT_BOTS.DELETE.API.ERROR_MESSAGE'));
    }
  }
};

const onEditAgentBot = bot => {
  router.push(
    frontendURL(
      `accounts/${accountId.value}/settings/agent-bots/csml/${bot.id}`
    )
  );
};
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('AGENT_BOTS.LIST.LOADING')"
    :no-records-found="!agentBots.length"
    :no-records-message="$t('AGENT_BOTS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('AGENT_BOTS.HEADER')"
        :description="$t('AGENT_BOTS.DESCRIPTION')"
        :link-text="$t('AGENT_BOTS.LEARN_MORE')"
        feature-name="agent_bots"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('AGENT_BOTS.ADD.TITLE')"
            @click="onConfigureNewBot"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="flex-1 overflow-auto">
        <table class="divide-y divide-slate-75 dark:divide-slate-700">
          <tbody class="divide-y divide-n-weak text-n-slate-11">
            <AgentBotRow
              v-for="(agentBot, index) in agentBots"
              :key="agentBot.id"
              :agent-bot="agentBot"
              :index="index"
              @delete="onDeleteAgentBot"
              @edit="onEditAgentBot"
            />
          </tbody>
        </table>
        <woot-confirm-modal
          ref="confirmDialog"
          :title="$t('AGENT_BOTS.DELETE.TITLE')"
          :description="$t('AGENT_BOTS.DELETE.DESCRIPTION')"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
