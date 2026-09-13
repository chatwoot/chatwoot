<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useIntervalFn } from '@vueuse/core';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import api from 'dashboard/api/captain/aproposSessions';
import Button from 'dashboard/components-next/button/Button.vue';
import MessageList from 'dashboard/components-next/captain/assistant/MessageList.vue';
import ActivityPanel from 'dashboard/components-next/captain/apropos/ActivityPanel.vue';

const POLL_INTERVAL = 1500;
const BUSY_STATUSES = ['queued', 'running'];
const route = useRoute();
const { t } = useI18n();
const { run, abort, isPending } = useAbortableRequest();
const session = ref(null);
const sessions = ref([]);
const draft = ref('');
const error = ref('');
const sending = ref(false);
const busy = computed(() => BUSY_STATUSES.includes(session.value?.status));
const messages = computed(() =>
  (session.value?.messages || []).map(message => ({
    sender: message.role,
    content: message.content,
    isError: message.error,
  }))
);
const trace = computed(() => session.value?.trace || []);

function reportError(exception) {
  error.value = exception.response?.data?.error || t('CAPTAIN_ASK.ERROR');
}

async function loadSession(id) {
  error.value = '';
  try {
    const response = await run(signal => api.read(id, { signal }));
    if (response) session.value = response.data;
  } catch (exception) {
    reportError(exception);
  }
}

function newChat() {
  abort();
  session.value = null;
  draft.value = '';
  error.value = '';
}

async function loadSessions() {
  newChat();
  sessions.value = [];
  try {
    const response = await run(signal => api.list({ signal }));
    if (!response) return;
    sessions.value = response.data;
    if (sessions.value.length) await loadSession(sessions.value[0].id);
  } catch (exception) {
    reportError(exception);
  }
}

async function send() {
  if (!draft.value.trim() || busy.value || sending.value || isPending.value)
    return;
  sending.value = true;
  error.value = '';
  const accountId = route.params.accountId;
  const message = draft.value.trim();
  try {
    const response = session.value
      ? await api.update(session.value.id, { message })
      : await api.create({ message });
    if (route.params.accountId !== accountId) return;
    session.value = response.data;
    draft.value = '';
    sessions.value = [
      response.data,
      ...sessions.value.filter(item => item.id !== response.data.id),
    ];
  } catch (exception) {
    if (route.params.accountId === accountId) reportError(exception);
  } finally {
    sending.value = false;
  }
}

useIntervalFn(async () => {
  if (!busy.value || isPending.value || sending.value) return;
  await loadSession(session.value.id);
}, POLL_INTERVAL);

watch(() => route.params.accountId, loadSessions, { immediate: true });
</script>

<template>
  <div class="flex flex-col w-full h-full min-h-0">
    <header
      class="flex items-center justify-between gap-4 p-6 border-b border-n-weak"
    >
      <div>
        <h1 class="text-heading-2 text-n-slate-12">
          {{ t('CAPTAIN_ASK.TITLE') }}
        </h1>
        <p class="text-body-main text-n-slate-11">
          {{ t('CAPTAIN_ASK.SUBTITLE') }}
        </p>
      </div>
      <Button
        :label="t('CAPTAIN_ASK.NEW_CHAT')"
        icon="i-lucide-plus"
        :disabled="sending"
        @click="newChat"
      />
    </header>
    <div class="flex flex-col lg:flex-row flex-1 min-h-0">
      <section class="flex flex-col flex-1 min-w-0 min-h-0">
        <div class="px-6 py-3">
          <label for="apropos-history" class="text-sm text-n-slate-11">
            {{ t('CAPTAIN_ASK.HISTORY') }}
          </label>
          <select
            id="apropos-history"
            :value="session?.id || ''"
            :disabled="sending"
            class="w-full mt-2 rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 text-sm"
            @change="
              $event.target.value ? loadSession($event.target.value) : newChat()
            "
          >
            <option value="">{{ t('CAPTAIN_ASK.NEW_CHAT') }}</option>
            <option v-for="item in sessions" :key="item.id" :value="item.id">
              {{ item.messages[0]?.content || t('CAPTAIN_ASK.NEW_CHAT') }}
            </option>
          </select>
        </div>
        <div
          v-if="!messages.length"
          class="flex-1 flex flex-col justify-center px-8 py-6 gap-3"
        >
          <h2 class="text-heading-3 text-n-slate-12">
            {{ t('CAPTAIN_ASK.EMPTY_TITLE') }}
          </h2>
          <p class="text-body-main text-n-slate-11">
            {{ t('CAPTAIN_ASK.EMPTY_BODY') }}
          </p>
          <Button
            variant="ghost"
            :label="t('CAPTAIN_ASK.EXAMPLE')"
            @click="draft = t('CAPTAIN_ASK.EXAMPLE')"
          />
        </div>
        <MessageList :messages="messages" :is-loading="busy" />
        <form class="p-6 border-t border-n-weak" @submit.prevent="send">
          <p v-if="error" role="alert" class="text-sm text-n-ruby-11 mb-3">
            {{ error }}
          </p>
          <label for="apropos-message" class="sr-only">{{
            t('CAPTAIN_ASK.MESSAGE')
          }}</label>
          <textarea
            id="apropos-message"
            v-model="draft"
            rows="3"
            maxlength="10000"
            class="w-full rounded-xl border border-n-weak bg-n-solid-1 text-n-slate-12 text-body-main"
            :placeholder="t('CAPTAIN_ASK.PLACEHOLDER')"
            :disabled="busy || sending"
          />
          <div class="flex items-center justify-between mt-3 gap-4">
            <span class="text-xs text-n-slate-10" aria-live="polite">
              {{
                busy ? t('CAPTAIN_ASK.WORKING') : t('CAPTAIN_ASK.ACCOUNT_SCOPE')
              }}
            </span>
            <Button
              type="submit"
              :label="t('CAPTAIN_ASK.SEND')"
              :disabled="busy || sending || isPending || !draft.trim()"
              :is-loading="sending"
              icon="i-lucide-arrow-up"
            />
          </div>
        </form>
      </section>
      <ActivityPanel :key="session?.id || 'new'" :events="trace" />
    </div>
  </div>
</template>
