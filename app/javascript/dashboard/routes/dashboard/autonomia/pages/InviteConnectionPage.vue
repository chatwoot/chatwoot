<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import QRCode from 'qrcode';
import NextButton from 'dashboard/components-next/button/Button.vue';
import InviteConnectionAPI from 'dashboard/api/autonomia/inviteConnection';

const { t } = useI18n();

const inbox = ref(null);
const status = ref('unknown');
const phone = ref('');
const qrDataUrl = ref('');
const isLoading = ref(true);
const isReconnecting = ref(false);
let timer = null;

const connected = computed(() => status.value === 'connected');

const STATUS_META = {
  connected: { key: 'CONNECTED', tone: 'text-n-teal-11 bg-n-teal-3' },
  awaiting_scan: { key: 'AWAITING', tone: 'text-n-amber-11 bg-n-amber-3' },
  connecting: { key: 'CONNECTING', tone: 'text-n-amber-11 bg-n-amber-3' },
  failed: { key: 'FAILED', tone: 'text-n-ruby-11 bg-n-ruby-3' },
  disconnected: { key: 'DISCONNECTED', tone: 'text-n-slate-11 bg-n-alpha-2' },
  unknown: { key: 'CHECKING', tone: 'text-n-slate-11 bg-n-alpha-2' },
};

const statusMeta = computed(
  () => STATUS_META[status.value] || STATUS_META.unknown
);

const tk = key => t(`INBOX_MGMT.WAHA_CONNECTION.${key}`);

const renderQr = async value => {
  if (!value) {
    qrDataUrl.value = '';
    return;
  }

  try {
    qrDataUrl.value = await QRCode.toDataURL(value, { width: 240, margin: 1 });
  } catch {
    qrDataUrl.value = '';
  }
};

const load = async () => {
  const { data } = await InviteConnectionAPI.show();
  inbox.value = data.inbox;
  status.value = data.connected ? 'connected' : 'unknown';
};

const poll = async () => {
  if (!inbox.value?.id) return;

  try {
    const { data } = await InviteConnectionAPI.connection(inbox.value.id);
    status.value = data.status;
    phone.value = data.phone;
    if (data.connected) {
      qrDataUrl.value = '';
    } else {
      await renderQr(data.qr);
    }
  } catch {
    status.value = 'unknown';
  }
};

const reconnect = async () => {
  if (!inbox.value?.id) return;

  isReconnecting.value = true;
  try {
    await InviteConnectionAPI.reconnect(inbox.value.id);
    status.value = 'connecting';
    qrDataUrl.value = '';
    await poll();
  } finally {
    isReconnecting.value = false;
  }
};

onMounted(async () => {
  try {
    await load();
    await poll();
    timer = setInterval(poll, 3000);
  } finally {
    isLoading.value = false;
  }
});

onBeforeUnmount(() => {
  if (timer) clearInterval(timer);
});
</script>

<template>
  <main class="w-full max-w-4xl mx-auto py-6 px-6">
    <div class="mb-6">
      <h1 class="mb-2 text-2xl font-semibold text-n-slate-12">
        {{ $t('AUTONOMIA.INVITE_CONNECTION.TITLE') }}
      </h1>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ $t('AUTONOMIA.INVITE_CONNECTION.DESCRIPTION') }}
      </p>
    </div>

    <div
      v-if="isLoading"
      class="flex items-center justify-center h-48 border rounded-xl border-n-weak bg-n-solid-1"
    >
      <span
        class="i-lucide-loader-circle animate-spin size-6 text-n-slate-10"
      />
    </div>

    <div
      v-else-if="!inbox"
      class="p-5 text-sm border rounded-xl border-n-weak bg-n-solid-1 text-n-slate-11"
    >
      {{ $t('AUTONOMIA.INVITE_CONNECTION.EMPTY') }}
    </div>

    <div
      v-else
      class="flex flex-col gap-4 p-5 border rounded-xl border-n-weak bg-n-solid-1"
    >
      <div class="flex items-center justify-between gap-3">
        <div class="flex items-center gap-3 min-w-0">
          <span
            class="flex items-center justify-center rounded-full size-10 bg-n-alpha-2"
          >
            <span class="i-lucide-message-circle size-5 text-n-slate-11" />
          </span>
          <div class="min-w-0">
            <p class="mb-1 text-sm font-medium text-n-slate-12 truncate">
              {{ phone || inbox.name }}
              <span
                class="inline-flex items-center gap-1 px-2 py-0.5 ml-1 text-xs font-medium rounded-md"
                :class="statusMeta.tone"
              >
                <span class="rounded-full size-1.5 bg-current" />
                {{ tk(`STATUS.${statusMeta.key}`) }}
              </span>
            </p>
            <p class="mb-0 text-xs text-n-slate-11">{{ tk('SUBTITLE') }}</p>
          </div>
        </div>
        <NextButton
          v-if="!connected"
          :is-loading="isReconnecting"
          icon="i-lucide-refresh-cw"
          color="slate"
          variant="outline"
          size="sm"
          :label="tk('RECONNECT')"
          @click="reconnect"
        />
      </div>

      <div
        v-if="connected"
        class="flex items-center gap-2 px-4 py-3 text-sm rounded-lg text-n-teal-11 bg-n-teal-3"
      >
        <span class="i-lucide-circle-check size-4" />
        {{ tk('CONNECTED_HELP') }}
      </div>

      <div
        v-else
        class="flex flex-col items-center gap-3 px-4 py-6 text-center border rounded-lg border-n-weak"
      >
        <p class="mb-0 text-sm font-medium text-n-slate-12">
          {{ tk('SCAN_TITLE') }}
        </p>
        <div
          class="flex items-center justify-center bg-white rounded-lg size-[240px] p-2"
        >
          <img
            v-if="qrDataUrl"
            :src="qrDataUrl"
            alt="QR Code"
            class="size-full"
          />
          <span
            v-else
            class="i-lucide-loader-circle animate-spin size-6 text-n-slate-10"
          />
        </div>
        <ol
          class="mb-0 text-xs leading-5 text-left text-n-slate-11 list-decimal list-inside"
        >
          <li>{{ tk('STEP_1') }}</li>
          <li>{{ tk('STEP_2') }}</li>
          <li>{{ tk('STEP_3') }}</li>
        </ol>
      </div>
    </div>
  </main>
</template>
