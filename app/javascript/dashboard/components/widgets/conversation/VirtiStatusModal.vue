<script setup>
import { ref, onMounted, computed } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const props = defineProps({
  statusConversa: {
    type: String,
    default: 'Desconhecido',
  },
  etapa: {
    type: String,
    default: 'Desconhecida',
  },
  bloqueado: {
    type: Boolean,
    default: false,
  },
  followUpsEnviados: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['close']);
const dialogRef = ref(null);

const statusColor = computed(() => {
  switch (props.statusConversa) {
    case 'Em andamento': return 'text-n-teal-11';
    case 'Finalizado': return 'text-n-blue-text';
    case 'Abandonado': return 'text-n-ruby-11';
    case 'Não Monitorado':
    case 'Desconhecido': return 'text-n-slate-11';
    default:
      if (props.statusConversa.startsWith('FollowUps')) return 'text-n-blue-text';
      return 'text-n-slate-12';
  }
});

const bloqueadoColor = computed(() =>
  props.bloqueado ? 'text-n-ruby-11' : 'text-n-teal-11'
);

onMounted(() => {
  dialogRef.value?.open();
});

const handleClose = () => {
  emit('close');
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    title="Status da Conversa"
    :show-confirm-button="false"
    cancel-button-label="Fechar"
    width="xl"
    @close="handleClose"
  >
    <div class="flex flex-col">
      <table class="w-full text-sm">
        <tbody>
          <tr class="border-b border-n-weak">
            <td class="py-2.5 pr-4 font-medium text-n-slate-11 whitespace-nowrap">
              Status
            </td>
            <td class="py-2.5 font-medium" :class="statusColor">
              {{ statusConversa }}
            </td>
          </tr>
          <tr class="border-b border-n-weak">
            <td class="py-2.5 pr-4 font-medium text-n-slate-11 whitespace-nowrap">
              Etapa Atual
            </td>
            <td class="py-2.5 text-n-slate-12">
              {{ etapa }}
            </td>
          </tr>
          <tr class="border-b border-n-weak">
            <td class="py-2.5 pr-4 font-medium text-n-slate-11 whitespace-nowrap">
              Bloqueado
            </td>
            <td class="py-2.5 font-medium" :class="bloqueadoColor">
              {{ bloqueado ? 'Sim' : 'Não' }}
            </td>
          </tr>
          <tr>
            <td class="py-2.5 pr-4 font-medium text-n-slate-11 whitespace-nowrap">
              Follow-ups Enviados
            </td>
            <td class="py-2.5 text-n-slate-12">
              {{ followUpsEnviados }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </Dialog>
</template>
