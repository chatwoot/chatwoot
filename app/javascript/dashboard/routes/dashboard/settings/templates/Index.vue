<!-- eslint-disable vue/no-bare-strings-in-template -->
<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import AddTemplate from './AddTemplate.vue';
import { getTemplatesDemo, deleteTemplate } from './helpers/templatesHelper';

const { t } = useI18n();

const loading = ref({});
const isLoading = ref(false);
const templates = ref([]);
const showDeleteConfirmationPopup = ref(false);
const showAddPopup = ref(false);
const selectedTemplate = ref({});

// TODO: maybe change this filters to object , will check it after backend
const selectedContent = ref('Content');
const selectedChannel = ref('Channel');
const selectedLanguage = ref('English (en-US)');

const filteredTemplates = computed(() => {
  let filtered = templates.value;

  // TODO: Apply filters here
  return filtered;
});

const deleteMessage = computed(() => ` ${selectedTemplate.value.name}?`);

const fetchTemplates = async () => {
  isLoading.value = true;
  try {
    const data = await getTemplatesDemo();
    templates.value = data;
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.API.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const openAddPopup = () => {
  showAddPopup.value = true;
};

const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openDeletePopup = template => {
  showDeleteConfirmationPopup.value = true;
  selectedTemplate.value = template;
};

const closeDeletePopup = () => {
  showDeleteConfirmationPopup.value = false;
};

const confirmDeletion = async () => {
  loading.value[selectedTemplate.value.id] = true;
  closeDeletePopup();

  try {
    await deleteTemplate(selectedTemplate.value.id);
    templates.value = templates.value.filter(
      tem => tem.id !== selectedTemplate.value.id
    );
    useAlert(t('SETTINGS.TEMPLATES.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('SETTINGS.TEMPLATES.DELETE.ERROR'));
  } finally {
    loading.value[selectedTemplate.value.id] = false;
  }
};

const getStatusColor = status => {
  switch (status) {
    case 'approved':
      return 'text-green-600';
    case 'pending':
      return 'text-yellow-600';
    case 'rejected':
      return 'text-red-600';
    default:
      return 'text-gray-600';
  }
};

// TODO: fix me
const formatCategory = category => {
  return category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const getTemplateIcon = category => {
  switch (category) {
    case 'marketing':
      return 'i-lucide-megaphone';
    case 'authentication':
      return 'i-lucide-shield-check';
    case 'utility':
      return 'i-lucide-settings';
    default:
      return 'i-lucide-message-square';
  }
};

onMounted(() => {
  fetchTemplates();
});
</script>

<template>
  <div class="flex flex-col w-full h-full font-inter">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('SETTINGS.TEMPLATES.HEADER.TITLE') }}
        </h1>
        <a href="#" class="text-sm text-n-blue-text hover:underline">
          {{ t('SETTINGS.TEMPLATES.LEARN_MORE_ABOUT_TEMPLATES') }}
        </a>
      </div>
      <Button
        icon="i-lucide-plus"
        blue
        :label="t('SETTINGS.TEMPLATES.ACTIONS.NEW_TEMPLATE')"
        @click="openAddPopup"
      />
    </div>

    <!-- Filters -->
    <div class="flex items-center gap-3 mb-6">
      <div class="relative w-48">
        <select
          v-model="selectedContent"
          class="w-full pl-3 pr-8 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 appearance-none"
        >
          <option value="Content">
            {{ t('SETTINGS.TEMPLATES.FILTERS.CONTENT') }}
          </option>
        </select>
      </div>

      <div class="relative w-48">
        <select
          v-model="selectedChannel"
          class="w-full pl-3 pr-8 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 appearance-none"
        >
          <option value="Channel">
            {{ t('SETTINGS.TEMPLATES.FILTERS.CHANNEL') }}
          </option>
        </select>
      </div>

      <div class="relative w-48">
        <select
          v-model="selectedLanguage"
          class="w-full pl-3 pr-8 py-2 text-sm border border-n-weak rounded-lg bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-blue-5 appearance-none"
        >
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          <option value="English (en-US)">English (en-US)</option>
        </select>
      </div>
    </div>

    <!-- Templates List -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('SETTINGS.TEMPLATES.LOADING')" />
    </div>

    <div
      v-else-if="!filteredTemplates.length"
      class="flex items-center justify-center py-12 text-n-slate-11"
    >
      {{ t('SETTINGS.TEMPLATES.LIST.404') }}
    </div>

    <div v-else class="flex-1 space-y-3">
      <div
        v-for="template in filteredTemplates"
        :key="template.id"
        class="flex items-center justify-between p-4 border border-n-weak rounded-lg bg-n-solid-2 hover:bg-n-solid-3 transition-colors"
      >
        <div class="flex items-center gap-4 flex-1">
          <!-- Template Icon -->
          <div
            class="flex items-center justify-center w-8 h-8 bg-n-solid-3 rounded"
          >
            <span
              :class="getTemplateIcon(template.category)"
              class="size-4 text-n-slate-11"
            />
          </div>

          <!-- Template Details -->
          <div class="flex-1">
            <div class="flex items-center gap-3 mb-1">
              <h3 class="text-sm font-medium text-n-slate-12">
                {{ template.name }}
              </h3>
              <span
                class="text-xs font-medium"
                :class="getStatusColor(template.status)"
              >
                {{
                  template.status.charAt(0).toUpperCase() +
                  template.status.slice(1)
                }}
              </span>
            </div>
            <div class="flex items-center gap-4 text-sm text-n-slate-11">
              <div class="flex items-center gap-1">
                <span
                  :class="getTemplateIcon(template.category)"
                  class="size-3"
                />
                <span>{{ formatCategory(template.category) }}</span>
              </div>
              <div class="flex items-center gap-1">
                <span class="i-lucide-globe size-3" />
                <span>{{ template.language.toUpperCase() }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-1">
          <Button
            v-tooltip.top="$t('SETTINGS.TEMPLATES.ACTIONS.EDIT')"
            icon="i-lucide-pen"
            slate
            xs
            faded
          />
          <Button
            v-tooltip.top="$t('SETTINGS.TEMPLATES.ACTIONS.DELETE')"
            icon="i-lucide-trash-2"
            xs
            ruby
            faded
            :is-loading="loading[template.id]"
            @click="openDeletePopup(template)"
          />
        </div>
      </div>
    </div>

    <!-- Pagination Info -->
    <div v-if="filteredTemplates.length" class="mt-6 text-sm text-n-slate-11">
      {{
        t('SETTINGS.TEMPLATES.LIST.PAGINATION', {
          start: 1,
          end: filteredTemplates.length,
          total: filteredTemplates.length,
        })
      }}
    </div>

    <!-- Add Template Modal -->
    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddTemplate @close="hideAddPopup" />
    </woot-modal>

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.TITLE')"
      :message="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.YES')"
      :reject-text="$t('SETTINGS.TEMPLATES.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
