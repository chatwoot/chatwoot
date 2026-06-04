<script setup>
import { computed, ref, watch, onMounted, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { parsePhoneNumber } from 'libphonenumber-js';
import { useAlert } from 'dashboard/composables';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import VoiceAPI from 'dashboard/api/channel/voice/voiceAPIClient';
import { useCallsStore } from 'dashboard/stores/calls';
import NextButton from 'dashboard/components-next/button/Button.vue';

const POSITION_KEY = 'cw_voice_dialer_position_xy';

const store = useStore();
const callsStore = useCallsStore();
const { t } = useI18n();

const showDialer = ref(false);
const isCalling = ref(false);
const dialNumber = ref('');
const selectedInboxId = ref('');
const showMenu = ref(false);
const isHidden = ref(false);

const resolveRegionFromLocale = locale => {
  if (!locale) return null;
  const parts = locale.split(/[-_]/);
  if (parts.length < 2) return null;
  return parts[1].toUpperCase();
};

const normalizeDialNumber = value => {
  const trimmed = value.trim();
  if (!trimmed) return { number: '', isValid: false };

  let cleaned = trimmed.replace(/[^+\d]/g, '');
  if (cleaned.startsWith('+')) {
    cleaned = `+${cleaned.slice(1).replace(/\+/g, '')}`;
  } else {
    cleaned = cleaned.replace(/\+/g, '');
  }

  if (cleaned.startsWith('+')) {
    try {
      const parsed = parsePhoneNumber(cleaned);
      if (parsed?.isValid()) {
        return { number: parsed.number, isValid: true };
      }
    } catch (error) {
      // Keep raw cleaned value if parsing fails.
    }
    return { number: cleaned, isValid: false };
  }

  const locale =
    store.getters.getUISettings?.locale ||
    store.getters.getCurrentAccount?.locale;
  const region = resolveRegionFromLocale(locale);
  if (region) {
    try {
      const parsed = parsePhoneNumber(cleaned, region);
      if (parsed?.isValid()) {
        return { number: parsed.number, isValid: true };
      }
    } catch (error) {
      // Fall through to naive normalization.
    }
  }

  return { number: cleaned ? `+${cleaned}` : '', isValid: false };
};

const getStoredPosition = () => {
  try {
    const raw = localStorage.getItem(POSITION_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
};

const storePosition = value => {
  try {
    localStorage.setItem(POSITION_KEY, JSON.stringify(value));
  } catch {
    // Ignore storage errors.
  }
};

const position = ref(getStoredPosition() || { x: 0, y: 0 });
const fabRef = ref(null);
const isDragging = ref(false);
const dragStart = ref({ x: 0, y: 0 });
const dragOffset = ref({ x: 0, y: 0 });
const hasDragged = ref(false);

const inboxes = computed(() => store.getters['inboxes/getInboxes'] || []);
const voiceInboxes = computed(() =>
  inboxes.value.filter(inbox => inbox.channel_type === INBOX_TYPES.VOICE)
);
const hasVoiceInbox = computed(() => voiceInboxes.value.length > 0);

const positionStyle = computed(() => ({
  left: `${position.value.x}px`,
  top: `${position.value.y}px`,
}));

const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

const clampPosition = () => {
  const rect = fabRef.value?.getBoundingClientRect();
  if (!rect) return;
  const padding = 8;
  const maxX = window.innerWidth - rect.width - padding;
  const maxY = window.innerHeight - rect.height - padding;
  position.value = {
    x: clamp(position.value.x, padding, Math.max(padding, maxX)),
    y: clamp(position.value.y, padding, Math.max(padding, maxY)),
  };
  storePosition(position.value);
};

const setDefaultPosition = () => {
  const rect = fabRef.value?.getBoundingClientRect();
  const padding = 24;
  const width = rect?.width || 56;
  const height = rect?.height || 56;
  position.value = {
    x: Math.max(padding, window.innerWidth - width - padding),
    y: Math.max(padding, window.innerHeight - height - padding),
  };
  storePosition(position.value);
};

const openDialer = () => {
  if (!hasVoiceInbox.value) return;
  if (hasDragged.value) {
    hasDragged.value = false;
    return;
  }
  showMenu.value = false;
  if (voiceInboxes.value.length === 1) {
    selectedInboxId.value = voiceInboxes.value[0].id;
  }
  showDialer.value = true;
};

const closeDialer = () => {
  showDialer.value = false;
};

const hideFab = () => {
  showMenu.value = false;
  isHidden.value = true;
};

const showFab = () => {
  isHidden.value = false;
};

const resetPosition = () => {
  showMenu.value = false;
  setDefaultPosition();
};

const handlePointerDown = event => {
  if (event.button !== 0) return;
  const rect = fabRef.value?.getBoundingClientRect();
  if (!rect) return;

  isDragging.value = true;
  hasDragged.value = false;
  dragStart.value = { x: event.clientX, y: event.clientY };
  dragOffset.value = { x: event.clientX - rect.left, y: event.clientY - rect.top };
  window.addEventListener('pointermove', handlePointerMove);
  window.addEventListener('pointerup', handlePointerUp, { once: true });
};

const handlePointerMove = event => {
  if (!isDragging.value) return;
  const rect = fabRef.value?.getBoundingClientRect();
  if (!rect) return;
  const padding = 8;
  const maxX = window.innerWidth - rect.width - padding;
  const maxY = window.innerHeight - rect.height - padding;
  const nextX = event.clientX - dragOffset.value.x;
  const nextY = event.clientY - dragOffset.value.y;
  position.value = {
    x: clamp(nextX, padding, Math.max(padding, maxX)),
    y: clamp(nextY, padding, Math.max(padding, maxY)),
  };
  const movedX = Math.abs(event.clientX - dragStart.value.x);
  const movedY = Math.abs(event.clientY - dragStart.value.y);
  if (movedX > 4 || movedY > 4) {
    hasDragged.value = true;
  }
};

const handlePointerUp = () => {
  isDragging.value = false;
  window.removeEventListener('pointermove', handlePointerMove);
  storePosition(position.value);
};

const handleResize = () => clampPosition();

const keypadButtons = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['*', '0', '#'],
];
const keypadDigits = computed(() => keypadButtons.flat());

const appendDigit = digit => {
  dialNumber.value += digit;
};

const backspaceDigit = () => {
  dialNumber.value = dialNumber.value.slice(0, -1);
};

const clearDigits = () => {
  dialNumber.value = '';
};

const startCall = async () => {
  if (isCalling.value) return;
  if (!dialNumber.value.trim()) {
    useAlert(t('CONVERSATION.VOICE_WIDGET.DIALER_EMPTY_NUMBER'));
    return;
  }
  if (!selectedInboxId.value) {
    useAlert(t('CONVERSATION.VOICE_WIDGET.DIALER_PICK_INBOX'));
    return;
  }

  isCalling.value = true;
  try {
    const { number: normalizedNumber, isValid } = normalizeDialNumber(
      dialNumber.value
    );
    if (!normalizedNumber) {
      useAlert(t('CONVERSATION.VOICE_WIDGET.DIALER_EMPTY_NUMBER'));
      return;
    }
    if (!isValid) {
      useAlert(t('CONVERSATION.VOICE_WIDGET.DIALER_INVALID_NUMBER'));
      return;
    }
    dialNumber.value = normalizedNumber;
    const response = await VoiceAPI.initiateCallByPhone(
      normalizedNumber,
      selectedInboxId.value
    );
    const {
      call_sid: callSid,
      conversation_id: conversationId,
      inbox_id: inboxId,
    } = response || {};

    if (callSid && conversationId) {
      callsStore.addCall({
        callSid,
        conversationId,
        inboxId,
        callDirection: 'outbound',
      });
    }

    showDialer.value = false;
    dialNumber.value = '';
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[VoiceDialerFab] startCall error', { error });
    useAlert(t('CONVERSATION.VOICE_WIDGET.DIALER_FAILED'));
  } finally {
    isCalling.value = false;
  }
};

watch(
  () => callsStore.hasIncomingCall,
  hasIncoming => {
    if (hasIncoming) showFab();
  },
  { immediate: true }
);

watch(
  hasVoiceInbox,
  hasVoice => {
    if (!hasVoice) return;
    if (!getStoredPosition()) {
      setTimeout(() => setDefaultPosition(), 0);
    } else {
      setTimeout(() => clampPosition(), 0);
    }
  },
  { immediate: true }
);

onMounted(() => {
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  window.removeEventListener('resize', handleResize);
});
</script>

<template>
  <div
    v-if="hasVoiceInbox && !isHidden"
    ref="fabRef"
    class="fixed z-50"
    :style="positionStyle"
  >
    <div class="relative flex flex-col items-end gap-2">
      <div
        v-if="showMenu"
        class="flex flex-col gap-2 bg-n-solid-2 border border-n-strong rounded-xl p-2 shadow-xl"
      >
        <button
          class="px-3 py-2 text-sm text-n-slate-12 hover:bg-n-slate-3 rounded-lg"
          @click="resetPosition"
        >
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_MOVE') }}
        </button>
        <button
          class="px-3 py-2 text-sm text-n-slate-12 hover:bg-n-slate-3 rounded-lg"
          @click="hideFab"
        >
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_HIDE') }}
        </button>
      </div>

      <div class="flex items-center gap-2">
        <button
          class="w-12 h-12 rounded-full bg-n-slate-3 hover:bg-n-slate-4 border border-n-strong flex items-center justify-center"
          @click="showMenu = !showMenu"
        >
          <i class="text-lg text-n-slate-12 i-ph-dots-three-outline-vertical-bold" />
        </button>
        <button
          class="w-14 h-14 rounded-full bg-n-teal-9 hover:bg-n-teal-10 shadow-xl border border-n-strong flex items-center justify-center"
          :title="t('CONVERSATION.VOICE_WIDGET.DIALER_TITLE')"
          @click="openDialer"
          @pointerdown="handlePointerDown"
        >
          <i class="text-xl text-white i-ph-phone-bold" />
        </button>
      </div>
    </div>
  </div>

    <woot-modal
      v-model:show="showDialer"
      :on-close="closeDialer"
      size="modal-voice-dialer"
    >
      <div class="flex flex-col gap-4 p-6 w-[22rem] max-w-[22rem]">
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t('CONVERSATION.VOICE_WIDGET.DIALER_TITLE') }}
      </h3>

      <label class="flex flex-col gap-2">
        <span class="text-sm text-n-slate-11">
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_NUMBER_LABEL') }}
        </span>
        <input
          v-model="dialNumber"
          type="text"
          class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm text-n-slate-12"
          :placeholder="t('CONVERSATION.VOICE_WIDGET.DIALER_NUMBER_PLACEHOLDER')"
        />
      </label>

      <label v-if="voiceInboxes.length > 1" class="flex flex-col gap-2">
        <span class="text-sm text-n-slate-11">
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_PICK_INBOX') }}
        </span>
        <select
          v-model="selectedInboxId"
          class="rounded-md border border-n-strong bg-transparent px-3 py-2 text-sm"
        >
          <option disabled value="">--</option>
          <option v-for="inbox in voiceInboxes" :key="inbox.id" :value="inbox.id">
            {{ inbox.name }}
          </option>
        </select>
      </label>

      <div class="grid grid-cols-3 gap-3">
        <button
          v-for="digit in keypadDigits"
          :key="digit"
          class="h-12 rounded-lg bg-n-slate-3 text-n-slate-12 text-lg font-semibold hover:bg-n-slate-4 transition-colors"
          @click="appendDigit(digit)"
        >
          {{ digit }}
        </button>
      </div>
      <div class="flex justify-between">
        <button
          class="text-sm text-n-slate-11 hover:text-n-slate-12"
          @click="backspaceDigit"
        >
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_BACKSPACE') }}
        </button>
        <button
          class="text-sm text-n-slate-11 hover:text-n-slate-12"
          @click="clearDigits"
        >
          {{ t('CONVERSATION.VOICE_WIDGET.DIALER_CLEAR') }}
        </button>
      </div>

      <div class="flex justify-end gap-2">
        <NextButton
          faded
          slate
          :label="t('CONVERSATION.VOICE_WIDGET.DIALER_CANCEL')"
          @click="closeDialer"
        />
        <NextButton
          :label="t('CONVERSATION.VOICE_WIDGET.DIALER_CALL')"
          :is-loading="isCalling"
          @click="startCall"
        />
      </div>
    </div>
  </woot-modal>
</template>
