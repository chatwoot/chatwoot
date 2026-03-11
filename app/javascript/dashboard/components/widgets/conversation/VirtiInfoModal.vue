<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import virtiAuth from 'dashboard/api/virtiAuth';
import { virtiGet, virtiPut, virtiDelete } from 'dashboard/api/virtiBackend';

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
const saving = ref(false);
const deleteConfirmIndex = ref(null);

// Array reativo de { key, val, originalKey, originalVal, isNew }
const varsEntries = ref([]);

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

const idRobo = computed(() => virtiAuth.getIdRobo());

const fetchData = async () => {
  isLoading.value = true;
  errorMessage.value = '';

  if (!idRobo.value || !idUsuario.value) {
    errorMessage.value = 'Dados insuficientes para buscar informações.';
    isLoading.value = false;
    return;
  }

  try {
    const res = await virtiGet(
      `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}`
    );
    const data = res?.data || {};
    varsEntries.value = Object.entries(data)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, val]) => ({
        key,
        val: val ?? '',
        originalKey: key,
        originalVal: val ?? '',
        isNew: false,
      }));
  } catch (err) {
    errorMessage.value =
      err?.response?.data?.message || 'Erro ao buscar dados.';
  } finally {
    isLoading.value = false;
  }
};

const saveEntry = async entry => {
  if (!idRobo.value || !idUsuario.value) return;

  // Nova variável: precisa de chave preenchida para salvar
  if (entry.isNew) {
    if (!entry.key) return;
    saving.value = true;
    try {
      await virtiPut(
        `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}/${entry.key}`,
        { value: entry.val }
      );
      entry.originalKey = entry.key;
      entry.originalVal = entry.val;
      entry.isNew = false;
      useAlert('Variável adicionada.');
    } catch {
      useAlert('Erro ao adicionar variável.');
    } finally {
      saving.value = false;
    }
    return;
  }

  // Nada mudou
  const keyChanged = entry.key !== entry.originalKey;
  const valChanged = entry.val !== entry.originalVal;
  if (!keyChanged && !valChanged) return;

  // Chave vazia: reverter
  if (!entry.key) {
    entry.key = entry.originalKey;
    return;
  }

  saving.value = true;
  try {
    if (keyChanged) {
      // Renomear: criar nova chave, deletar antiga
      await virtiPut(
        `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}/${entry.key}`,
        { value: entry.val }
      );
      await virtiDelete(
        `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}/${entry.originalKey}`
      );
      entry.originalKey = entry.key;
      entry.originalVal = entry.val;
      useAlert('Chave atualizada.');
    } else {
      // Só valor mudou
      await virtiPut(
        `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}/${entry.key}`,
        { value: entry.val }
      );
      entry.originalVal = entry.val;
      useAlert('Valor atualizado.');
    }
  } catch {
    entry.key = entry.originalKey;
    entry.val = entry.originalVal;
    useAlert('Erro ao salvar variável.');
  } finally {
    saving.value = false;
  }
};

const addNewEntry = () => {
  varsEntries.value.push({
    key: '',
    val: '',
    originalKey: '',
    originalVal: '',
    isNew: true,
  });
};

const deleteEntry = async (entry, index) => {
  // Confirmação inline: primeiro clique marca, segundo executa
  if (deleteConfirmIndex.value !== index) {
    deleteConfirmIndex.value = index;
    return;
  }

  deleteConfirmIndex.value = null;

  // Se nunca foi salva, apenas remove do array
  if (entry.isNew) {
    varsEntries.value.splice(index, 1);
    return;
  }

  saving.value = true;
  try {
    await virtiDelete(
      `/api/v1/vars_user/${idRobo.value}/${idUsuario.value}/${entry.originalKey}`
    );
    varsEntries.value.splice(index, 1);
    useAlert('Variável excluída.');
  } catch {
    useAlert('Erro ao excluir variável.');
  } finally {
    saving.value = false;
  }
};

const cancelDelete = () => {
  deleteConfirmIndex.value = null;
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
      <div>
        <h4 class="mb-2 text-sm font-medium text-n-slate-12">
          Variáveis coletadas
        </h4>

        <!-- Empty state -->
        <div
          v-if="varsEntries.length === 0"
          class="py-4 text-sm text-center text-n-slate-11"
        >
          Nenhuma variável coletada nesta conversa.
        </div>

        <!-- Entries -->
        <div v-else class="flex flex-col gap-1.5">
          <div
            v-for="(entry, index) in varsEntries"
            :key="index"
            class="flex items-center gap-2 group"
          >
            <!-- Key input -->
            <input
              :value="entry.key"
              @input="entry.key = $event.target.value"
              type="text"
              placeholder="Chave"
              :disabled="saving"
              class="w-2/5 px-2 py-1.5 text-sm font-medium rounded-md border-0 outline outline-1 outline-n-weak bg-transparent text-n-slate-11 placeholder:text-n-slate-9 focus:outline-n-brand transition-colors"
              @blur="saveEntry(entry)"
            />
            <!-- Value input -->
            <input
              :value="entry.val"
              @input="entry.val = $event.target.value"
              type="text"
              placeholder="Valor"
              :disabled="saving"
              class="w-3/5 px-2 py-1.5 text-sm rounded-md border-0 outline outline-1 outline-n-weak bg-transparent text-n-slate-11 placeholder:text-n-slate-9 focus:outline-n-brand transition-colors"
              @blur="saveEntry(entry)"
            />
            <!-- Delete button (default state) -->
            <button
              v-if="deleteConfirmIndex !== index"
              type="button"
              :disabled="saving"
              class="inline-flex items-center justify-center w-7 h-7 rounded-md text-n-slate-10 hover:text-n-ruby-11 hover:bg-n-alpha-2 transition-colors opacity-0 group-hover:opacity-100 flex-shrink-0 disabled:opacity-50"
              @click="deleteEntry(entry, index)"
            >
              <Icon icon="i-lucide-trash-2" class="size-3.5" />
            </button>
            <!-- Delete confirm button -->
            <button
              v-else
              type="button"
              :disabled="saving"
              class="inline-flex items-center justify-center h-7 px-2 rounded-md text-xs font-medium text-white bg-n-ruby-9 hover:bg-n-ruby-10 transition-colors flex-shrink-0 disabled:opacity-50"
              @click="deleteEntry(entry, index)"
              @blur="cancelDelete"
            >
              Excluir?
            </button>
          </div>
        </div>

        <!-- Add button -->
        <div class="flex justify-center mt-3">
          <ButtonV4
            size="sm"
            variant="faded"
            color="slate"
            icon="i-lucide-plus"
            label="Adicionar"
            :disabled="saving"
            class="rounded-md"
            @click="addNewEntry"
          />
        </div>
      </div>
    </div>
  </Dialog>
</template>
