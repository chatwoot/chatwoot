<script setup>
/**
 * Shows a countdown timer for the WhatsApp 24-hour messaging session window.
 * When expired, the text changes to "Expirada" and the agent knows
 * they can only send template messages.
 */
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  /** Unix timestamp (seconds) of the last incoming message */
  lastIncomingMessageAt: { type: Number, default: 0 },
  /** Whether the channel type is WhatsApp */
  isWhatsApp: { type: Boolean, default: false },
});

const { t } = useI18n();

const SESSION_WINDOW = 24 * 60 * 60; // 24 hours in seconds
const now = ref(Math.floor(Date.now() / 1000));
let timer = null;

const expiresAt = computed(() =>
  props.lastIncomingMessageAt ? props.lastIncomingMessageAt + SESSION_WINDOW : 0
);

const remaining = computed(() => {
  if (!expiresAt.value) return 0;
  return Math.max(0, expiresAt.value - now.value);
});

const isExpired = computed(() => remaining.value <= 0);
const isUrgent = computed(() => remaining.value > 0 && remaining.value < 3600);

const displayText = computed(() => {
  if (!props.lastIncomingMessageAt) return '';
  if (isExpired.value) return t('CONVERSATION.WHATSAPP_SESSION.EXPIRED');

  const h = Math.floor(remaining.value / 3600);
  const m = Math.floor((remaining.value % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
});

const colorClass = computed(() => {
  if (isExpired.value) return 'text-n-ruby-11';
  if (isUrgent.value) return 'text-n-amber-11';
  return 'text-n-teal-11';
});

function stopTimer() {
  if (timer) {
    clearInterval(timer);
    timer = null;
  }
}

function startTimer() {
  stopTimer();
  timer = setInterval(() => {
    now.value = Math.floor(Date.now() / 1000);
  }, 30000); // update every 30 seconds
}

onMounted(startTimer);
onUnmounted(stopTimer);

watch(
  () => props.lastIncomingMessageAt,
  () => {
    now.value = Math.floor(Date.now() / 1000);
  }
);
</script>

<template>
  <div
    v-if="isWhatsApp && lastIncomingMessageAt"
    v-tooltip="
      isExpired
        ? t('CONVERSATION.WHATSAPP_SESSION.EXPIRED_TOOLTIP')
        : t('CONVERSATION.WHATSAPP_SESSION.ACTIVE_TOOLTIP', {
            time: displayText,
          })
    "
    class="flex items-center gap-1 text-xs font-medium shrink-0"
    :class="colorClass"
  >
    <Icon
      :icon="isExpired ? 'i-lucide-timer-off' : 'i-lucide-timer'"
      class="size-3.5"
    />
    <span>{{ displayText }}</span>
  </div>
</template>
