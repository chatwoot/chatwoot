<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
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

const helpURL = computed(() => getHelpUrlForFeature('agent_bots'));

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

const botWebhookDisplay = bot =>
  bot.outgoing_url || bot.bot_config?.webhook_url || '';

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
      <div
        class="flex flex-col gap-6 pb-2 sm:flex-row sm:items-end sm:justify-between"
      >
        <div class="min-w-0 space-y-2">
          <h2 class="text-3xl font-bold tracking-tight text-on-surface mb-0">
            {{ t('AGENT_BOTS.HEADER') }}
          </h2>
          <p class="text-on-primary-container max-w-2xl text-base mb-0">
            {{ t('AGENT_BOTS.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('AGENT_BOTS.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
        <Button
          solid
          teal
          lg
          icon="i-lucide-plus"
          :label="$t('AGENT_BOTS.ADD.TITLE')"
          class="w-full shrink-0 font-bold rounded-xl shadow-none hover:shadow-[0_0_20px_rgba(4,190,153,0.4)] active:scale-[0.98] sm:w-auto"
          @click="openAddModal"
        />
      </div>
    </template>
    <template #body>
      <div
        class="overflow-x-auto rounded-2xl shadow-xl border border-outline-variant/10"
      >
        <div class="min-w-[44rem] bg-surface-container-low">
          <div
            class="grid grid-cols-12 px-6 py-4 bg-surface-container-high/30 border-b border-surface-container-high/50"
          >
            <div
              class="col-span-5 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.DETAILS') }}
            </div>
            <div
              class="col-span-5 text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.URL') }}
            </div>
            <div
              class="col-span-2 text-right text-[11px] font-bold uppercase tracking-widest text-tertiary/60"
            >
              {{ t('AGENT_BOTS.LIST.TABLE_HEADER.ACTIONS') }}
            </div>
          </div>
          <div class="divide-y divide-surface-container-high/30">
            <div
              v-for="bot in agentBots"
              :key="bot.id"
              class="grid grid-cols-12 items-center px-6 py-4 transition-all duration-200 hover:bg-surface-container-high/40"
            >
              <div class="col-span-5 flex min-w-0 items-center gap-4">
                <Avatar :name="bot.name" :src="bot.thumbnail" :size="40" />
                <div class="min-w-0">
                  <span
                    class="block text-sm font-bold break-words text-on-surface"
                  >
                    {{ bot.name }}
                    <span
                      v-if="bot.system_bot"
                      class="ms-1 inline-block rounded-md bg-surface-container-high px-2.5 py-1 text-xs font-medium text-tertiary/70 align-middle"
                    >
                      {{ $t('AGENT_BOTS.GLOBAL_BOT_BADGE') }}
                    </span>
                  </span>
                  <span
                    class="mt-0.5 block text-xs text-on-primary-container line-clamp-2"
                  >
                    {{ bot.description }}
                  </span>
                </div>
              </div>
              <div class="col-span-5 min-w-0 px-2 ltr:pl-0 rtl:pr-0">
                <p
                  class="mb-0 truncate font-mono text-xs text-on-primary-container"
                  :title="botWebhookDisplay(bot)"
                >
                  {{ botWebhookDisplay(bot) || '—' }}
                </p>
              </div>
              <div class="col-span-2 flex justify-end gap-1">
                <button
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.EDIT.BUTTON_TEXT')"
                  type="button"
                  :disabled="loading[bot.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-secondary hover:opacity-100 focus-visible:ring-2 focus-visible:ring-secondary/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openEditModal(bot)"
                >
                  <Spinner v-if="loading[bot.id]" class="size-5" />
                  <Icon v-else icon="i-lucide-pen" class="size-5" />
                </button>
                <button
                  v-if="!bot.system_bot"
                  v-tooltip.top="t('AGENT_BOTS.DELETE.BUTTON_TEXT')"
                  type="button"
                  :disabled="loading[bot.id]"
                  class="rounded-lg p-2 text-tertiary opacity-70 outline-none transition-all hover:bg-surface-container-high hover:text-error hover:opacity-100 focus-visible:ring-2 focus-visible:ring-error/40 disabled:pointer-events-none disabled:opacity-40"
                  @click="openDeletePopup(bot)"
                >
                  <Spinner v-if="loading[bot.id]" class="size-5" />
                  <Icon v-else icon="i-lucide-trash-2" class="size-5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      <p class="mt-6 text-xs font-medium text-on-primary-container">
        {{ t('AGENT_BOTS.LIST.SHOWING_COUNT', { count: agentBots.length }) }}
      </p>
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
