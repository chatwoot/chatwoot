<script setup>
import { ref, watch, computed } from 'vue';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';
import ViariJourneyBar from './ViariJourneyBar.vue';
import ViariTabs from './ViariTabs.vue';
import ViariOrcamentoModal from './ViariOrcamentoModal.vue';
import ViariReservaModal from './ViariReservaModal.vue';
import ViariPagamentoModal from './ViariPagamentoModal.vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  conversationId: { type: [Number, String], required: true },
});

const store = useStore();
const contact = useFunctionGetter('contacts/getContact', props.contactId);

const loading = ref(true);
const error = ref('');
const clienteData = ref(null);
const showModal = ref(false);
const showReservaModal = ref(false);
const showPagamentoModal = ref(false);
const activeOrcamento = ref(null);
const activeReserva = ref(null);
const tabsRefreshKey = ref(0);

const statusJornada = computed(
  () => clienteData.value?.cliente?.statusJornada ?? 'contato'
);
// Support both { cliente: { id } } (new) and { clienteId } (legacy) response formats
const viariClienteId = computed(
  () => clienteData.value?.cliente?.id ?? clienteData.value?.clienteId ?? null
);

const VIARI_LABELS = [
  'viari-vinculado',
  'orcamento-enviado',
  'orcamento-aprovado',
  'aguardando-sinal',
  'reserva-confirmada',
  'pago-completo',
  'orcamento-perdido',
  'concluido',
];

const JORNADA_LABEL_MAP = {
  contato: 'viari-vinculado',
  orcamento: 'orcamento-enviado',
  sinal: 'aguardando-sinal',
  reserva: 'reserva-confirmada',
  pago: 'pago-completo',
  embarque: 'concluido',
};

const applyLabels = async status => {
  const label = JORNADA_LABEL_MAP[status];
  if (!label) return;
  try {
    const conversationId = Number(props.conversationId);
    const currentLabels =
      store.getters['conversationLabels/getConversationLabels'](conversationId);
    const labelsWithoutViari = currentLabels.filter(
      l => !VIARI_LABELS.includes(l)
    );
    const newLabels = [...labelsWithoutViari, label];
    await store.dispatch('conversationLabels/update', {
      conversationId,
      labels: newLabels,
    });
  } catch {
    // labels are best-effort
  }
};

const loadCustomer = async () => {
  loading.value = true;
  error.value = '';
  try {
    const response = await ViariAPI.getCustomer(props.contactId);
    clienteData.value = response.data;
  } catch (e) {
    error.value = e.response?.data?.error || 'error';
  } finally {
    loading.value = false;
  }
};

const onOrcamentoCriado = async () => {
  await loadCustomer();
  await applyLabels('orcamento');
  tabsRefreshKey.value += 1;
};

const onCreateReserva = orcamento => {
  activeOrcamento.value = orcamento;
  showReservaModal.value = true;
};

const onReservaCriada = async () => {
  await loadCustomer();
  await applyLabels('sinal');
  tabsRefreshKey.value += 1;
};

const onCreatePagamento = reserva => {
  activeReserva.value = reserva;
  showPagamentoModal.value = true;
};

const onPagamentoCriado = async ({ tipo }) => {
  await loadCustomer();
  await applyLabels(tipo === 'sinal' ? 'reserva' : 'pago');
  tabsRefreshKey.value += 1;
};

watch(
  () => props.contactId,
  async () => {
    await loadCustomer();
    await applyLabels(statusJornada.value);
  },
  { immediate: true }
);
</script>

<template>
  <div class="viari-panel">
    <!-- Header with Viari branding -->
    <div class="flex items-center justify-between px-3 py-2 bg-[#0D2B2A]">
      <div class="flex items-center gap-2">
        <span class="text-base">{{
          $t('CONVERSATION_SIDEBAR.VIARI.ICON')
        }}</span>
        <span class="text-sm font-bold text-[#5DCAA5]">{{
          $t('CONVERSATION_SIDEBAR.VIARI.BRAND_NAME')
        }}</span>
        <span
          v-if="!loading && !error"
          class="text-[9px] px-1.5 py-0.5 rounded-full font-semibold bg-[#1D9E75] text-[#E1F5EE]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.LINKED') }}
        </span>
      </div>
      <button
        v-if="!loading && !error"
        class="text-[10px] font-bold px-2 py-1 rounded bg-[#1D9E75] text-white"
        @click="showModal = true"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.NEW_QUOTE_BTN') }}
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center items-center py-4 bg-white">
      <span
        class="w-5 h-5 border-2 rounded-full animate-spin border-[#1D9E75] border-t-transparent"
      />
    </div>

    <!-- Error -->
    <div
      v-else-if="error"
      class="text-center py-3 text-xs bg-white text-red-500"
    >
      {{ $t('CONVERSATION_SIDEBAR.VIARI.ERROR') }}
    </div>

    <!-- Content -->
    <template v-else>
      <ViariJourneyBar :status="statusJornada" />
      <ViariTabs
        :key="tabsRefreshKey"
        :contact-id="contactId"
        :viari-cliente-id="viariClienteId"
        @create-reserva="onCreateReserva"
        @create-pagamento="onCreatePagamento"
      />
    </template>

    <!-- Orcamento modal -->
    <ViariOrcamentoModal
      v-if="showModal"
      :contact-id="contactId"
      :viari-cliente-id="viariClienteId"
      :conversation-id="conversationId"
      @close="showModal = false"
      @created="onOrcamentoCriado"
    />

    <!-- Reserva modal -->
    <ViariReservaModal
      v-if="showReservaModal && activeOrcamento"
      :orcamento="activeOrcamento"
      :viari-cliente-id="viariClienteId"
      :contact="contact"
      @close="showReservaModal = false"
      @created="onReservaCriada"
    />

    <!-- Pagamento modal -->
    <ViariPagamentoModal
      v-if="showPagamentoModal && activeReserva"
      :reserva="activeReserva"
      :viari-cliente-id="viariClienteId"
      :contact="contact"
      @close="showPagamentoModal = false"
      @created="onPagamentoCriado"
    />
  </div>
</template>
