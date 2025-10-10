<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import TemplatesAPI from 'dashboard/api/templates';
import ParameterEditor from './components/ParameterEditor.vue';
import ContentBlockList from './components/ContentBlockList.vue';
import TemplatePreview from './components/TemplatePreview.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

// State
const loading = ref(false);
const saving = ref(false);
const templateId = computed(() => route.params.templateId);
const isEditMode = computed(() => !!templateId.value);

const template = ref({
  name: '',
  description: '',
  category: 'general',
  status: 'draft',
  supportedChannels: [],
  tags: [],
  useCases: [],
  parameters: {},
  contentBlocks: [],
  version: 1,
});

const errors = ref({});
const activeTab = ref('basic');
const newTag = ref('');
const newUseCase = ref('');

// Computed
const availableChannels = [
  {
    value: 'apple_messages_for_business',
    label: t('TEMPLATES.CHANNELS.APPLE_MESSAGES'),
  },
  { value: 'whatsapp', label: t('TEMPLATES.CHANNELS.WHATSAPP') },
  { value: 'web_widget', label: t('TEMPLATES.CHANNELS.WEB_WIDGET') },
  { value: 'sms', label: t('TEMPLATES.CHANNELS.SMS') },
  { value: 'email', label: t('TEMPLATES.CHANNELS.EMAIL') },
];

const categoryOptions = [
  { value: 'general', label: t('TEMPLATES.CATEGORIES.GENERAL') },
  { value: 'payment', label: t('TEMPLATES.CATEGORIES.PAYMENT') },
  { value: 'scheduling', label: t('TEMPLATES.CATEGORIES.SCHEDULING') },
  { value: 'support', label: t('TEMPLATES.CATEGORIES.SUPPORT') },
  { value: 'marketing', label: t('TEMPLATES.CATEGORIES.MARKETING') },
  { value: 'feedback', label: t('TEMPLATES.CATEGORIES.FEEDBACK') },
  { value: 'notification', label: t('TEMPLATES.CATEGORIES.NOTIFICATION') },
  { value: 'confirmation', label: t('TEMPLATES.CATEGORIES.CONFIRMATION') },
  { value: 'sales', label: t('TEMPLATES.CATEGORIES.SALES') },
];

const statusOptions = [
  { value: 'draft', label: t('TEMPLATES.STATUS.DRAFT') },
  { value: 'active', label: t('TEMPLATES.STATUS.ACTIVE') },
  { value: 'deprecated', label: t('TEMPLATES.STATUS.DEPRECATED') },
];

const tabs = computed(() => [
  {
    id: 'basic',
    label: t('TEMPLATES.BUILDER.BASIC_INFO'),
    icon: 'i-lucide-info',
  },
  {
    id: 'parameters',
    label: t('TEMPLATES.BUILDER.PARAMETERS.TITLE'),
    icon: 'i-lucide-braces',
  },
  {
    id: 'content',
    label: t('TEMPLATES.BUILDER.CONTENT_BLOCKS.TITLE'),
    icon: 'i-lucide-blocks',
  },
  {
    id: 'preview',
    label: t('TEMPLATES.BUILDER.PREVIEW.TITLE'),
    icon: 'i-lucide-eye',
  },
]);

// Methods
const fetchTemplate = async () => {
  if (!templateId.value) return;

  loading.value = true;
  try {
    const response = await TemplatesAPI.show(templateId.value);
    template.value = response.data;
  } catch (error) {
    useAlert(t('TEMPLATES.API.FETCH_ERROR'));
    router.push({ name: 'template_list' });
  } finally {
    loading.value = false;
  }
};

const validateTemplate = () => {
  errors.value = {};

  if (!template.value.name?.trim()) {
    errors.value.name = t('TEMPLATES.BUILDER.VALIDATION.NAME_REQUIRED');
  }

  if (!template.value.category) {
    errors.value.category = t('TEMPLATES.BUILDER.VALIDATION.CATEGORY_REQUIRED');
  }

  if (template.value.supportedChannels.length === 0) {
    errors.value.channels = t('TEMPLATES.BUILDER.VALIDATION.CHANNEL_REQUIRED');
  }

  if (template.value.contentBlocks.length === 0) {
    errors.value.content = t('TEMPLATES.BUILDER.VALIDATION.CONTENT_REQUIRED');
  }

  return Object.keys(errors.value).length === 0;
};

const saveTemplate = async () => {
  if (!validateTemplate()) {
    useAlert(Object.values(errors.value)[0]);
    return;
  }

  saving.value = true;
  try {
    let response;
    if (isEditMode.value) {
      response = await TemplatesAPI.update(templateId.value, template.value);
      useAlert(t('TEMPLATES.API.UPDATE_SUCCESS'));
    } else {
      response = await TemplatesAPI.create(template.value);
      useAlert(t('TEMPLATES.API.CREATE_SUCCESS'));
    }

    router.push({ name: 'templates_list' });
  } catch (error) {
    const message = isEditMode.value
      ? t('TEMPLATES.API.UPDATE_ERROR')
      : t('TEMPLATES.API.CREATE_ERROR');
    useAlert(message);
  } finally {
    saving.value = false;
  }
};

const cancel = () => {
  router.push({ name: 'templates_list' });
};

const toggleChannel = channel => {
  const index = template.value.supportedChannels.indexOf(channel);
  if (index === -1) {
    template.value.supportedChannels.push(channel);
  } else {
    template.value.supportedChannels.splice(index, 1);
  }
};

const addTag = () => {
  const tag = newTag.value.trim();
  if (tag && !template.value.tags.includes(tag)) {
    template.value.tags.push(tag);
    newTag.value = '';
  }
};

const removeTag = index => {
  template.value.tags.splice(index, 1);
};

const addUseCase = () => {
  const useCase = newUseCase.value.trim();
  if (useCase && !template.value.useCases.includes(useCase)) {
    template.value.useCases.push(useCase);
    newUseCase.value = '';
  }
};

const removeUseCase = index => {
  template.value.useCases.splice(index, 1);
};

const updateParameters = parameters => {
  template.value.parameters = parameters;
};

const updateContentBlocks = blocks => {
  template.value.contentBlocks = blocks;
};

onMounted(() => {
  if (isEditMode.value) {
    fetchTemplate();
  }
});
</script>

<template>
  <div class="flex flex-col h-full bg-n-slate-1">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-4 bg-white border-b border-n-weak"
    >
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{
            isEditMode
              ? t('TEMPLATES.BUILDER.TITLE_EDIT')
              : t('TEMPLATES.BUILDER.TITLE_NEW')
          }}
        </h1>
        <p v-if="template.name" class="text-sm text-n-slate-11 mt-1">
          {{ template.name }}
        </p>
      </div>
      <div class="flex gap-3">
        <Button variant="outline" slate @click="cancel">
          {{ t('TEMPLATES.BUILDER.CANCEL') }}
        </Button>
        <Button
          icon="i-lucide-save"
          :label="
            saving ? t('TEMPLATES.BUILDER.SAVING') : t('TEMPLATES.BUILDER.SAVE')
          "
          :disabled="saving"
          @click="saveTemplate"
        />
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center flex-1">
      <woot-loading-state :message="t('TEMPLATES.LOADING')" />
    </div>

    <!-- Main Content -->
    <div v-else class="flex flex-1 overflow-hidden">
      <!-- Tabs Sidebar -->
      <div class="w-64 bg-white border-r border-n-weak overflow-y-auto">
        <nav class="p-4 space-y-1">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            class="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-colors"
            :class="[
              activeTab === tab.id
                ? 'bg-n-blue-2 text-n-blue-11 font-medium'
                : 'text-n-slate-11 hover:bg-n-slate-2',
            ]"
            @click="activeTab = tab.id"
          >
            <i class="text-lg" :class="[tab.icon]" />
            <span>{{ tab.label }}</span>
          </button>
        </nav>
      </div>

      <!-- Content Area -->
      <div class="flex-1 overflow-y-auto p-6">
        <!-- Basic Information Tab -->
        <div v-show="activeTab === 'basic'" class="max-w-3xl mx-auto space-y-6">
          <!-- Name -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.NAME.LABEL') }}
              <span class="text-n-red-11">*</span>
            </label>
            <input
              v-model="template.name"
              type="text"
              :placeholder="t('TEMPLATES.BUILDER.NAME.PLACEHOLDER')"
              class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2"
              :class="[
                errors.name
                  ? 'border-n-red-7 focus:ring-n-red-7'
                  : 'border-n-slate-7 focus:ring-n-blue-7',
              ]"
            />
            <p v-if="errors.name" class="mt-1 text-sm text-n-red-11">
              {{ errors.name }}
            </p>
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.DESCRIPTION.LABEL') }}
            </label>
            <textarea
              v-model="template.description"
              rows="3"
              :placeholder="t('TEMPLATES.BUILDER.DESCRIPTION.PLACEHOLDER')"
              class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
            />
          </div>

          <!-- Category and Status -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('TEMPLATES.BUILDER.CATEGORY.LABEL') }}
                <span class="text-n-red-11">*</span>
              </label>
              <select
                v-model="template.category"
                class="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2"
                :class="[
                  errors.category
                    ? 'border-n-red-7 focus:ring-n-red-7'
                    : 'border-n-slate-7 focus:ring-n-blue-7',
                ]"
              >
                <option value="">
                  {{ t('TEMPLATES.BUILDER.CATEGORY.PLACEHOLDER') }}
                </option>
                <option
                  v-for="option in categoryOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.category" class="mt-1 text-sm text-n-red-11">
                {{ errors.category }}
              </p>
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2">
                {{ t('TEMPLATES.BUILDER.STATUS.LABEL') }}
              </label>
              <select
                v-model="template.status"
                class="w-full px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
              >
                <option
                  v-for="option in statusOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>
          </div>

          <!-- Supported Channels -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.CHANNELS.LABEL') }}
              <span class="text-n-red-11">*</span>
            </label>
            <p class="text-sm text-n-slate-11 mb-3">
              {{ t('TEMPLATES.BUILDER.CHANNELS.DESCRIPTION') }}
            </p>
            <div class="grid grid-cols-2 gap-3">
              <button
                v-for="channel in availableChannels"
                :key="channel.value"
                class="flex items-center gap-3 px-4 py-3 border-2 rounded-lg transition-all"
                :class="[
                  template.supportedChannels.includes(channel.value)
                    ? 'border-n-blue-7 bg-n-blue-2 text-n-blue-11'
                    : 'border-n-slate-7 hover:border-n-slate-8',
                ]"
                @click="toggleChannel(channel.value)"
              >
                <div
                  class="w-5 h-5 rounded border-2 flex items-center justify-center"
                  :class="[
                    template.supportedChannels.includes(channel.value)
                      ? 'border-n-blue-9 bg-n-blue-9'
                      : 'border-n-slate-7',
                  ]"
                >
                  <i
                    v-if="template.supportedChannels.includes(channel.value)"
                    class="i-lucide-check text-white text-sm"
                  />
                </div>
                <span class="text-sm font-medium">{{ channel.label }}</span>
              </button>
            </div>
            <p v-if="errors.channels" class="mt-2 text-sm text-n-red-11">
              {{ errors.channels }}
            </p>
          </div>

          <!-- Tags -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.TAGS.LABEL') }}
            </label>
            <p class="text-sm text-n-slate-11 mb-3">
              {{ t('TEMPLATES.BUILDER.TAGS.DESCRIPTION') }}
            </p>
            <div class="flex gap-2 mb-3">
              <input
                v-model="newTag"
                type="text"
                :placeholder="t('TEMPLATES.BUILDER.TAGS.PLACEHOLDER')"
                class="flex-1 px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                @keyup.enter="addTag"
              />
              <Button icon="i-lucide-plus" @click="addTag" />
            </div>
            <div v-if="template.tags.length > 0" class="flex flex-wrap gap-2">
              <span
                v-for="(tag, index) in template.tags"
                :key="index"
                class="inline-flex items-center gap-2 px-3 py-1 bg-n-slate-3 text-n-slate-12 rounded-full text-sm"
              >
                {{ tag }}
                <button class="hover:text-n-red-11" @click="removeTag(index)">
                  <i class="i-lucide-x text-xs" />
                </button>
              </span>
            </div>
          </div>

          <!-- Use Cases -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-2">
              {{ t('TEMPLATES.BUILDER.USE_CASES.LABEL') }}
            </label>
            <p class="text-sm text-n-slate-11 mb-3">
              {{ t('TEMPLATES.BUILDER.USE_CASES.DESCRIPTION') }}
            </p>
            <div class="flex gap-2 mb-3">
              <input
                v-model="newUseCase"
                type="text"
                :placeholder="t('TEMPLATES.BUILDER.USE_CASES.PLACEHOLDER')"
                class="flex-1 px-4 py-2 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7"
                @keyup.enter="addUseCase"
              />
              <Button icon="i-lucide-plus" @click="addUseCase" />
            </div>
            <div
              v-if="template.useCases.length > 0"
              class="flex flex-wrap gap-2"
            >
              <span
                v-for="(useCase, index) in template.useCases"
                :key="index"
                class="inline-flex items-center gap-2 px-3 py-1 bg-n-slate-3 text-n-slate-12 rounded-full text-sm"
              >
                {{ useCase }}
                <button
                  class="hover:text-n-red-11"
                  @click="removeUseCase(index)"
                >
                  <i class="i-lucide-x text-xs" />
                </button>
              </span>
            </div>
          </div>
        </div>

        <!-- Parameters Tab -->
        <div v-show="activeTab === 'parameters'" class="max-w-4xl mx-auto">
          <ParameterEditor
            :parameters="template.parameters"
            @update:parameters="updateParameters"
          />
        </div>

        <!-- Content Blocks Tab -->
        <div v-show="activeTab === 'content'" class="max-w-5xl mx-auto">
          <ContentBlockList
            :blocks="template.contentBlocks"
            :parameters="template.parameters"
            @update:blocks="updateContentBlocks"
          />
        </div>

        <!-- Preview Tab -->
        <div v-show="activeTab === 'preview'" class="max-w-6xl mx-auto">
          <TemplatePreview :template="template" />
        </div>
      </div>
    </div>
  </div>
</template>
