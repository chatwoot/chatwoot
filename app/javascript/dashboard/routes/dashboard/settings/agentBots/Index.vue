<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import AgentBotModal from './components/AgentBotModal.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const store = useStore();
const { t } = useI18n();

const agentBots = useMapGetter('agentBots/getBots');
const uiFlags = useMapGetter('agentBots/getUIFlags');

const selectedBot = ref({});
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const agentBotModalRef = ref(null);
const agentBotDeleteDialogRef = ref(null);

const tableHeaders = computed(() => {
  return [
    t('AGENT_BOTS.LIST.TABLE_HEADER.DETAILS'),
    t('AGENT_BOTS.LIST.TABLE_HEADER.URL'),
  ];
});

const selectedBotName = computed(() => selectedBot.value?.name || '');

const openAddModal = () => {
  modalType.value = MODAL_TYPES.CREATE;
  selectedBot.value = {};
  agentBotModalRef.value.dialogRef.open();
};

const openEditModal = bot => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedBot.value = bot;
  agentBotModalRef.value.dialogRef.open();
};

const openDeletePopup = bot => {
  selectedBot.value = bot;
  agentBotDeleteDialogRef.value.open();
};

const deleteAgentBot = async id => {
  try {
    await store.dispatch('agentBots/delete', id);
    useAlert(t('AGENT_BOTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AGENT_BOTS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedBot.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedBot.value.id] = true;
  deleteAgentBot(selectedBot.value.id);
  agentBotDeleteDialogRef.value.close();
};

onMounted(() => {
  store.dispatch('agentBots/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('AGENT_BOTS.LIST.LOADING')"
    :no-records-found="!agentBots.length"
    :no-records-message="t('AGENT_BOTS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('AGENT_BOTS.HEADER')"
        :description="t('AGENT_BOTS.DESCRIPTION')"
        :link-text="t('AGENT_BOTS.LEARN_MORE')"
        feature-name="agent_bots"
      >
        <template #actions>
          <Button
            icon="i-lucide-circle-plus"
            :label="$t('AGENT_BOTS.ADD.TITLE')"
            @click="openAddModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <table class="min-w-full overflow-x-auto divide-y divide-n-strong">
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 font-semibold text-left ltr:pr-4 rtl:pl-4 text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="flex-1 divide-y divide-n-weak text-n-slate-12">
          <tr v-for="bot in agentBots" :key="bot.id">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-row items-center gap-4">
                <Avatar
                  :name="bot.name"
                  :src="bot.thumbnail"
                  :size="40"
                  rounded-full
                />
                <div>
                  <span class="block font-medium break-words">
                    {{ bot.name }}
                    <span
                      v-if="bot.system_bot"
                      class="text-xs text-n-slate-12 bg-n-blue-5 inline-block rounded-md py-0.5 px-1 ltr:ml-1 rtl:mr-1"
                    >
                      {{ $t('AGENT_BOTS.GLOBAL_BOT_BADGE') }}
                    </span>
                  </span>
                  <span class="text-sm text-n-slate-11">
                    {{ bot.description }}
                  </span>
                </div>
              </div>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4 text-sm">
              {{ bot.outgoing_url || bot.bot_config?.webhook_url }}
            </td>
            <td class="py-4 min-w-xs">
              <div class="flex gap-1 justify-end">
                <Button
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  :is-loading="loading[bot.id]"
                  @click="openEditModal(bot)"
                />
                <Button
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
                  icon="i-lucide-trash-2"
                  xs
                  ruby
                  faded
                  :is-loading="loading[bot.id]"
                  @click="openDeletePopup(bot)"
                />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </template>

    <AgentBotModal
      ref="agentBotModalRef"
      :type="modalType"
      :selected-bot="selectedBot"
    />

    <Dialog
      ref="agentBotDeleteDialogRef"
      type="alert"
      :title="t('AGENT_BOTS.DELETE.CONFIRM.TITLE')"
      :description="
        t('AGENT_BOTS.DELETE.CONFIRM.MESSAGE', { name: selectedBotName })
      "
      :is-loading="uiFlags.isDeleting"
      :confirm-button-label="t('AGENT_BOTS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('AGENT_BOTS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
