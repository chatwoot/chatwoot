<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import MessageApi from 'dashboard/api/inbox/message';
import Button from 'dashboard/components-next/button/Button.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

const props = defineProps({
  conversationId: { type: Number, required: true },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const { getPlainText } = useMessageFormatter();
const { run, abort, isPending } = useAbortableRequest();
const popover = ref(null);
const input = ref(null);
const query = ref('');
const messages = ref([]);
const hasMore = ref(false);
const hasSearched = ref(false);
const error = ref('');
const isJumping = ref(false);

const results = computed(() => {
  const escapedQuery = query.value
    .trim()
    .replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return messages.value.map(message => ({
    ...message,
    parts: getPlainText(message.content || '').split(
      new RegExp(`(${escapedQuery})`, 'ig')
    ),
  }));
});

const reset = () => {
  abort();
  messages.value = [];
  hasMore.value = false;
  hasSearched.value = false;
  error.value = '';
};
watch(query, reset, { flush: 'sync' });

const onShow = async () => {
  await nextTick();
  input.value?.focus();
};
const onHide = () => {
  reset();
  query.value = '';
};

const search = async (before = undefined) => {
  if (!query.value.trim()) return;
  error.value = '';
  if (!before) {
    messages.value = [];
    hasMore.value = false;
    hasSearched.value = false;
  }
  try {
    const response = await run(signal =>
      MessageApi.search(
        props.conversationId,
        { q: query.value.trim(), before },
        { signal }
      )
    );
    if (!response) return;
    messages.value.push(...response.data.payload);
    hasMore.value = response.data.meta.has_more;
    hasSearched.value = true;
  } catch {
    error.value = t('CONVERSATION.IN_CONVERSATION_SEARCH.ERROR');
  }
};

const jumpToMessage = async messageId => {
  isJumping.value = true;
  error.value = '';
  try {
    await store.dispatch('fetchMessagesThrough', {
      conversationId: props.conversationId,
      messageId,
    });
    if (store.getters.getSelectedChat.id !== props.conversationId) return;
    await router.replace({ query: { ...route.query, messageId } });
    await nextTick();
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
    popover.value?.hide();
  } catch {
    error.value = t('CONVERSATION.IN_CONVERSATION_SEARCH.JUMP_ERROR');
  } finally {
    isJumping.value = false;
  }
};
</script>

<template>
  <Popover ref="popover" @show="onShow" @hide="onHide">
    <template #default="{ isOpen }">
      <Button
        v-tooltip="t('CONVERSATION.IN_CONVERSATION_SEARCH.TITLE')"
        icon="i-lucide-search"
        :aria-label="t('CONVERSATION.IN_CONVERSATION_SEARCH.TITLE')"
        :aria-expanded="isOpen"
        slate
        ghost
        sm
      />
    </template>
    <template #content="{ hide }">
      <section
        :aria-label="t('CONVERSATION.IN_CONVERSATION_SEARCH.TITLE')"
        class="w-[min(24rem,calc(100vw-2rem))] p-4 flex flex-col gap-3"
      >
        <div class="flex items-center justify-between gap-2">
          <h3 class="text-sm font-medium text-n-slate-12 m-0">
            {{ t('CONVERSATION.IN_CONVERSATION_SEARCH.TITLE') }}
          </h3>
          <Button
            icon="i-lucide-x"
            :aria-label="t('GENERAL.CLOSE')"
            slate
            ghost
            xs
            @click="hide"
          />
        </div>
        <form class="flex items-center gap-2" @submit.prevent="search()">
          <input
            ref="input"
            v-model="query"
            type="search"
            maxlength="200"
            :aria-label="t('CONVERSATION.IN_CONVERSATION_SEARCH.TITLE')"
            :placeholder="t('CONVERSATION.IN_CONVERSATION_SEARCH.PLACEHOLDER')"
            class="min-w-0 flex-1 !mb-0"
          />
          <Button
            type="submit"
            icon="i-lucide-search"
            :aria-label="t('CONVERSATION.IN_CONVERSATION_SEARCH.SUBMIT')"
            :disabled="!query.trim() || isPending || isJumping"
            :is-loading="isPending"
            sm
          />
        </form>
        <p v-if="error" role="alert" class="text-sm text-n-ruby-11 m-0">
          {{ error }}
        </p>
        <div aria-live="polite" class="text-sm text-n-slate-11">
          <p v-if="isPending" class="m-0">{{ t('SEARCH.SEARCHING_DATA') }}</p>
          <p v-else-if="hasSearched && !results.length" class="m-0">
            {{ t('CONVERSATION.IN_CONVERSATION_SEARCH.EMPTY') }}
          </p>
          <p v-else-if="!hasSearched && !error" class="m-0">
            {{ t('CONVERSATION.IN_CONVERSATION_SEARCH.HINT') }}
          </p>
        </div>
        <div
          v-if="results.length"
          class="max-h-80 overflow-y-auto flex flex-col gap-2"
        >
          <button
            v-for="message in results"
            :key="message.id"
            type="button"
            :disabled="isJumping"
            class="text-start rounded-lg p-3 border border-n-weak hover:bg-n-alpha-2 disabled:opacity-50"
            @click="jumpToMessage(message.id)"
          >
            <span
              class="flex justify-between gap-2 text-xs text-n-slate-11 mb-2"
            >
              <span>{{ dynamicTime(message.created_at) }}</span>
              <span v-if="message.private">{{ t('SEARCH.PRIVATE') }}</span>
            </span>
            <span class="text-sm text-n-slate-12 break-words line-clamp-4">
              <template v-for="(part, index) in message.parts" :key="index">
                <mark v-if="index % 2" class="bg-n-amber-3 text-n-slate-12">{{
                  part
                }}</mark>
                <template v-else>{{ part }}</template>
              </template>
            </span>
          </button>
          <Button
            v-if="hasMore"
            :label="t('SEARCH.LOAD_MORE')"
            :disabled="isPending || isJumping"
            slate
            faded
            sm
            @click="search(messages[messages.length - 1].id)"
          />
        </div>
      </section>
    </template>
  </Popover>
</template>
