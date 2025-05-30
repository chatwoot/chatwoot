<script setup>
import { computed, ref } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  inboxesCount: {
    type: Number,
    default: 0,
  },
  documentCount: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['action']);
const { checkPermissions } = usePolicy();
const { t, locale } = useI18n();
const [showActionsDropdown, toggleDropdown] = useToggle();
const isAdmin = computed(() => checkPermissions(['administrator']));

const lastUpdatedAt = computed(() => dynamicTime(props.updatedAt));

const handleAction = (action) => {
  toggleDropdown(false);
  emit('action', { action, id: props.id });
};

// Helper function for other labels
const getLabel = (key, params = {}) => {
  if (locale.value === 'fr') {
    if (key === 'AI_AGENT.TOPICS.INBOXES_COUNT') {
      return `Boîtes de réception: ${params.count}`;
    }
    if (key === 'AI_AGENT.TOPICS.DOCUMENTS_COUNT') {
      return `Documents: ${params.count}`;
    }
  }
  return t(key, params);
};

// Get translated button labels based on locale
const getInboxesLabel = () => {
  return locale.value === 'fr' 
    ? 'Voir les boîtes de réception connectées'
    : 'View Connected Inboxes';
};

const getEditLabel = () => {
  return locale.value === 'fr'
    ? 'Modifier le sujet'
    : 'Edit Topic';
};

const getDeleteLabel = () => {
  return locale.value === 'fr'
    ? 'Supprimer le sujet'
    : 'Delete Topic';
};
</script>

<template>
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <router-link
        :to="{ name: 'ai_agent_topics_edit', params: { topicId: id } }"
        class="text-base text-n-slate-12 line-clamp-1 hover:underline transition-colors"
      >
        {{ name }}
      </router-link>
      <div class="flex items-center gap-2">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="relative flex items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <!-- Custom dropdown menu implementation -->
          <div
            v-if="showActionsDropdown"
            class="bg-white dark:bg-slate-800 absolute mt-1 right-0 top-full rounded-lg shadow-lg py-2 px-2 z-50 min-w-[180px] border border-slate-200 dark:border-slate-700"
          >
            <button
              type="button"
              class="w-full text-left px-3 py-2 text-sm flex items-center gap-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700"
              @click="handleAction('viewConnectedInboxes')"
            >
              <Icon icon="i-lucide-link" class="size-4" />
              <span>{{ getInboxesLabel() }}</span>
            </button>
            
            <template v-if="isAdmin">
              <button
                type="button"
                class="w-full text-left px-3 py-2 text-sm flex items-center gap-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700"
                @click="handleAction('edit')"
              >
                <Icon icon="i-lucide-pencil-line" class="size-4" />
                <span>{{ getEditLabel() }}</span>
              </button>
              
              <button
                type="button"
                class="w-full text-left px-3 py-2 text-sm flex items-center gap-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 text-red-600"
                @click="handleAction('delete')"
              >
                <Icon icon="i-lucide-trash" class="size-4" />
                <span>{{ getDeleteLabel() }}</span>
              </button>
            </template>
          </div>
        </div>
      </div>
    </div>
    <div class="flex items-center justify-between w-full gap-4">
      <span class="text-sm truncate text-n-slate-11">
        {{ description || 'Description not available' }}
      </span>
      <span class="text-sm text-n-slate-11 line-clamp-1 shrink-0">
        {{ lastUpdatedAt }}
      </span>
    </div>
    <div
      v-if="inboxesCount || documentCount"
      class="flex items-center gap-4 mt-2"
    >
      <span v-if="inboxesCount" class="text-xs text-n-slate-10">
        {{ getLabel('AI_AGENT.TOPICS.INBOXES_COUNT', { count: inboxesCount }) }}
      </span>
      <span v-if="documentCount" class="text-xs text-n-slate-10">
        {{ getLabel('AI_AGENT.TOPICS.DOCUMENTS_COUNT', { count: documentCount }) }}
      </span>
    </div>
  </CardLayout>
</template>
