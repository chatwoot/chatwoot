<script setup>
import { ref, onMounted } from 'vue';
import ViariAPI from 'dashboard/api/integrations/viari';

const props = defineProps({
  initialData: { type: Object, required: true },
});

const emit = defineEmits(['next']);

const canais = ref([]);
const errors = ref({});

function todayStr() {
  return new Date().toISOString().substring(0, 10);
}
function plus30Str() {
  const d = new Date();
  d.setDate(d.getDate() + 30);
  return d.toISOString().substring(0, 10);
}

const form = ref({
  canalVendaId: props.initialData.canalVendaId ?? '',
  periodoInicio: props.initialData.periodoInicio || todayStr(),
  periodoFim: props.initialData.periodoFim || plus30Str(),
  dataValidade: props.initialData.dataValidade || plus30Str(),
  obsInternas: props.initialData.obsInternas ?? '',
  msgCliente: props.initialData.msgCliente ?? '',
});

const validate = () => {
  errors.value = {};
  if (!form.value.periodoInicio) errors.value.periodoInicio = true;
  if (!form.value.periodoFim) errors.value.periodoFim = true;
  if (!form.value.dataValidade) errors.value.dataValidade = true;
  return Object.keys(errors.value).length === 0;
};

const handleNext = () => {
  if (!validate()) return;
  const canal = canais.value.find(c => c.id === form.value.canalVendaId);
  emit('next', { ...form.value, grupoTarifaId: canal?.grupoTarifaId ?? null });
};

onMounted(async () => {
  try {
    const r = await ViariAPI.getCanaisVenda();
    canais.value = r.data.canais ?? [];
  } catch {
    // canal is optional
  }
});
</script>

<template>
  <div class="p-5">
    <div class="grid grid-cols-2 gap-4">
      <!-- Period start -->
      <div>
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_START_LABEL') }}
        </label>
        <input
          v-model="form.periodoInicio"
          type="date"
          class="w-full px-3 py-1.5 text-sm rounded border bg-[#f8fffe] text-[#0D2B2A]"
          :class="errors.periodoInicio ? 'border-red-400' : 'border-[#b2dfd0]'"
        />
        <p v-if="errors.periodoInicio" class="text-[10px] text-red-500 mt-0.5">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.REQUIRED') }}
        </p>
      </div>

      <!-- Period end -->
      <div>
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.PERIOD_END_LABEL') }}
        </label>
        <input
          v-model="form.periodoFim"
          type="date"
          class="w-full px-3 py-1.5 text-sm rounded border bg-[#f8fffe] text-[#0D2B2A]"
          :class="errors.periodoFim ? 'border-red-400' : 'border-[#b2dfd0]'"
        />
        <p v-if="errors.periodoFim" class="text-[10px] text-red-500 mt-0.5">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.REQUIRED') }}
        </p>
      </div>

      <!-- Validity date -->
      <div>
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.VALIDITY_LABEL') }}
        </label>
        <input
          v-model="form.dataValidade"
          type="date"
          class="w-full px-3 py-1.5 text-sm rounded border bg-[#f8fffe] text-[#0D2B2A]"
          :class="errors.dataValidade ? 'border-red-400' : 'border-[#b2dfd0]'"
        />
        <p v-if="errors.dataValidade" class="text-[10px] text-red-500 mt-0.5">
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.REQUIRED') }}
        </p>
      </div>

      <!-- Sales channel -->
      <div>
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.CANAL_LABEL') }}
        </label>
        <select
          v-model="form.canalVendaId"
          class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A]"
        >
          <option value="">
            {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.SELECT_PLACEHOLDER') }}
          </option>
          <option v-for="c in canais" :key="c.id" :value="c.id">
            {{ c.nome }}
          </option>
        </select>
      </div>

      <!-- Internal notes -->
      <div class="col-span-2">
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.OBS_LABEL') }}
        </label>
        <textarea
          v-model="form.obsInternas"
          rows="3"
          class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A] resize-none"
        />
      </div>

      <!-- Message for client -->
      <div class="col-span-2">
        <label
          class="block text-[10px] font-bold uppercase tracking-wide mb-1 text-[#0F6E56]"
        >
          {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.MSG_LABEL') }}
        </label>
        <textarea
          v-model="form.msgCliente"
          rows="3"
          class="w-full px-3 py-1.5 text-sm rounded border border-[#b2dfd0] bg-[#f8fffe] text-[#0D2B2A] resize-none"
        />
      </div>
    </div>

    <!-- Footer -->
    <div class="flex justify-end mt-5">
      <button
        class="px-4 py-2 rounded text-sm font-bold text-white bg-[#1D9E75]"
        @click="handleNext"
      >
        {{ $t('CONVERSATION_SIDEBAR.VIARI.MODAL.NEXT') }}
      </button>
    </div>
  </div>
</template>
