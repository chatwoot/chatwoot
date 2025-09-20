<script setup>
import { computed, ref, useAttrs } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import VoiceAPI from 'dashboard/api/channels/voice';

const props = defineProps({
  phone: { type: String, default: '' },
  contactId: { type: [String, Number], default: null },
  label: { type: String, default: '' },
  icon: { type: [String, Object, Function], default: '' },
  size: { type: String, default: 'sm' },
  tooltipLabel: { type: String, default: '' },
});

defineOptions({ inheritAttrs: false });
const attrs = useAttrs();
const route = useRoute();

const inboxesList = useMapGetter('inboxes/getInboxes');
const voiceInboxes = computed(() =>
  (inboxesList.value || []).filter(
    inbox => inbox.channel_type === INBOX_TYPES.VOICE
  )
);
const hasVoiceInboxes = computed(() => voiceInboxes.value.length > 0);
const hasPhone = computed(() => !!(props.phone || '').trim());

const shouldRender = computed(() => hasVoiceInboxes.value && hasPhone.value);

const dialogRef = ref(null);

const onClick = async () => {
  if (voiceInboxes.value.length > 1) {
    dialogRef.value?.open();
    return;
  }
  const [inbox] = voiceInboxes.value;
  if (!inbox) return;
  const targetContactId = props.contactId ?? route.params.contactId;
  await VoiceAPI.initiateCall(targetContactId, inbox.id);
};

const onPickInbox = async inbox => {
  const targetContactId = props.contactId ?? route.params.contactId;
  await VoiceAPI.initiateCall(targetContactId, inbox.id);
  dialogRef.value?.close();
};
</script>

<template>
  <span class="contents">
    <Button
      v-if="shouldRender"
      v-tooltip.top-end="tooltipLabel || null"
      v-bind="attrs"
      :label="label"
      :icon="icon"
      :size="size"
      @click="onClick"
    />

    <Dialog
      v-if="shouldRender && voiceInboxes.length > 1"
      ref="dialogRef"
      :title="$t('CONTACT_PANEL.VOICE_INBOX_PICKER.TITLE')"
      show-cancel-button
      :show-confirm-button="false"
      width="md"
    >
      <div class="flex flex-col gap-2">
        <button
          v-for="inbox in voiceInboxes"
          :key="inbox.id"
          type="button"
          class="flex items-center justify-between w-full px-4 py-2 text-left rounded-lg hover:bg-n-alpha-2"
          @click="onPickInbox(inbox)"
        >
          <div class="flex items-center gap-2">
            <span class="i-ri-phone-fill text-n-slate-10" />
            <span class="text-sm text-n-slate-12">{{ inbox.name }}</span>
          </div>
          <span v-if="inbox.phone_number" class="text-xs text-n-slate-10">
            {{ inbox.phone_number }}
          </span>
        </button>
      </div>
    </Dialog>
  </span>
</template>
