<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ViariReservaCard from './ViariReservaCard.vue';
import ViariOrcamentoCard from './ViariOrcamentoCard.vue';
import ViariPagamentoCard from './ViariPagamentoCard.vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  viariClienteId: { type: String, default: null },
});

const { t } = useI18n();

const activeTab = ref('reservas');
const tabs = ['reservas', 'orcamentos', 'pagamentos'];

const data = ref({ reservas: [], orcamentos: [], pagamentos: [] });
const loading = ref({ reservas: false, orcamentos: false, pagamentos: false });
const loaded = ref({ reservas: false, orcamentos: false, pagamentos: false });

const tabLabel = tab =>
  t(`CONVERSATION_SIDEBAR.VIARI.TABS.${tab.toUpperCase()}`);

const fetchTab = async tab => {
  if (loaded.value[tab] || !props.viariClienteId) return;
  loading.value[tab] = true;
  try {
    const apiMap = {
      reservas: () => ViariAPI.getReservas(props.contactId),
      orcamentos: () => ViariAPI.getOrcamentos(props.contactId),
      pagamentos: () => ViariAPI.getPagamentos(props.contactId),
    };
    const response = await apiMap[tab]();
    data.value[tab] = response.data[tab] ?? [];
    loaded.value[tab] = true;
  } catch {
    data.value[tab] = [];
  } finally {
    loading.value[tab] = false;
  }
};

watch(activeTab, tab => fetchTab(tab), { immediate: true });
watch(
  () => props.viariClienteId,
  () => {
    loaded.value = { reservas: false, orcamentos: false, pagamentos: false };
    fetchTab(activeTab.value);
  }
);
</script>

<template>
  <div class="bg-white">
    <!-- Tab bar -->
    <div class="flex border-b border-[#b2dfd0]">
      <button
        v-for="tab in tabs"
        :key="tab"
        class="px-3 py-2 text-[11px] font-semibold capitalize"
        :class="[
          activeTab === tab
            ? 'text-[#1D9E75] border-b-2 border-[#1D9E75]'
            : 'text-[#0F6E56] opacity-60 border-b-2 border-transparent',
        ]"
        @click="activeTab = tab"
      >
        {{ tabLabel(tab) }}
      </button>
    </div>

    <!-- Tab content -->
    <div class="px-3 py-2 space-y-2">
      <div v-if="loading[activeTab]" class="flex justify-center py-3">
        <span
          class="w-4 h-4 border-2 rounded-full animate-spin border-[#1D9E75] border-t-transparent"
        />
      </div>
      <template v-else-if="data[activeTab].length > 0">
        <template v-if="activeTab === 'reservas'">
          <ViariReservaCard
            v-for="item in data.reservas"
            :key="item.id"
            :reserva="item"
          />
        </template>
        <template v-else-if="activeTab === 'orcamentos'">
          <ViariOrcamentoCard
            v-for="item in data.orcamentos"
            :key="item.id"
            :orcamento="item"
          />
        </template>
        <template v-else-if="activeTab === 'pagamentos'">
          <ViariPagamentoCard
            v-for="item in data.pagamentos"
            :key="item.id"
            :pagamento="item"
          />
        </template>
      </template>
      <p v-else class="text-center text-[11px] py-3 text-[#0F6E56] opacity-60">
        {{ $t(`CONVERSATION_SIDEBAR.VIARI.EMPTY.${activeTab.toUpperCase()}`) }}
      </p>
    </div>
  </div>
</template>
