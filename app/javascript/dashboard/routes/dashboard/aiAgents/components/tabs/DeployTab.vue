<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import AiAgentsAPI from 'dashboard/api/saas/aiAgents';

const props = defineProps({
  agent: { type: Object, required: true },
});

const { t } = useI18n();
const store = useStore();

const inboxes = useMapGetter('inboxes/getInboxes');
const linkedInboxes = ref([]);
const isFetching = ref(false);
const connectDialogRef = ref(null);
const selectedInboxId = ref('');

const availableInboxes = computed(() => {
  const linkedIds = new Set(linkedInboxes.value.map(l => l.inbox_id));
  return (inboxes.value || []).filter(inbox => !linkedIds.has(inbox.id));
});

const getInboxName = inboxId => {
  const inbox = (inboxes.value || []).find(i => i.id === inboxId);
  return inbox?.name || `Inbox #${inboxId}`;
};

const getInboxChannelType = inboxId => {
  const inbox = (inboxes.value || []).find(i => i.id === inboxId);
  return inbox?.channel_type?.replace('Channel::', '') || '';
};

const fetchLinkedInboxes = async () => {
  isFetching.value = true;
  try {
    const { data } = await AiAgentsAPI.show(props.agent.id);
    linkedInboxes.value = data.inboxes || [];
  } catch {
    // Inboxes come from show response
  } finally {
    isFetching.value = false;
  }
};

const handleConnect = () => {
  selectedInboxId.value = '';
  nextTick(() => connectDialogRef.value?.open());
};

const submitConnect = async () => {
  if (!selectedInboxId.value) return;
  try {
    const { data } = await AiAgentsAPI.createInboxLink(props.agent.id, {
      inbox_id: Number(selectedInboxId.value),
    });
    linkedInboxes.value.push(data);
    useAlert(t('AI_AGENTS.DEPLOY.CONNECT.SUCCESS_MESSAGE'));
    connectDialogRef.value?.close();
  } catch {
    useAlert(t('AI_AGENTS.DEPLOY.CONNECT.ERROR_MESSAGE'));
  }
};

const handleToggleAutoReply = async link => {
  try {
    const newAutoReply = !link.auto_reply;
    await AiAgentsAPI.updateInboxLink(props.agent.id, link.id, {
      auto_reply: newAutoReply,
    });
    const idx = linkedInboxes.value.findIndex(l => l.id === link.id);
    if (idx !== -1) {
      linkedInboxes.value[idx] = {
        ...linkedInboxes.value[idx],
        auto_reply: newAutoReply,
      };
    }
  } catch {
    useAlert(t('AI_AGENTS.DEPLOY.UPDATE_ERROR'));
  }
};

const handleDisconnect = async link => {
  try {
    await AiAgentsAPI.deleteInboxLink(props.agent.id, link.id);
    linkedInboxes.value = linkedInboxes.value.filter(l => l.id !== link.id);
    useAlert(t('AI_AGENTS.DEPLOY.DISCONNECT.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('AI_AGENTS.DEPLOY.DISCONNECT.ERROR_MESSAGE'));
  }
};

onMounted(() => {
  store.dispatch('inboxes/get');
  fetchLinkedInboxes();
});
</script>

<template>
  <div class="flex flex-col gap-6 max-w-3xl">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-base font-medium text-n-slate-12">
          {{ t('AI_AGENTS.TABS.DEPLOY') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('AI_AGENTS.DEPLOY.DESCRIPTION') }}
        </p>
      </div>
      <Button
        :label="t('AI_AGENTS.DEPLOY.CONNECT.TITLE')"
        icon="i-lucide-plus"
        size="sm"
        @click="handleConnect"
      />
    </div>

    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!linkedInboxes.length"
      class="flex flex-col items-center py-12 gap-3"
    >
      <div class="i-lucide-inbox size-10 text-n-slate-8" />
      <p class="text-sm text-n-slate-11">
        {{ t('AI_AGENTS.DEPLOY.EMPTY') }}
      </p>
    </div>

    <div v-else class="flex flex-col gap-4">
      <CardLayout v-for="link in linkedInboxes" :key="link.id">
        <div class="flex items-center justify-between w-full">
          <div class="flex items-center gap-3 min-w-0">
            <div class="i-lucide-inbox size-5 text-n-slate-11 shrink-0" />
            <div class="min-w-0">
              <h3 class="text-sm font-medium text-n-slate-12 truncate">
                {{ getInboxName(link.inbox_id) }}
              </h3>
              <span class="text-xs text-n-slate-11">
                {{ getInboxChannelType(link.inbox_id) }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-3 shrink-0">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                :checked="link.auto_reply"
                class="rounded"
                @change="handleToggleAutoReply(link)"
              />
              <span class="text-xs text-n-slate-11">
                {{ t('AI_AGENTS.DEPLOY.AUTO_REPLY') }}
              </span>
            </label>
            <span
              class="inline-flex items-center gap-1.5 text-xs text-n-slate-11"
            >
              <span
                class="size-1.5 rounded-full"
                :class="
                  link.status === 'active' ? 'bg-n-teal-9' : 'bg-n-amber-9'
                "
              />
              {{ link.status }}
            </span>
            <Button
              icon="i-lucide-unlink"
              variant="ghost"
              color="ruby"
              size="xs"
              @click="handleDisconnect(link)"
            />
          </div>
        </div>
      </CardLayout>
    </div>

    <Dialog
      ref="connectDialogRef"
      type="edit"
      :title="t('AI_AGENTS.DEPLOY.CONNECT.TITLE')"
      :show-cancel-button="false"
      :show-confirm-button="false"
      overflow-y-auto
      @close="() => {}"
    >
      <form class="flex flex-col gap-4" @submit.prevent="submitConnect">
        <fieldset class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('AI_AGENTS.DEPLOY.SELECT_INBOX') }}
          </label>
          <select
            v-model="selectedInboxId"
            class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option value="" disabled>
              {{ t('AI_AGENTS.DEPLOY.SELECT_INBOX_PLACEHOLDER') }}
            </option>
            <option
              v-for="inbox in availableInboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }} ({{
                inbox.channel_type?.replace('Channel::', '')
              }})
            </option>
          </select>
        </fieldset>

        <div class="flex justify-end gap-2 pt-2">
          <Button
            type="button"
            variant="faded"
            color="slate"
            :label="t('AI_AGENTS.FORM.CANCEL')"
            @click="connectDialogRef?.close()"
          />
          <Button
            type="submit"
            :label="t('AI_AGENTS.DEPLOY.CONNECT.BUTTON')"
            :disabled="!selectedInboxId"
          />
        </div>
      </form>
      <template #footer />
    </Dialog>
  </div>
</template>
