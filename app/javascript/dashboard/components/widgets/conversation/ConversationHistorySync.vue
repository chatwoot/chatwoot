<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';

// The end of what this inbox holds, and either the offer to ask the phone for more or
// the word that there is no more to ask for.
//
// Placed at the top of the thread rather than in a settings screen because that is where
// the want appears: somebody reading a conversation that starts mid-sentence. It is also
// the shape of the mechanism -- the provider walks one chat backwards from one anchor, so
// a control per chat is the honest surface for it.
//
// WhatsApp only ever says a chat is finished on the answer to a request, never before
// one, so the two states are ordered rather than alternative: the offer stands until an
// answer retires it, which is the same order WhatsApp Web shows them in.

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  exhausted: { type: Boolean, default: false },
  // An inbox locked to one conversation files the history in it, so it appears here.
  singleConversation: { type: Boolean, default: false },
});

const store = useStore();
const { t } = useI18n();

// The phone answers on the webhook minutes later, or never -- it has to be awake and it
// declines to resend a stretch it has already handed over. So the press reports that the
// request went out. Where the messages land is not known until they do: each is filed in
// the thread that was current when it was sent, usually an older one than this, which
// the agent reaches with the previous-conversation link. An inbox locked to one
// conversation is the exception, and the messages appear here.
const requesting = ref(false);
const requestOlder = async () => {
  requesting.value = true;
  try {
    await store.dispatch('syncHistory', props.conversationId);
    useAlert(
      props.singleConversation
        ? t('CONVERSATION.HISTORY_SYNC.REQUESTED')
        : t('CONVERSATION.HISTORY_SYNC.REQUESTED_BY_DATE')
    );
  } catch (error) {
    useAlert(t('CONVERSATION.HISTORY_SYNC.ERROR'));
  } finally {
    requesting.value = false;
  }
};
</script>

<template>
  <li class="flex flex-col items-center gap-1 py-3 list-none">
    <span v-if="exhausted" class="text-xs text-n-slate-11">
      {{ $t('CONVERSATION.HISTORY_SYNC.EXHAUSTED') }}
    </span>
    <NextButton
      v-if="!exhausted"
      faded
      slate
      sm
      :is-loading="requesting"
      :disabled="requesting"
      @click="requestOlder"
    >
      {{ $t('CONVERSATION.HISTORY_SYNC.BUTTON') }}
    </NextButton>
    <span v-if="!exhausted" class="text-xs text-n-slate-11">
      {{ $t('CONVERSATION.HISTORY_SYNC.HELP') }}
    </span>
  </li>
</template>
