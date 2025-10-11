<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TemplatesAPI from 'dashboard/api/templates';
import AppleLogo from 'dashboard/assets/images/apple-logo.png';

const { t } = useI18n();
const router = useRouter();

// State
const templates = ref([]);
const loading = ref(false);
const searchQuery = ref('');
const selectedCategory = ref('all');
const selectedChannel = ref('all');
const selectedTags = ref([]);
const showDeleteConfirmation = ref(false);
const templateToDelete = ref(null);

// Computed
const filteredTemplates = computed(() => {
  let filtered = templates.value;

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      template =>
        template.name.toLowerCase().includes(query) ||
        template.description?.toLowerCase().includes(query) ||
        template.category?.toLowerCase().includes(query)
    );
  }

  if (selectedCategory.value !== 'all') {
    filtered = filtered.filter(
      template => template.category === selectedCategory.value
    );
  }

  if (selectedChannel.value !== 'all') {
    filtered = filtered.filter(template =>
      template.supportedChannels?.includes(selectedChannel.value)
    );
  }

  if (selectedTags.value.length > 0) {
    filtered = filtered.filter(template =>
      selectedTags.value.some(tag => template.tags?.includes(tag))
    );
  }

  return filtered;
});

const categories = computed(() => {
  const cats = new Set(
    templates.value.map(template => template.category).filter(Boolean)
  );
  return ['all', ...Array.from(cats)];
});

const availableChannels = computed(() => [
  { value: 'all', label: t('TEMPLATES.CHANNELS.ALL') },
  {
    value: 'apple_messages_for_business',
    label: t('TEMPLATES.CHANNELS.APPLE_MESSAGES'),
  },
  { value: 'whatsapp', label: t('TEMPLATES.CHANNELS.WHATSAPP') },
  { value: 'web_widget', label: t('TEMPLATES.CHANNELS.WEB_WIDGET') },
  { value: 'sms', label: t('TEMPLATES.CHANNELS.SMS') },
  { value: 'email', label: t('TEMPLATES.CHANNELS.EMAIL') },
]);

const allTags = computed(() => {
  const tags = new Set();
  templates.value.forEach(template => {
    if (template.tags) {
      template.tags.forEach(tag => tags.add(tag));
    }
  });
  return Array.from(tags);
});

// Methods
const fetchTemplates = async () => {
  loading.value = true;
  try {
    const response = await TemplatesAPI.get();
    // Extract templates array from paginated response
    templates.value = response.data.templates || response.data || [];
  } catch (error) {
    useAlert(t('TEMPLATES.API.FETCH_ERROR'));
  } finally {
    loading.value = false;
  }
};

const navigateToNewTemplate = () => {
  router.push({ name: 'template_new' });
};

const navigateToEdit = templateId => {
  router.push({ name: 'template_edit', params: { templateId } });
};

const openDeleteConfirmation = template => {
  templateToDelete.value = template;
  showDeleteConfirmation.value = true;
};

const closeDeleteConfirmation = () => {
  templateToDelete.value = null;
  showDeleteConfirmation.value = false;
};

const confirmDelete = async () => {
  if (!templateToDelete.value) return;

  try {
    await TemplatesAPI.delete(templateToDelete.value.id);
    useAlert(t('TEMPLATES.API.DELETE_SUCCESS'));
    await fetchTemplates();
  } catch (error) {
    useAlert(t('TEMPLATES.API.DELETE_ERROR'));
  } finally {
    closeDeleteConfirmation();
  }
};

const duplicateTemplate = async template => {
  try {
    const duplicatedData = {
      ...template,
      name: `${template.name} (Copy)`,
      id: undefined,
    };
    const response = await TemplatesAPI.create(duplicatedData);
    useAlert(t('TEMPLATES.API.DUPLICATE_SUCCESS'));
    await fetchTemplates();
    navigateToEdit(response.data.id);
  } catch (error) {
    useAlert(t('TEMPLATES.API.DUPLICATE_ERROR'));
  }
};

const getCategoryLabel = category => {
  if (!category) return t('TEMPLATES.CATEGORIES.UNCATEGORIZED');

  const lowerCategory = category.toLowerCase();
  if (lowerCategory === 'all') return t('TEMPLATES.CATEGORIES.ALL');
  if (lowerCategory === 'general') return t('TEMPLATES.CATEGORIES.GENERAL');
  if (lowerCategory === 'marketing') return t('TEMPLATES.CATEGORIES.MARKETING');
  if (lowerCategory === 'support') return t('TEMPLATES.CATEGORIES.SUPPORT');
  if (lowerCategory === 'sales') return t('TEMPLATES.CATEGORIES.SALES');
  if (lowerCategory === 'onboarding')
    return t('TEMPLATES.CATEGORIES.ONBOARDING');

  return category;
};

const getChannelIcon = channel => {
  const icons = {
    apple_messages_for_business: null, // Will use Apple logo image
    whatsapp: 'whatsapp',
    web_widget: 'globe',
    sms: 'message-square',
    email: 'mail',
  };
  return icons[channel] || 'message-circle';
};

const isAppleMessagesChannel = channel => {
  return channel === 'apple_messages_for_business';
};

const getStatusBadgeClass = status => {
  const classes = {
    active:
      'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 font-semibold',
    draft:
      'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200 font-semibold',
    deprecated:
      'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200 font-semibold',
  };
  return classes[status] || 'bg-n-slate-3 text-n-slate-11';
};

const getStatusLabel = status => {
  if (!status) return '';

  const lowerStatus = status.toLowerCase();
  if (lowerStatus === 'active') return t('TEMPLATES.STATUS.ACTIVE');
  if (lowerStatus === 'draft') return t('TEMPLATES.STATUS.DRAFT');
  if (lowerStatus === 'deprecated') return t('TEMPLATES.STATUS.DEPRECATED');

  return status;
};

const toggleTag = tag => {
  const index = selectedTags.value.indexOf(tag);
  if (index === -1) {
    selectedTags.value.push(tag);
  } else {
    selectedTags.value.splice(index, 1);
  }
};

const clearFilters = () => {
  searchQuery.value = '';
  selectedCategory.value = 'all';
  selectedChannel.value = 'all';
  selectedTags.value = [];
};

onMounted(() => {
  fetchTemplates();
});
</script>

<template>
  <div class="flex flex-col h-full">
    <BaseSettingsHeader
      :title="t('TEMPLATES.HEADER')"
      :description="t('TEMPLATES.DESCRIPTION')"
      :link-text="t('TEMPLATES.LEARN_MORE')"
      feature-name="templates"
    >
      <template #actions>
        <Button
          icon="i-lucide-plus"
          :label="t('TEMPLATES.HEADER_BTN_TXT')"
          @click="navigateToNewTemplate"
        />
      </template>
    </BaseSettingsHeader>

    <!-- Filters Section -->
    <div class="flex flex-col gap-4 p-4 bg-white border-b border-n-weak">
      <!-- Search Bar -->
      <div class="flex gap-3">
        <div class="flex-1">
          <input
            v-model="searchQuery"
            type="text"
            :placeholder="t('TEMPLATES.SEARCH_PLACEHOLDER')"
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
        </div>
        <Button
          v-if="
            searchQuery ||
            selectedCategory !== 'all' ||
            selectedChannel !== 'all' ||
            selectedTags.length > 0
          "
          slate
          variant="outline"
          icon="i-lucide-x"
          @click="clearFilters"
        >
          {{ t('TEMPLATES.CLEAR_FILTERS') }}
        </Button>
      </div>

      <!-- Category and Channel Filters -->
      <div class="flex gap-3">
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('TEMPLATES.FILTER_BY_CATEGORY') }}
          </label>
          <select
            v-model="selectedCategory"
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option
              v-for="category in categories"
              :key="category"
              :value="category"
            >
              {{ getCategoryLabel(category) }}
            </option>
          </select>
        </div>

        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ t('TEMPLATES.FILTER_BY_CHANNEL') }}
          </label>
          <select
            v-model="selectedChannel"
            class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          >
            <option
              v-for="channel in availableChannels"
              :key="channel.value"
              :value="channel.value"
            >
              {{ channel.label }}
            </option>
          </select>
        </div>
      </div>

      <!-- Tag Filter -->
      <div v-if="allTags.length > 0">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ t('TEMPLATES.FILTER_BY_TAGS') }}
        </label>
        <div class="flex flex-wrap gap-2">
          <button
            v-for="tag in allTags"
            :key="tag"
            class="px-3 py-2 text-sm rounded-lg border-2 transition-colors font-medium"
            :class="[
              selectedTags.includes(tag)
                ? 'bg-n-blue-9 text-white border-n-blue-9'
                : 'bg-white text-n-slate-11 border-n-slate-7 hover:border-n-blue-7',
            ]"
            @click="toggleTag(tag)"
          >
            {{ tag }}
          </button>
        </div>
      </div>
    </div>

    <!-- Templates List -->
    <div class="flex-1 overflow-auto p-4">
      <!-- Loading State -->
      <div v-if="loading" class="flex items-center justify-center h-64">
        <woot-loading-state :message="t('TEMPLATES.LOADING')" />
      </div>

      <!-- Empty State -->
      <div
        v-else-if="filteredTemplates.length === 0 && !searchQuery"
        class="flex flex-col items-center justify-center h-64"
      >
        <i class="i-lucide-file-text text-6xl text-n-slate-8 mb-4" />
        <div class="text-n-slate-11 text-lg font-medium mb-2">
          {{ t('TEMPLATES.EMPTY_STATE.TITLE') }}
        </div>
        <div class="text-n-slate-10 text-sm mb-6">
          {{ t('TEMPLATES.EMPTY_STATE.MESSAGE') }}
        </div>
        <Button
          icon="i-lucide-plus"
          :label="t('TEMPLATES.CREATE_FIRST_TEMPLATE')"
          @click="navigateToNewTemplate"
        />
      </div>

      <!-- No Results -->
      <div
        v-else-if="filteredTemplates.length === 0"
        class="flex flex-col items-center justify-center h-64"
      >
        <i class="i-lucide-search-x text-6xl text-n-slate-8 mb-4" />
        <div class="text-n-slate-11">{{ t('TEMPLATES.NO_RESULTS') }}</div>
      </div>

      <!-- Templates Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="template in filteredTemplates"
          :key="template.id"
          class="border border-n-slate-7 rounded-lg p-5 hover:shadow-lg hover:border-n-blue-7 transition-all bg-white"
        >
          <!-- Header -->
          <div class="flex items-start justify-between mb-3">
            <div class="flex-1">
              <h3 class="text-base font-semibold text-n-slate-12 mb-2">
                {{ template.name }}
              </h3>
              <div class="flex items-center gap-2">
                <span
                  class="px-2 py-1 text-xs rounded-full"
                  :class="getStatusBadgeClass(template.status)"
                >
                  {{ getStatusLabel(template.status) }}
                </span>
                <span
                  v-if="template.category"
                  class="px-2 py-1 text-xs rounded-full bg-n-slate-3 text-n-slate-11 font-medium"
                >
                  {{ getCategoryLabel(template.category) }}
                </span>
              </div>
            </div>
          </div>

          <!-- Description -->
          <p
            v-if="template.description"
            class="text-sm text-n-slate-11 mb-3 line-clamp-2"
          >
            {{ template.description }}
          </p>

          <!-- Supported Channels -->
          <div class="flex items-center gap-2 mb-3">
            <span class="text-xs font-medium text-n-slate-10 uppercase">
              {{ t('TEMPLATES.SUPPORTED_CHANNELS') }}
            </span>
            <div class="flex gap-2">
              <span
                v-for="channel in template.supportedChannels"
                :key="channel"
                class="w-6 h-6 flex items-center justify-center bg-n-slate-2 rounded"
                :title="channel"
              >
                <img
                  v-if="isAppleMessagesChannel(channel)"
                  :src="AppleLogo"
                  alt="Apple Messages"
                  class="w-4 h-4"
                />
                <i
                  v-else
                  :class="`i-lucide-${getChannelIcon(channel)}`"
                  class="w-4 h-4 text-n-slate-11"
                />
              </span>
            </div>
          </div>

          <!-- Tags -->
          <div v-if="template.tags && template.tags.length > 0" class="mb-3">
            <div class="flex flex-wrap gap-1">
              <span
                v-for="tag in template.tags.slice(0, 3)"
                :key="tag"
                class="px-2 py-1 text-xs rounded bg-n-slate-2 text-n-slate-11"
              >
                {{ tag }}
              </span>
              <span
                v-if="template.tags.length > 3"
                class="px-2 py-1 text-xs rounded bg-n-slate-2 text-n-slate-11 font-medium"
              >
                {{
                  t('TEMPLATES.TAGS_MORE', { count: template.tags.length - 3 })
                }}
              </span>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-2 pt-3 border-t border-n-weak">
            <Button
              icon="i-lucide-pen"
              slate
              xs
              faded
              @click="navigateToEdit(template.id)"
            >
              {{ t('TEMPLATES.ACTIONS.EDIT') }}
            </Button>
            <Button
              icon="i-lucide-copy"
              slate
              xs
              faded
              @click="duplicateTemplate(template)"
            >
              {{ t('TEMPLATES.ACTIONS.DUPLICATE') }}
            </Button>
            <Button
              icon="i-lucide-trash-2"
              ruby
              xs
              faded
              @click="openDeleteConfirmation(template)"
            >
              {{ t('TEMPLATES.ACTIONS.DELETE') }}
            </Button>
          </div>

          <!-- Metadata -->
          <div
            class="flex items-center justify-between mt-3 pt-3 border-t border-n-weak"
          >
            <span class="text-xs text-n-slate-10">
              {{
                t('TEMPLATES.VERSION_LABEL', { version: template.version || 1 })
              }}
            </span>
            <span class="text-xs text-n-slate-10">
              {{
                t('TEMPLATES.UPDATED_LABEL', {
                  date: new Date(template.updatedAt).toLocaleDateString(),
                })
              }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-if="showDeleteConfirmation"
      :show="showDeleteConfirmation"
      :on-close="closeDeleteConfirmation"
      :on-confirm="confirmDelete"
      :title="t('TEMPLATES.DELETE_MODAL.TITLE')"
      :message="
        t('TEMPLATES.DELETE_MODAL.MESSAGE', { name: templateToDelete?.name })
      "
      :confirm-text="t('TEMPLATES.DELETE_MODAL.CONFIRM')"
      :reject-text="t('TEMPLATES.DELETE_MODAL.CANCEL')"
    />
  </div>
</template>
