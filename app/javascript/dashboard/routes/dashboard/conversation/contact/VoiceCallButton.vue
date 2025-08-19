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
const hasPhone = computed(() => !!(props.contactPhone || '').trim());
const disabled = computed(() => !hasVoice.value || !hasPhone.value);

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
  <!-- Hide completely if no phone or no voice inbox -->
  <div v-if="hasVoice && hasPhone" class="relative">
    <!-- Single inbox: simple call button -->
    <template v-if="hasVoice && voiceInboxes.length === 1">
      <Button
        v-if="text"
        :label="$t('CONTACT_PANEL.MAKE_CALL')"
        size="sm"
        :disabled="disabled"
        @click="call(voiceInboxes[0].id)"
      />
      <NextButton
        v-else
        v-tooltip.top-end="$t('CONTACT_PANEL.MAKE_CALL')"
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
        :label="$t('CONTACT_PANEL.MAKE_CALL')"
        size="sm"
        :disabled="disabled"
        @click="showModal = true"
      />
      <NextButton
        v-else
        v-tooltip.top-end="$t('CONTACT_PANEL.MAKE_CALL')"
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
