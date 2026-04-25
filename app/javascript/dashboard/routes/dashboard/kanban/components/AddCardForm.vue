<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useDebounce } from '@vueuse/core';

const props = defineProps({
  columnId: { type: Number, required: true },
});

const emit = defineEmits(['created', 'cancel']);

const { t } = useI18n();
const store = useStore();

const phone = ref('');
const contactName = ref('');
const email = ref('');
const potentialValue = ref('');
const notes = ref('');
const searchResult = ref(null);
const isSearching = ref(false);
const isSubmitting = ref(false);
const error = ref('');

const debouncedPhone = useDebounce(phone, 400);

watch(debouncedPhone, async val => {
  if (!val || val.length < 8) {
    searchResult.value = null;
    return;
  }
  isSearching.value = true;
  try {
    const contacts = store.getters['contacts/getContacts'];
    const cleaned = val.replace(/\D/g, '');
    const found = contacts.find(c =>
      c.phone_number?.replace(/\D/g, '').endsWith(cleaned)
    );
    if (found) {
      searchResult.value = found;
      contactName.value = found.name;
    } else {
      // Search via API
      await store.dispatch('contacts/search', { search: val, page: 1 });
      const results = store.getters['contacts/getContacts'];
      const match = results.find(c =>
        c.phone_number?.replace(/\D/g, '').endsWith(cleaned)
      );
      searchResult.value = match || null;
      if (match) contactName.value = match.name;
    }
  } finally {
    isSearching.value = false;
  }
});

async function submit() {
  if (!phone.value && !email.value) {
    error.value = t('KANBAN.ADD_CARD.ERROR_PHONE_OR_EMAIL');
    return;
  }
  error.value = '';
  isSubmitting.value = true;
  try {
    await store.dispatch('kanban/createCard', {
      columnId: props.columnId,
      params: {
        phone_number: phone.value,
        email: email.value,
        contact_name: contactName.value,
        potential_value: potentialValue.value || null,
        notes: notes.value || null,
      },
    });
    emit('created');
  } catch (e) {
    const msg = e?.response?.data?.message;
    error.value = msg || t('KANBAN.ADD_CARD.ERROR_GENERIC');
  } finally {
    isSubmitting.value = false;
  }
}
</script>

<template>
  <div
    class="bg-white dark:bg-slate-800 rounded-lg border border-woot-400 p-3 space-y-3"
  >
    <!-- Telefone com busca -->
    <div>
      <label
        class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
      >
        {{ $t('KANBAN.ADD_CARD.PHONE') }}
      </label>
      <div class="relative">
        <input
          v-model="phone"
          type="tel"
          class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
          :placeholder="$t('KANBAN.ADD_CARD.PHONE_PLACEHOLDER')"
        />
        <fluent-icon
          v-if="isSearching"
          icon="spinner"
          size="14"
          class="absolute right-2 top-2 animate-spin text-slate-400"
        />
      </div>

      <!-- Preview do contato encontrado -->
      <div
        v-if="searchResult"
        class="mt-1 flex items-center gap-2 text-xs text-green-700 dark:text-green-400 bg-green-50 dark:bg-green-900/20 rounded px-2 py-1"
      >
        <fluent-icon icon="checkmark-circle" size="12" />
        {{ $t('KANBAN.ADD_CARD.CONTACT_FOUND', { name: searchResult.name }) }}
      </div>
    </div>

    <!-- Nome (pré-preenchido se encontrou, editável se não) -->
    <div v-if="!searchResult">
      <label
        class="block text-xs font-medium text-slate-600 dark:text-slate-300 mb-1"
      >
        {{ $t('KANBAN.ADD_CARD.NAME') }}
      </label>
      <input
        v-model="contactName"
        type="text"
        class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500"
        :placeholder="$t('KANBAN.ADD_CARD.NAME_PLACEHOLDER')"
      />
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
        :placeholder="$t('KANBAN.ADD_CARD.POTENTIAL_VALUE_PLACEHOLDER')"
      />
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
        rows="2"
        class="w-full text-sm rounded border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 px-3 py-1.5 focus:outline-none focus:ring-1 focus:ring-woot-500 resize-none"
        :placeholder="$t('KANBAN.ADD_CARD.NOTES_PLACEHOLDER')"
      />
    </div>

    <p v-if="error" class="text-xs text-red-500">{{ error }}</p>

    <div class="flex gap-2 justify-end">
      <button
        class="px-3 py-1.5 text-xs rounded border border-slate-300 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700"
        @click="emit('cancel')"
      >
        {{ $t('CANCEL') }}
      </button>
      <button
        class="px-3 py-1.5 text-xs rounded bg-woot-500 text-white hover:bg-woot-600 disabled:opacity-50"
        :disabled="isSubmitting"
        @click="submit"
      >
        {{ $t('KANBAN.ADD_CARD.SUBMIT') }}
      </button>
    </div>
  </div>
</template>
