<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';

const props = defineProps({
  card: { type: Object, required: true },
});

const emit = defineEmits(['close', 'updated']);

useI18n();
const store = useStore();
const router = useRouter();

const potentialValue = ref(props.card.potential_value ?? '');
const notes = ref(props.card.notes ?? '');
const isSaving = ref(false);
const conversations = ref([]);
const isLoadingConversations = ref(false);

const contact = computed(() => props.card.contact);

const formattedValue = computed(() => {
  if (!potentialValue.value) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(potentialValue.value);
});

onMounted(async () => {
  if (!contact.value?.id) return;
  isLoadingConversations.value = true;
  try {
    await store.dispatch(
      'contacts/fetchContactConversations',
      contact.value.id
    );
    conversations.value =
      store.getters['contacts/getContactConversations'](contact.value.id) || [];
  } finally {
    isLoadingConversations.value = false;
  }
});

async function save() {
  isSaving.value = true;
  try {
    await store.dispatch('kanban/updateCard', {
      id: props.card.id,
      potential_value: potentialValue.value || null,
      notes: notes.value || null,
    });
    emit('updated');
    emit('close');
  } finally {
    isSaving.value = false;
  }
}

function openContact() {
  router.push({
    name: 'contact-page',
    params: { contactId: contact.value.id },
  });
  emit('close');
}

async function openOrCreateConversation() {
  if (conversations.value.length > 0) {
    const conv = conversations.value[0];
    router.push({
      name: 'conversation',
      params: {
        accountId: store.getters['auth/getCurrentUser'].account_id,
        id: conv.id,
      },
    });
    emit('close');
  } else {
    // Create a new conversation — navigate to new conversation flow with contact pre-filled
    router.push({
      name: 'new-conversation',
      query: { contactId: contact.value.id },
    });
    emit('close');
  }
}
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40"
    @click.self="emit('close')"
  >
    <div
      class="bg-white dark:bg-slate-800 rounded-xl shadow-xl w-full max-w-md mx-4"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between p-4 border-b border-slate-200 dark:border-slate-700"
      >
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-full bg-woot-500 text-white flex items-center justify-center font-semibold text-sm"
          >
            {{ contact?.name?.[0]?.toUpperCase() }}
          </div>
          <div>
            <p class="font-semibold text-slate-800 dark:text-slate-100">
              {{ contact?.name }}
            </p>
            <p class="text-xs text-slate-500">{{ contact?.phone_number }}</p>
          </div>
        </div>
        <button
          class="text-slate-400 hover:text-slate-600"
          @click="emit('close')"
        >
          <fluent-icon icon="dismiss" size="16" />
        </button>
      </div>

      <!-- Body -->
      <div class="p-4 space-y-4">
        <!-- Ações rápidas -->
        <div class="flex gap-2">
          <button
            class="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 text-sm text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
            @click="openContact"
          >
            <fluent-icon icon="person" size="14" />
            {{ $t('KANBAN.CARD.OPEN_CONTACT') }}
          </button>
          <button
            class="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg border border-woot-400 text-sm text-woot-600 dark:text-woot-400 hover:bg-woot-50 dark:hover:bg-woot-900/20"
            @click="openOrCreateConversation"
          >
            <fluent-icon icon="chat" size="14" />
            <span v-if="isLoadingConversations">...</span>
            <span v-else-if="conversations.length > 0">{{
              $t('KANBAN.CARD.OPEN_CONVERSATION')
            }}</span>
            <span v-else>{{ $t('KANBAN.CARD.NEW_CONVERSATION') }}</span>
          </button>
        </div>

        <!-- Valor potencial -->
        <div>
          <label
            class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
          >
            {{ $t('KANBAN.ADD_CARD.POTENTIAL_VALUE') }}
          </label>
          <input
            v-model="potentialValue"
            type="number"
            min="0"
            step="0.01"
            class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
          />
          <p v-if="formattedValue" class="text-xs text-green-600 mt-0.5">
            {{ formattedValue }}
          </p>
        </div>

        <!-- Notas -->
        <div>
          <label
            class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
          >
            {{ $t('KANBAN.ADD_CARD.NOTES') }}
          </label>
          <textarea
            v-model="notes"
            rows="3"
            class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500 resize-none"
          />
        </div>

        <!-- Histórico de movimentações -->
        <div
          v-if="card.activities?.length"
          class="text-xs text-slate-500 dark:text-slate-400"
        >
          <p class="font-medium mb-1">{{ $t('KANBAN.CARD.HISTORY') }}</p>
          <ul class="space-y-0.5">
            <li v-for="activity in card.activities" :key="activity.id">
              {{
                $t('KANBAN.CARD.HISTORY_ENTRY', {
                  from:
                    activity.from_column?.name ||
                    $t('KANBAN.CARD.HISTORY_INITIAL'),
                  to: activity.to_column?.name,
                })
              }}
            </li>
          </ul>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end gap-2 px-4 pb-4">
        <button
          class="px-4 py-2 text-sm rounded border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:bg-slate-50"
          @click="emit('close')"
        >
          {{ $t('CANCEL') }}
        </button>
        <button
          class="px-4 py-2 text-sm rounded bg-woot-500 text-white hover:bg-woot-600 disabled:opacity-50"
          :disabled="isSaving"
          @click="save"
        >
          {{ $t('SAVE') }}
        </button>
      </div>
    </div>
  </div>
</template>
