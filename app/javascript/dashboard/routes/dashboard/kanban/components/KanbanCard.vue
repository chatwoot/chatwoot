<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

const props = defineProps({
  card: { type: Object, required: true },
});

const emit = defineEmits(['edit', 'delete']);

useI18n();
const router = useRouter();

const contactInitials = computed(() => {
  const name = props.card.contact?.name || '?';
  return name
    .split(' ')
    .slice(0, 2)
    .map(n => n[0])
    .join('')
    .toUpperCase();
});

const formattedValue = computed(() => {
  if (props.card.potential_value == null) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(props.card.potential_value);
});

function openContact() {
  router.push({
    name: 'contact-page',
    params: { contactId: props.card.contact.id },
  });
}
</script>

<template>
  <div
    class="bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 p-3 cursor-pointer hover:shadow-md transition-shadow group"
  >
    <div class="flex items-start justify-between gap-2">
      <!-- Avatar + Nome -->
      <div class="flex items-center gap-2 min-w-0">
        <div
          v-if="card.contact?.avatar_url"
          class="w-8 h-8 rounded-full flex-shrink-0 bg-cover bg-center"
          :style="{ backgroundImage: `url(${card.contact.avatar_url})` }"
        />
        <div
          v-else
          class="w-8 h-8 rounded-full flex-shrink-0 bg-woot-500 text-white text-xs font-semibold flex items-center justify-center"
        >
          {{ contactInitials }}
        </div>
        <div class="min-w-0">
          <p
            class="text-sm font-medium text-slate-800 dark:text-slate-100 truncate"
          >
            {{ card.contact?.name }}
          </p>
          <p
            v-if="card.contact?.phone_number"
            class="text-xs text-slate-500 dark:text-slate-400 truncate"
          >
            {{ card.contact.phone_number }}
          </p>
        </div>
      </div>

      <!-- Ações (aparecem no hover) -->
      <div
        class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0"
      >
        <button
          class="p-1 rounded text-slate-400 hover:text-woot-500 hover:bg-slate-100 dark:hover:bg-slate-700"
          :title="$t('KANBAN.CARD.OPEN_CONTACT')"
          @click.stop="openContact"
        >
          <fluent-icon icon="person" size="14" />
        </button>
        <button
          class="p-1 rounded text-slate-400 hover:text-woot-500 hover:bg-slate-100 dark:hover:bg-slate-700"
          :title="$t('KANBAN.CARD.EDIT')"
          @click.stop="emit('edit', card)"
        >
          <fluent-icon icon="edit" size="14" />
        </button>
        <button
          class="p-1 rounded text-slate-400 hover:text-red-500 hover:bg-slate-100 dark:hover:bg-slate-700"
          :title="$t('KANBAN.CARD.DELETE')"
          @click.stop="emit('delete', card)"
        >
          <fluent-icon icon="delete" size="14" />
        </button>
      </div>
    </div>

    <!-- Valor potencial -->
    <div v-if="formattedValue" class="mt-2 flex items-center gap-1">
      <fluent-icon icon="money" size="12" class="text-green-600" />
      <span class="text-xs font-semibold text-green-600">{{
        formattedValue
      }}</span>
    </div>

    <!-- Notas -->
    <p
      v-if="card.notes"
      class="mt-2 text-xs text-slate-500 dark:text-slate-400 line-clamp-2"
    >
      {{ card.notes }}
    </p>
  </div>
</template>
