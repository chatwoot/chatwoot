<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';
import ViariModalStep1 from './ViariModalStep1.vue';
import ViariModalStep2 from './ViariModalStep2.vue';
import ViariModalStep3 from './ViariModalStep3.vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  contactId: { type: [Number, String], required: true },
  viariClienteId: { type: [Number, String], default: null },
  conversationId: { type: [Number, String], required: true },
});

const emit = defineEmits(['close', 'created']);

const { t } = useI18n();
const store = useStore();
const contact = useFunctionGetter('contacts/getContact', props.contactId);

const currentStep = ref(1);
const isCreating = ref(false);
const createError = ref('');

const formData = ref({
  canalVendaId: '',
  grupoTarifaId: null,
  periodoInicio: '',
  periodoFim: '',
  dataValidade: '',
  percentualSinal: 35,
  descontoManual: 0,
  obsInternas: '',
  msgCliente: '',
  itens: [],
});

const displayTotals = ref({
  totalCartao: 0,
  totalPix: 0,
  sinalCartao: 0,
  sinalPix: 0,
  acertoCartao: 0,
  acertoPix: 0,
});

const fmt = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});

const buildWhatsAppText = (contactObj, itens, totals) => {
  let ordinal = 1;
  const linhas = [];
  itens.forEach(item => {
    [
      { tipo: 'ADT', qtd: item.qtdAdt ?? 0, preco: item.precoAdt },
      { tipo: 'CHD', qtd: item.qtdChd ?? 0, preco: item.precoChd },
      { tipo: 'INF', qtd: item.qtdInf ?? 0, preco: item.precoInf },
      { tipo: 'SEN', qtd: item.qtdSen ?? 0, preco: item.precoSen },
    ].forEach(({ tipo, qtd, preco }) => {
      if (qtd > 0 && preco != null) {
        linhas.push(
          `${ordinal}° - ${item.produtoNome ?? ''} ${tipo} | ${fmt.format(preco)} | Pax: ${qtd}`
        );
        ordinal += 1;
      }
    });
  });
  return [
    '🏠 Orçamento dos passeios:',
    `Nome: ${contactObj?.name ?? ''}`,
    `📞 Telefone: ${contactObj?.phone_number ?? ''}`,
    '',
    ...linhas,
    '',
    '💳 Cartão em até 6x s/ juros',
    `Preço Total no Cartão: ${fmt.format(totals.totalCartao)}`,
    `Sinal para reserva de vagas (PIX): ${fmt.format(totals.sinalCartao)}`,
    `Valor a acertar no dia do 1° passeio: ${fmt.format(totals.acertoCartao)}`,
    'ㅤ',
    '✅ PIX',
    `Preço Total no Pix: ${fmt.format(totals.totalPix)}`,
    `Sinal para reserva de vagas (PIX): ${fmt.format(totals.sinalPix)}`,
    `Valor a acertar no dia do 1° passeio: ${fmt.format(totals.acertoPix)}`,
  ].join('\n');
};

const previewText = computed(() =>
  buildWhatsAppText(
    contact.value,
    formData.value.itens ?? [],
    displayTotals.value
  )
);

const stepTitles = computed(() => [
  t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP1_TITLE'),
  t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP2_TITLE'),
  t('CONVERSATION_SIDEBAR.VIARI.MODAL.STEP3_TITLE'),
]);

const handleStep1Next = data => {
  Object.assign(formData.value, data);
  currentStep.value = 2;
};

const handleStep2Next = data => {
  const {
    totalCartao,
    totalPix,
    sinalCartao,
    sinalPix,
    acertoCartao,
    acertoPix,
    ...rest
  } = data;
  Object.assign(formData.value, rest);
  displayTotals.value = {
    totalCartao,
    totalPix,
    sinalCartao,
    sinalPix,
    acertoCartao,
    acertoPix,
  };
  currentStep.value = 3;
};

const handleBack = () => {
  if (currentStep.value > 1) currentStep.value -= 1;
};

const handleConfirm = async () => {
  isCreating.value = true;
  createError.value = '';
  try {
    const apiItens = formData.value.itens.map(
      // eslint-disable-next-line no-unused-vars
      ({ produtoNome, precoAdt, precoChd, precoInf, precoSen, ...apiFields }) =>
        apiFields
    );
    const response = await ViariAPI.criarOrcamento({
      clienteId: props.viariClienteId,
      ...formData.value,
      itens: apiItens,
    });

    let textoWhatsapp = response.data?.textoWhatsapp ?? '';

    if (!textoWhatsapp) {
      const orcamentoId = response.data?.orcamento?.id ?? response.data?.id;
      if (orcamentoId) {
        try {
          const r = await ViariAPI.getTextoWhatsapp(orcamentoId);
          textoWhatsapp = r.data?.texto ?? r.data?.textoWhatsapp ?? '';
        } catch {
          // fallback to locally generated text
        }
      }
    }

    if (!textoWhatsapp) {
      textoWhatsapp = previewText.value;
    }

    if (textoWhatsapp) {
      navigator.clipboard.writeText(textoWhatsapp).catch(() => {});
    }
    store.dispatch('draftMessages/set', {
      key: `draft-${props.conversationId}-REPLY`,
      message: textoWhatsapp,
    });
    emit('created');
    emit('close');
  } catch {
    createError.value = t('CONVERSATION_SIDEBAR.VIARI.MODAL.ERROR');
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
    <div
      class="rounded-xl overflow-hidden shadow-2xl w-[680px] max-h-[90vh] bg-white flex flex-col"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between px-4 py-3 bg-[#0D2B2A] shrink-0"
      >
        <div class="flex items-center gap-2">
          <span class="text-base">{{
            $t('CONVERSATION_SIDEBAR.VIARI.ICON')
          }}</span>
          <span class="text-sm font-bold text-[#5DCAA5]">{{
            $t('CONVERSATION_SIDEBAR.VIARI.MODAL.TITLE')
          }}</span>
          <span
            v-if="contact && contact.name"
            class="text-xs text-[#5DCAA5] opacity-70"
          >
            {{ contact.name }}
            <template v-if="contact.phone_number">
              {{ contact.phone_number }}
            </template>
          </span>
        </div>
        <button
          class="text-[#5DCAA5] text-lg leading-none hover:text-white"
          @click="emit('close')"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="w-4 h-4"
            viewBox="0 0 20 20"
            fill="currentColor"
          >
            <path
              fill-rule="evenodd"
              d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
              clip-rule="evenodd"
            />
          </svg>
        </button>
      </div>

      <!-- Step nav bar -->
      <div class="flex items-center px-6 py-3 bg-[#E1F5EE] shrink-0">
        <template v-for="(title, i) in stepTitles" :key="i">
          <div class="flex flex-col items-center">
            <div
              class="w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-extrabold text-white"
              :class="
                currentStep > i + 1
                  ? 'bg-[#0F6E56]'
                  : currentStep === i + 1
                    ? 'bg-[#1D9E75]'
                    : 'bg-[#5DCAA5]'
              "
            >
              <template v-if="currentStep > i + 1">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="w-3 h-3"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              </template>
              <template v-else>{{ i + 1 }}</template>
            </div>
            <span
              class="text-[11px] font-semibold mt-0.5"
              :class="
                currentStep >= i + 1
                  ? 'text-[#1D9E75]'
                  : 'text-[#0F6E56] opacity-40'
              "
            >
              {{ title }}
            </span>
          </div>
          <div v-if="i < 2" class="flex-1 h-px mx-2 bg-[#5DCAA5] opacity-40" />
        </template>
      </div>

      <!-- Step content -->
      <div class="flex-1 overflow-y-auto">
        <ViariModalStep1
          v-if="currentStep === 1"
          :initial-data="formData"
          @next="handleStep1Next"
        />
        <ViariModalStep2
          v-else-if="currentStep === 2"
          :initial-data="formData"
          @next="handleStep2Next"
          @back="handleBack"
        />
        <ViariModalStep3
          v-else-if="currentStep === 3"
          :form-data="formData"
          :preview-text="previewText"
          :is-creating="isCreating"
          :create-error="createError"
          @confirm="handleConfirm"
          @back="handleBack"
        />
      </div>
    </div>
  </div>
</template>
