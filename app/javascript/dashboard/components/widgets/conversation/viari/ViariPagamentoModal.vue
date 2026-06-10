<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  reserva: { type: Object, required: true },
  viariClienteId: { type: [Number, String], required: true },
  contact: { type: Object, default: null },
});

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();

const fmt = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
});
const isCreating = ref(false);
const error = ref('');

const todayStr = () => new Date().toISOString().substring(0, 10);

const form = ref({
  tipo: 'sinal',
  formaPagamento: 'pix',
  valor: props.reserva.valorSinal ?? props.reserva.valorTotal ?? 0,
  data: todayStr(),
  obs: '',
});

const handleConfirm = async () => {
  isCreating.value = true;
  error.value = '';
  try {
    await ViariAPI.criarPagamento({
      clienteId: props.viariClienteId,
      reservaId: props.reserva.id,
      ...form.value,
    });
    emit('created', { tipo: form.value.tipo });
    emit('close');
  } catch {
    error.value = t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.ERROR');
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
    <div
      class="rounded-xl overflow-hidden shadow-2xl w-[480px] max-h-[90vh] bg-white flex flex-col"
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
            $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.TITLE')
          }}</span>
          <span
            v-if="contact && contact.name"
            class="text-xs text-[#5DCAA5] opacity-70"
          >
            {{ contact.name }}
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

      <!-- Content -->
      <div class="flex-1 overflow-y-auto p-5 space-y-4">
        <!-- Reserva reference -->
        <div class="rounded-lg p-3 bg-[#E1F5EE]">
          <div
            class="text-[10px] font-bold uppercase tracking-wide mb-1.5 text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.RESERVA_REF') }}
          </div>
          <div class="text-sm font-bold text-[#0D2B2A]">
            {{ reserva.produto }}
          </div>
          <div class="text-xs text-[#0F6E56] mt-0.5">
            {{ fmt.format(reserva.valorTotal) }}
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <!-- Tipo -->
          <div>
            <label
              class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
            >
              {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.TIPO_LABEL') }}
            </label>
            <select
              v-model="form.tipo"
              class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A]"
            >
              <option value="sinal">
                {{
                  $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.TIPO_SINAL')
                }}
              </option>
              <option value="acerto">
                {{
                  $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.TIPO_ACERTO')
                }}
              </option>
            </select>
          </div>

          <!-- Forma de pagamento -->
          <div>
            <label
              class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
            >
              {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_LABEL') }}
            </label>
            <select
              v-model="form.formaPagamento"
              class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A]"
            >
              <option value="pix">
                {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_PIX') }}
              </option>
              <option value="cartao">
                {{
                  $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_CARTAO')
                }}
              </option>
              <option value="dinheiro">
                {{
                  $t(
                    'CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_DINHEIRO'
                  )
                }}
              </option>
              <option value="boleto">
                {{
                  $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_BOLETO')
                }}
              </option>
              <option value="transferencia">
                {{
                  $t(
                    'CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.FORMA_TRANSFERENCIA'
                  )
                }}
              </option>
            </select>
          </div>

          <!-- Valor -->
          <div>
            <label
              class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
            >
              {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.VALOR_LABEL') }}
            </label>
            <input
              v-model.number="form.valor"
              type="number"
              min="0"
              step="0.01"
              class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A]"
            />
          </div>

          <!-- Data -->
          <div>
            <label
              class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
            >
              {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.DATA_LABEL') }}
            </label>
            <input
              v-model="form.data"
              type="date"
              class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A]"
            />
          </div>
        </div>

        <!-- Obs -->
        <div>
          <label
            class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
          >
            {{ $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.OBS_LABEL') }}
          </label>
          <textarea
            v-model="form.obs"
            rows="2"
            class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A] resize-none"
          />
        </div>

        <p v-if="error" class="text-[11px] text-red-500 text-center">
          {{ error }}
        </p>
      </div>

      <!-- Footer -->
      <div
        class="flex justify-between px-5 py-4 border-t border-[#b2dfd0] shrink-0"
      >
        <button
          class="px-4 py-2 rounded text-sm font-bold border border-[#b2dfd0] text-[#0F6E56] disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="isCreating"
          @click="emit('close')"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.BACK') }}
        </button>
        <button
          class="px-4 py-2 rounded text-sm font-bold text-white bg-[#1D9E75] flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          :disabled="isCreating"
          @click="handleConfirm"
        >
          <Spinner v-if="isCreating" :size="14" class="text-white" />
          {{
            isCreating
              ? $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.CREATING')
              : $t('CONVERSATION_SIDEBAR.VIARI.PAGAMENTO_MODAL.CONFIRM')
          }}
        </button>
      </div>
    </div>
  </div>
</template>
