<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import VoiceAPI from 'dashboard/api/channels/voice';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
  contactPhone: { type: String, default: '' },
  text: { type: Boolean, default: false },
});

const store = useStore();
const voiceInboxes = computed(
  () => store.getters['inboxes/getVoiceInboxes'] || []
);
const hasVoice = computed(() => (voiceInboxes.value || []).length > 0);
const disabled = computed(() => !hasVoice.value || !props.contactPhone);

const showModal = ref(false);

const call = async inboxId => {
  try {
    await VoiceAPI.initiateCall(props.contactId, inboxId);
  } catch (e) {
    // swallow for MVP; errors surface via toasts
  } finally {
    showModal.value = false;
  }
};
</script>

<template>
  <div class="relative">
    <!-- Single inbox: simple call button -->
    <template v-if="hasVoice && voiceInboxes.length === 1">
      <Button
        v-if="text"
        :label="$t('CONVERSATION.VOICE_CALL.CALL_CONTACT')"
        size="sm"
        :disabled="disabled"
        @click="call(voiceInboxes[0].id)"
      />
      <NextButton
        v-else
        v-tooltip.top-end="$t('CONVERSATION.VOICE_CALL.CALL_CONTACT')"
        icon="i-ph-phone"
        slate
        faded
        sm
        :disabled="disabled"
        @click="call(voiceInboxes[0].id)"
      />
    </template>

    <!-- Multiple inboxes: open selection modal -->
    <template v-else>
      <Button
        v-if="text"
        :label="$t('CONVERSATION.VOICE_CALL.CALL_CONTACT')"
        size="sm"
        :disabled="disabled"
        @click="showModal = true"
      />
      <NextButton
        v-else
        v-tooltip.top-end="$t('CONVERSATION.VOICE_CALL.CALL_CONTACT')"
        icon="i-ph-phone"
        slate
        faded
        sm
        :disabled="disabled"
        @click="showModal = true"
      />
    </template>

    <woot-modal v-model:show="showModal" :on-close="() => (showModal = false)">
      <woot-modal-header
        :header-title="$t('CONVERSATION.VOICE_CALL.SELECT_NUMBER')"
      />
      <div class="p-4 space-y-2">
        <button
          v-for="inbox in voiceInboxes"
          :key="inbox.id"
          class="w-full text-left px-3 py-2 rounded-md border border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-700 text-sm text-slate-800 dark:text-slate-200"
          @click="call(inbox.id)"
        >
          <div class="font-medium">{{ inbox.name }}</div>
          <div class="text-xs text-slate-500">{{ inbox.phone_number }}</div>
        </button>
      </div>
    </woot-modal>
  </div>
</template>
