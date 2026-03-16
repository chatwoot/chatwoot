<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import virtiAuth from 'dashboard/api/virtiAuth';
import { virtiGet } from 'dashboard/api/virtiBackend';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['close']);

const store = useStore();
const dialogRef = ref(null);
const isLoading = ref(true);
const errorMessage = ref('');
const tracking = ref(null);

const currentChat = computed(() => store.getters.getSelectedChat);

const phoneNumber = computed(() => {
  const senderId = currentChat.value?.meta?.sender?.id;
  if (!senderId) return null;
  const contact = store.getters['contacts/getContact'](senderId);
  return contact?.phone_number || null;
});

const idUsuario = computed(() => {
  if (!phoneNumber.value) return null;
  return `chatwoot_${phoneNumber.value.replace('+', '')}`;
});

const trackingFields = computed(() => {
  if (!tracking.value) return [];
  const t = tracking.value;
  const utm = t.utm || {};
  return [
    { label: 'Referer', value: t.referer },
    { label: 'URL Atual', value: t.url_atual },
    { label: 'UTM Source', value: utm.utm_source },
    { label: 'UTM Medium', value: utm.utm_medium },
    { label: 'UTM Campaign', value: utm.utm_campaign },
    { label: 'UTM Content', value: utm.utm_content },
    { label: 'UTM Term', value: utm.utm_term },
    { label: 'GCLID', value: t.gclid },
    { label: 'FBCLID', value: t.fbclid },
  ];
});

const hasTrackingData = computed(() =>
  trackingFields.value.some(f => f.value)
);

const fetchData = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  const idRobo = await virtiAuth.resolveRobo(currentChat.value?.inbox_id);
  if (!idRobo || !idUsuario.value) {
    errorMessage.value = 'Dados insuficientes para buscar rastreamento.';
    isLoading.value = false;
    return;
  }

  try {
    const res = await virtiGet(
      `/api/v1/conversas/${idRobo}/${idUsuario.value}/tracking`
    );
    const data = res?.data || {};
    tracking.value = Object.keys(data).length > 0 ? data : null;
  } catch (err) {
    errorMessage.value =
      err?.response?.data?.message || 'Erro ao buscar dados de rastreamento.';
  } finally {
    isLoading.value = false;
  }
};

const copyToClipboard = async text => {
  if (!text) return;
  try {
    await navigator.clipboard.writeText(text);
    useAlert('Copiado para a área de transferência.');
  } catch {
    useAlert('Erro ao copiar texto.');
  }
};

onMounted(() => {
  dialogRef.value?.open();
  fetchData();
});

const handleClose = () => {
  emit('close');
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    title="Rastreamento"
    :show-confirm-button="false"
    cancel-button-label="Fechar"
    width="xl"
    @close="handleClose"
  >
    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center py-8">
      <Spinner />
    </div>

    <!-- Error -->
    <div
      v-else-if="errorMessage"
      class="py-4 text-sm text-n-ruby-11"
    >
      {{ errorMessage }}
    </div>

    <!-- Data -->
    <div v-else-if="hasTrackingData" class="flex flex-col max-h-[60vh] overflow-y-auto">
      <table class="w-full text-sm">
        <tbody>
          <tr
            v-for="field in trackingFields"
            :key="field.label"
            class="border-b border-n-weak"
          >
            <td class="py-2 pr-3 font-medium text-n-slate-11 whitespace-nowrap align-top w-1/4">
              {{ field.label }}
            </td>
            <td class="py-2 text-n-slate-12 break-all">
              {{ field.value || 'N/A' }}
            </td>
            <td class="py-2 pl-2 w-8">
              <button
                v-if="field.value"
                type="button"
                class="inline-flex items-center justify-center w-6 h-6 rounded hover:bg-n-alpha-2 text-n-slate-11 hover:text-n-slate-12 transition-colors"
                @click="copyToClipboard(field.value)"
              >
                <Icon icon="i-lucide-copy" class="size-3.5" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Empty state -->
    <div
      v-else
      class="py-4 text-sm text-center text-n-slate-11"
    >
      Nenhuma informação de rastreamento disponível.
    </div>
  </Dialog>
</template>
