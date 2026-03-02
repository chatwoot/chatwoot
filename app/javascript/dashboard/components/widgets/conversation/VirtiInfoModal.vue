<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
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
// COMENTADO: infoscard desabilitado por enquanto
// const infosUser = ref({});
const varsUser = ref({});

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

// COMENTADO: infoscard desabilitado por enquanto
// const infosEntries = computed(() => {
//   const hidden = ['task_id', 'chatwoot_conversation_id', 'chatwoot_inbox_id', 'chatwoot_contact_id'];
//   return Object.entries(infosUser.value)
//     .filter(([key]) => !hidden.includes(key))
//     .sort(([a], [b]) => a.localeCompare(b));
// });

const varsEntries = computed(() => {
  return Object.entries(varsUser.value)
    .sort(([a], [b]) => a.localeCompare(b));
});

const fetchData = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  const idRobo = virtiAuth.getIdRobo();
  if (!idRobo || !idUsuario.value) {
    errorMessage.value = 'Dados insuficientes para buscar informações.';
    isLoading.value = false;
    return;
  }

  try {
    // COMENTADO: infoscard desabilitado por enquanto
    // const response = await virtiGet(
    //   `/apiportal/v1/conversas/infoscard/?idRobo=${idRobo}&idUsuario=${idUsuario.value}`
    // );
    // const data = response?.data || {};
    // infosUser.value = data;

    // Buscar vars_user (variáveis coletadas pelo robô)
    const varsResponse = await virtiGet(
      `/api/v1/vars_user/${idRobo}/${idUsuario.value}`
    );
    varsUser.value = varsResponse?.data || {};
  } catch (err) {
    errorMessage.value = err?.response?.data?.message || 'Erro ao buscar dados.';
  } finally {
    isLoading.value = false;
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
    title="Informações do Contato"
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
    <div v-else class="flex flex-col gap-4 max-h-[60vh] overflow-y-auto">
      <!-- COMENTADO: infoscard desabilitado por enquanto -->
      <!-- <div v-if="infosEntries.length > 0">
        <h4 class="mb-2 text-sm font-medium text-n-slate-12">
          Dados da conversa
        </h4>
        <table class="w-full text-sm">
          <tbody>
            <tr
              v-for="([key, value]) in infosEntries"
              :key="key"
              class="border-b border-n-weak"
            >
              <td class="py-1.5 pr-3 font-medium text-n-slate-11 whitespace-nowrap align-top">
                {{ key }}
              </td>
              <td class="py-1.5 text-n-slate-12 break-all">
                {{ value ?? '-' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div> -->

      <!-- Vars do usuário (dados coletados pelo robô) -->
      <div v-if="varsEntries.length > 0">
        <h4 class="mb-2 text-sm font-medium text-n-slate-12">
          Variáveis coletadas
        </h4>
        <table class="w-full text-sm">
          <tbody>
            <tr
              v-for="([key, value]) in varsEntries"
              :key="key"
              class="border-b border-n-weak"
            >
              <td class="py-1.5 pr-3 font-medium text-n-slate-11 whitespace-nowrap align-top">
                {{ key }}
              </td>
              <td class="py-1.5 text-n-slate-12 break-all">
                {{ value ?? '-' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Empty state -->
      <div
        v-if="varsEntries.length === 0"
        class="py-4 text-sm text-center text-n-slate-11"
      >
        Nenhuma informação coletada nesta conversa.
      </div>
    </div>
  </Dialog>
</template>
