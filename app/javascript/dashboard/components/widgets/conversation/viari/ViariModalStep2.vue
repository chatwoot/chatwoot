<script setup>
import { ref, computed, onMounted } from 'vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  initialData: { type: Object, required: true },
});

const emit = defineEmits(['next', 'back']);

const PAX_TYPES = ['ADT', 'CHD', 'INF', 'SEN', 'FREE'];
const fmt = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const produtos = ref([]);

function newItem() {
  return {
    produtoId: '',
    agendaId: '',
    agendas: [],
    tarifas: [],
    qtdAdt: 0,
    qtdChd: 0,
    qtdInf: 0,
    qtdSen: 0,
    qtdFree: 0,
  };
}

const itens = ref(
  props.initialData.itens?.length ? props.initialData.itens : [newItem()]
);

const fmtDate = d =>
  d
    ? new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
      })
    : '';

const onProdutoChange = async item => {
  item.agendaId = '';
  item.agendas = [];
  item.tarifas = [];
  if (!item.produtoId) return;
  try {
    const r = await ViariAPI.getAgendas(
      item.produtoId,
      props.initialData.periodoInicio,
      props.initialData.periodoFim
    );
    item.agendas = r.data.agendas ?? [];
  } catch {
    item.agendas = [];
  }
};

const onAgendaChange = async item => {
  item.tarifas = [];
  if (!item.agendaId) return;
  const agenda = item.agendas.find(a => a.id === item.agendaId);
  if (!agenda) return;
  try {
    const r = await ViariAPI.getTarifas(
      item.produtoId,
      null,
      agenda.dataAgenda
    );
    item.tarifas = r.data.itens ?? [];
  } catch {
    item.tarifas = [];
  }
};

const getPreco = (item, tipoPax) => {
  const found = item.tarifas.find(
    itarifa => itarifa.precos[tipoPax] !== undefined
  );
  return found ? found.precos[tipoPax] : null;
};

const subtotalItem = item =>
  PAX_TYPES.reduce((s, pax) => {
    const qtd = item[`qtd${pax.charAt(0) + pax.slice(1).toLowerCase()}`];
    const preco = getPreco(item, pax) ?? 0;
    return s + qtd * preco;
  }, 0);

const totalCartao = computed(() =>
  itens.value.reduce((sum, item) => sum + subtotalItem(item), 0)
);
const totalPix = computed(
  () => totalCartao.value - (props.initialData.descontoManual ?? 0)
);
const valorSinal = computed(
  () =>
    Math.round(
      totalPix.value * ((props.initialData.percentualSinal ?? 35) / 100) * 100
    ) / 100
);
const acerto = computed(() => totalPix.value - valorSinal.value);
const sinalPctDisplay = computed(
  () => `(${props.initialData.percentualSinal ?? 35}%)`
);

const addItem = () => itens.value.push(newItem());
const removeItem = idx => {
  if (itens.value.length > 1) itens.value.splice(idx, 1);
};

const handleNext = () => {
  const valid = itens.value.every(item => item.produtoId && item.agendaId);
  if (!valid) return;
  const payload = itens.value.map(item => ({
    produtoId: item.produtoId,
    agendaId: item.agendaId,
    qtdAdt: item.qtdAdt,
    qtdChd: item.qtdChd,
    qtdInf: item.qtdInf,
    qtdSen: item.qtdSen,
    qtdFree: item.qtdFree,
  }));
  emit('next', payload);
};

onMounted(async () => {
  try {
    const r = await ViariAPI.getProdutos();
    produtos.value = r.data.produtos ?? [];
  } catch {
    // silent
  }
});
</script>

<template>
  <div class="p-5 flex flex-col gap-4">
    <!-- Period info bar -->
    <div
      class="flex items-center gap-2 px-3 py-2 rounded bg-[#E1F5EE] text-[#0F6E56] text-xs font-semibold"
    >
      <span>{{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_LABEL') }}</span>
      <span>{{ fmtDate(props.initialData.periodoInicio) }}</span>
      <span class="w-px h-3 bg-[#0F6E56] opacity-40 inline-block" />
      <span>{{ fmtDate(props.initialData.periodoFim) }}</span>
    </div>

    <!-- Items section -->
    <div class="flex flex-col gap-3">
      <!-- Section header -->
      <div class="flex items-center justify-between">
        <span class="text-xs font-bold uppercase tracking-wide text-[#0F6E56]">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.ITEMS_LABEL') }}
        </span>
        <button
          class="text-xs font-bold text-white bg-[#1D9E75] px-3 py-1 rounded hover:bg-[#0F6E56]"
          @click="addItem"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.ADD_ITEM') }}
        </button>
      </div>

      <!-- Each item -->
      <div
        v-for="(item, idx) in itens"
        :key="idx"
        class="rounded-lg border border-[#b2dfd0] bg-[#f8fffe] p-3 flex flex-col gap-3"
      >
        <!-- Item header -->
        <div class="flex items-center justify-between">
          <span
            class="text-[10px] font-bold uppercase tracking-wide text-[#1D9E75]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.ITEM_LABEL') }}
            {{ idx + 1 }}
          </span>
          <button
            v-if="itens.length > 1"
            class="text-[10px] font-bold text-red-400 hover:text-red-600"
            @click="removeItem(idx)"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.REMOVE') }}
          </button>
        </div>

        <!-- Product select -->
        <div>
          <label
            class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PRODUCT_LABEL') }}
          </label>
          <select
            v-model="item.produtoId"
            class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-white text-[#0D2B2A]"
            @change="onProdutoChange(item)"
          >
            <option value="">
              {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SELECT_PLACEHOLDER') }}
            </option>
            <option v-for="p in produtos" :key="p.id" :value="p.id">
              {{ p.nome }}
            </option>
          </select>
        </div>

        <!-- Agenda select -->
        <div>
          <label
            class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.AGENDA_LABEL') }}
          </label>
          <select
            v-model="item.agendaId"
            class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-white text-[#0D2B2A]"
            :disabled="!item.produtoId || item.agendas.length === 0"
            @change="onAgendaChange(item)"
          >
            <option value="">
              {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SELECT_PLACEHOLDER') }}
            </option>
            <option v-for="a in item.agendas" :key="a.id" :value="a.id">
              {{
                a.nome
                  ? `${fmtDate(a.dataAgenda)} - ${a.nome}`
                  : fmtDate(a.dataAgenda)
              }}
            </option>
          </select>
        </div>

        <!-- PAX inputs -->
        <div>
          <label
            class="block text-[10px] font-bold uppercase tracking-wide mb-2 text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PAX_LABEL') }}
          </label>
          <div class="grid grid-cols-5 gap-2">
            <div
              v-for="pax in PAX_TYPES"
              :key="pax"
              class="flex flex-col items-center gap-1"
            >
              <span class="text-[10px] font-bold text-[#0F6E56]">{{
                pax
              }}</span>
              <input
                v-model.number="
                  item[`qtd${pax.charAt(0) + pax.slice(1).toLowerCase()}`]
                "
                type="number"
                min="0"
                class="w-full px-2 py-1 text-sm text-center rounded border border-[#b2dfd0] bg-white text-[#0D2B2A]"
              />
              <span
                v-if="getPreco(item, pax) !== null"
                class="text-[9px] text-[#1D9E75] font-medium"
              >
                {{ fmt.format(getPreco(item, pax)) }}
              </span>
            </div>
          </div>
        </div>

        <!-- Item subtotal -->
        <div
          class="flex items-center justify-end gap-2 pt-1 border-t border-[#b2dfd0]"
        >
          <span
            class="text-[10px] font-bold uppercase tracking-wide text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SUBTOTAL') }}
          </span>
          <span class="text-sm font-bold text-[#0D2B2A]">
            {{ fmt.format(subtotalItem(item)) }}
          </span>
        </div>
      </div>
    </div>

    <!-- Totals summary -->
    <div
      class="rounded-lg border border-[#b2dfd0] bg-[#E1F5EE] px-4 py-3 flex flex-col gap-1.5"
    >
      <div class="flex items-center justify-between text-sm">
        <span class="text-[#0F6E56] font-semibold">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.TOTAL_CARTAO') }}
        </span>
        <span class="font-bold text-[#0D2B2A]">{{
          fmt.format(totalCartao)
        }}</span>
      </div>
      <div class="flex items-center justify-between text-sm">
        <span class="text-[#0F6E56] font-semibold">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.TOTAL_PIX') }}
        </span>
        <span class="font-bold text-[#0D2B2A]">{{ fmt.format(totalPix) }}</span>
      </div>
      <div class="flex items-center justify-between text-sm">
        <span class="text-[#0F6E56] font-semibold">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SINAL_VALUE') }}
          <span class="text-[10px] font-normal opacity-70">
            {{ sinalPctDisplay }}
          </span>
        </span>
        <span class="font-bold text-[#1D9E75]">{{
          fmt.format(valorSinal)
        }}</span>
      </div>
      <div
        class="flex items-center justify-between text-sm border-t border-[#b2dfd0] pt-1.5 mt-0.5"
      >
        <span class="text-[#0F6E56] font-semibold">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.ACERTO') }}
        </span>
        <span class="font-bold text-[#0D2B2A]">{{ fmt.format(acerto) }}</span>
      </div>
    </div>

    <!-- Footer: Back / Next -->
    <div class="flex justify-between mt-1">
      <button
        class="px-4 py-2 rounded text-sm font-bold text-[#0F6E56] border border-[#b2dfd0] bg-white hover:bg-[#E1F5EE]"
        @click="emit('back')"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.BACK') }}
      </button>
      <button
        class="px-4 py-2 rounded text-sm font-bold text-white bg-[#1D9E75] hover:bg-[#0F6E56]"
        @click="handleNext"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.NEXT') }}
      </button>
    </div>
  </div>
</template>
