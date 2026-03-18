<script setup>
import { watch, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useWhatsappCallSession } from 'dashboard/composables/useWhatsappCallSession';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const router = useRouter();

const {
  activeCall,
  incomingCalls,
  hasActiveCall,
  hasIncomingCall,
  isAccepting,
  isMuted,
  isOutboundRinging,
  callError,
  formattedCallDuration,
  acceptCall,
  rejectCall,
  endActiveCall,
  toggleMute,
  dismissIncomingCall,
} = useWhatsappCallSession();

// Auto-dismiss ringing calls after 30 seconds
const autoRejectTimers = new Map();

const startAutoRejectTimer = call => {
  if (autoRejectTimers.has(call.callId)) return;
  const timer = setTimeout(() => {
    dismissIncomingCall(call);
    autoRejectTimers.delete(call.callId);
  }, 30000);
  autoRejectTimers.set(call.callId, timer);
};

const clearAutoRejectTimer = callId => {
  const timer = autoRejectTimers.get(callId);
  if (timer) {
    clearTimeout(timer);
    autoRejectTimers.delete(callId);
  }
};

const handleAccept = async call => {
  clearAutoRejectTimer(call.callId);
  await acceptCall(call);
  if (activeCall.value) {
    router.push({
      name: 'inbox_conversation',
      params: { conversation_id: call.conversationId },
    });
  }
};

const handleReject = async call => {
  clearAutoRejectTimer(call.callId);
  await rejectCall(call);
};

const handleEndCall = async () => {
  await endActiveCall();
};

// Start auto-reject timers for each newly added incoming call
watch(
  incomingCalls,
  calls => {
    calls.forEach(call => startAutoRejectTimer(call));
  },
  { immediate: true, deep: true }
);

onUnmounted(() => {
  autoRejectTimers.forEach(timer => clearTimeout(timer));
  autoRejectTimers.clear();
});
</script>

<template>
  <div
    v-if="hasIncomingCall || hasActiveCall"
    class="fixed ltr:right-4 rtl:left-4 bottom-20 z-50 flex flex-col gap-2 w-72"
  >
    <!-- Error banner -->
    <div
      v-if="callError"
      class="px-3 py-2 bg-n-ruby-3 border border-n-ruby-6 rounded-lg text-xs text-n-ruby-11"
    >
      {{ callError }}
    </div>

    <!-- Incoming calls (shown when there's no active call yet) -->
    <template v-if="!hasActiveCall">
      <div
        v-for="call in incomingCalls"
        :key="call.callId"
        class="flex items-center gap-3 p-4 bg-n-solid-2 rounded-xl shadow-xl outline outline-1 outline-n-strong"
      >
        <div
          class="animate-pulse ring-2 ring-n-teal-9 rounded-full inline-flex"
        >
          <Avatar
            :src="call.caller?.avatar"
            :name="call.caller?.name || call.caller?.phone"
            :size="40"
            rounded-full
          />
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-n-slate-12 truncate mb-0">
            {{
              call.caller?.name ||
              call.caller?.phone ||
              t('WHATSAPP_CALL.UNKNOWN_CALLER')
            }}
          </p>
          <p class="text-xs text-n-slate-11 truncate">
            {{ t('WHATSAPP_CALL.INCOMING_WHATSAPP_CALL') }}
          </p>
        </div>
        <div class="flex shrink-0 gap-2">
          <button
            class="flex justify-center items-center w-10 h-10 bg-n-ruby-9 hover:bg-n-ruby-10 rounded-full transition-colors"
            :title="t('WHATSAPP_CALL.REJECT')"
            @click="handleReject(call)"
          >
            <i class="text-lg text-white i-ph-phone-x-bold" />
          </button>
          <button
            class="flex justify-center items-center w-10 h-10 bg-n-teal-9 hover:bg-n-teal-10 rounded-full transition-colors"
            :disabled="isAccepting"
            :title="t('WHATSAPP_CALL.ACCEPT')"
            @click="handleAccept(call)"
          >
            <i
              v-if="isAccepting"
              class="text-lg text-white i-ph-circle-notch animate-spin"
            />
            <i v-else class="text-lg text-white i-ph-phone-bold" />
          </button>
        </div>
      </div>
    </template>

    <!-- Active call widget -->
    <div
      v-if="hasActiveCall"
      class="flex items-center gap-3 p-4 bg-n-solid-2 rounded-xl shadow-xl outline outline-1 outline-n-strong"
    >
      <div
        class="ring-2 ring-n-teal-9 rounded-full inline-flex"
        :class="{ 'animate-pulse': isOutboundRinging }"
      >
        <Avatar
          :src="activeCall.caller?.avatar"
          :name="activeCall.caller?.name || activeCall.caller?.phone"
          :size="40"
          rounded-full
        />
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-n-slate-12 truncate mb-0">
          {{
            activeCall.caller?.name ||
            activeCall.caller?.phone ||
            t('WHATSAPP_CALL.UNKNOWN_CALLER')
          }}
        </p>
        <p
          class="text-sm"
          :class="
            isOutboundRinging ? 'text-n-slate-11' : 'font-mono text-n-teal-9'
          "
        >
          {{
            isOutboundRinging
              ? t('WHATSAPP_CALL.RINGING')
              : formattedCallDuration
          }}
        </p>
      </div>
      <div class="flex shrink-0 gap-2">
        <!-- Mute toggle -->
        <button
          class="flex justify-center items-center w-9 h-9 rounded-full transition-colors"
          :class="
            isMuted
              ? 'bg-n-amber-9 hover:bg-n-amber-10'
              : 'bg-n-slate-4 hover:bg-n-slate-5'
          "
          :title="isMuted ? t('WHATSAPP_CALL.UNMUTE') : t('WHATSAPP_CALL.MUTE')"
          @click="toggleMute"
        >
          <i
            class="text-base text-white"
            :class="
              isMuted ? 'i-ph-microphone-slash-bold' : 'i-ph-microphone-bold'
            "
          />
        </button>
        <!-- Hang up -->
        <button
          class="flex justify-center items-center w-9 h-9 bg-n-ruby-9 hover:bg-n-ruby-10 rounded-full transition-colors"
          :title="t('WHATSAPP_CALL.HANG_UP')"
          @click="handleEndCall"
        >
          <i class="text-base text-white i-ph-phone-x-bold" />
        </button>
      </div>
    </div>
  </div>
</template>
