<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import { TWILIO_CONTENT_TEMPLATE_TYPES } from 'shared/constants/messages';
import TemplatesAPI from 'dashboard/api/templates';

const props = defineProps({
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['onSelect']);

const { t } = useI18n();
const store = useStore();
const query = ref('');
const isRefreshing = ref(false);
const unifiedTemplates = ref([]);
const isLoadingUnified = ref(false);
const unifiedTemplatesError = ref(null);

const twilioTemplates = computed(() => {
  const inbox = store.getters['inboxes/getInbox'](props.inboxId);
  return inbox?.content_templates?.templates || [];
});

// Normalize channel type: 'Channel::AppleMessagesForBusiness' → 'apple_messages_for_business'
const normalizeChannelType = channelType => {
  if (!channelType) return null;

  return channelType
    .replace(/^Channel::/, '')
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
    .replace(/([a-z\d])([A-Z])/g, '$1_$2')
    .toLowerCase();
};

// Fetch unified templates from the API
const fetchUnifiedTemplates = async () => {
  if (!props.inboxId) return;

  isLoadingUnified.value = true;
  unifiedTemplatesError.value = null;

  try {
    const inbox = store.getters['inboxes/getInbox'](props.inboxId);
    if (!inbox) return;

    const channelType = normalizeChannelType(inbox.channel_type);

    const response = await TemplatesAPI.get({
      channel: channelType,
      status: 'active',
    });

    unifiedTemplates.value = response.data.templates || [];
  } catch (error) {
    unifiedTemplatesError.value = error.message;
    unifiedTemplates.value = [];
  } finally {
    isLoadingUnified.value = false;
  }
};

// Normalize Twilio templates to common format
const normalizedTwilioTemplates = computed(() => {
  return twilioTemplates.value.map(template => ({
    ...template,
    source: 'twilio',
    id: template.content_sid,
    displayName: template.friendly_name,
    displayBody: template.body,
    displayCategory: template.category || 'utility',
    displayLanguage: template.language,
    displayCreatedAt: template.created_at,
    displayType: getTemplateType(template),
  }));
});

// Normalize unified templates to common format
const normalizedUnifiedTemplates = computed(() => {
  return unifiedTemplates.value.map(template => ({
    ...template,
    source: 'unified',
    displayName: template.name,
    displayBody: template.content || template.description,
    displayCategory: template.category,
    displayLanguage: 'multi',
    displayCreatedAt: template.createdAt,
    displayType: getCategoryDisplayName(template.category),
  }));
});

// Merge and filter both template sources
const filteredTemplateMessages = computed(() => {
  const allTemplates = [
    ...normalizedTwilioTemplates.value.filter(t => t.status === 'approved'),
    ...normalizedUnifiedTemplates.value,
  ];

  if (!query.value) return allTemplates;

  const searchTerm = query.value.toLowerCase();
  return allTemplates.filter(
    template =>
      template.displayName?.toLowerCase().includes(searchTerm) ||
      (template.displayBody &&
        template.displayBody.toLowerCase().includes(searchTerm)) ||
      (template.description &&
        template.description.toLowerCase().includes(searchTerm))
  );
});

const getTemplateType = template => {
  if (template.template_type === TWILIO_CONTENT_TEMPLATE_TYPES.MEDIA) {
    return t('CONTENT_TEMPLATES.PICKER.TYPES.MEDIA');
  }
  if (template.template_type === TWILIO_CONTENT_TEMPLATE_TYPES.QUICK_REPLY) {
    return t('CONTENT_TEMPLATES.PICKER.TYPES.QUICK_REPLY');
  }
  return t('CONTENT_TEMPLATES.PICKER.TYPES.TEXT');
};

const getCategoryDisplayName = category => {
  const categoryMap = {
    scheduling: 'Scheduling',
    payment: 'Payment',
    support: 'Support',
    form: 'Form',
    general: 'General',
    marketing: 'Marketing',
    sales: 'Sales',
  };
  return categoryMap[category] || category || 'Template';
};

const refreshTemplates = async () => {
  isRefreshing.value = true;
  try {
    await Promise.all([
      store.dispatch('inboxes/syncTemplates', props.inboxId),
      fetchUnifiedTemplates(),
    ]);
    useAlert(t('CONTENT_TEMPLATES.PICKER.REFRESH_SUCCESS'));
  } catch (error) {
    useAlert(t('CONTENT_TEMPLATES.PICKER.REFRESH_ERROR'));
  } finally {
    isRefreshing.value = false;
  }
};

// Fetch unified templates on mount and when inbox changes
onMounted(() => {
  fetchUnifiedTemplates();
});

watch(
  () => props.inboxId,
  () => {
    fetchUnifiedTemplates();
  }
);
</script>

<template>
  <div class="w-full">
    <div class="flex gap-2 mb-2.5">
      <div
        class="flex flex-1 gap-1 items-center px-2.5 py-0 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 focus-within:outline-n-brand dark:focus-within:outline-n-brand"
      >
        <fluent-icon icon="search" class="text-n-slate-12" size="16" />
        <input
          v-model="query"
          type="search"
          :placeholder="t('CONTENT_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
          class="reset-base w-full h-9 bg-transparent text-n-slate-12 !text-sm !outline-0"
        />
      </div>
      <button
        :disabled="isRefreshing || isLoadingUnified"
        class="flex justify-center items-center w-9 h-9 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 disabled:opacity-50 disabled:cursor-not-allowed"
        :title="t('CONTENT_TEMPLATES.PICKER.REFRESH_BUTTON')"
        @click="refreshTemplates"
      >
        <Icon
          icon="i-lucide-refresh-ccw"
          class="text-n-slate-12 size-4"
          :class="{ 'animate-spin': isRefreshing || isLoadingUnified }"
        />
      </button>
    </div>
    <div
      class="bg-n-background outline-n-container outline outline-1 rounded-lg max-h-[18.75rem] overflow-y-auto p-2.5"
    >
      <div v-for="(template, i) in filteredTemplateMessages" :key="template.id">
        <button
          class="block p-2.5 w-full text-left rounded-lg cursor-pointer hover:bg-n-alpha-2 dark:hover:bg-n-solid-2"
          @click="() => emit('onSelect', template)"
        >
          <div>
            <div class="flex justify-between items-center mb-2.5">
              <div class="flex items-center gap-2">
                <p class="text-sm font-medium">
                  {{ template.displayName }}
                </p>
                <span
                  v-if="template.source === 'unified'"
                  class="inline-block px-1.5 py-0.5 text-xs leading-none rounded bg-n-brand/10 text-n-brand"
                  title="Unified Template"
                >
                  Template
                </span>
              </div>
              <div class="flex gap-2">
                <span
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
                >
                  {{ template.displayType }}
                </span>
                <span
                  v-if="template.displayLanguage"
                  class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
                >
                  {{
                    `${t('CONTENT_TEMPLATES.PICKER.LABELS.LANGUAGE')}: ${template.displayLanguage}`
                  }}
                </span>
              </div>
            </div>

            <!-- Body -->
            <div>
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('CONTENT_TEMPLATES.PICKER.BODY') }}
              </p>
              <p class="text-sm label-body line-clamp-2">
                {{
                  template.displayBody ||
                  t('CONTENT_TEMPLATES.PICKER.NO_CONTENT')
                }}
              </p>
            </div>

            <div class="flex justify-between items-center mt-3">
              <div>
                <p class="text-xs font-medium text-n-slate-11">
                  {{ t('CONTENT_TEMPLATES.PICKER.LABELS.CATEGORY') }}
                </p>
                <p class="text-sm">
                  {{ template.displayCategory || 'utility' }}
                </p>
              </div>
              <div
                v-if="
                  template.source === 'unified' &&
                  template.supportedChannels?.length
                "
                class="text-xs text-n-slate-11"
              >
                <span class="font-medium">{{ template.supportedChannels.length }} channels</span>
              </div>
              <div v-else class="text-xs text-n-slate-11">
                {{ new Date(template.displayCreatedAt).toLocaleDateString() }}
              </div>
            </div>
          </div>
        </button>
        <hr
          v-if="i != filteredTemplateMessages.length - 1"
          :key="`hr-${i}`"
          class="border-b border-solid border-n-weak my-2.5 mx-auto max-w-[95%]"
        />
      </div>
      <div v-if="!filteredTemplateMessages.length" class="py-8 text-center">
        <div v-if="isLoadingUnified || isRefreshing" class="space-y-2">
          <div class="animate-pulse flex justify-center">
            <Icon
              icon="i-lucide-loader-2"
              class="animate-spin text-n-slate-11 size-6"
            />
          </div>
          <p class="text-n-slate-11">Loading templates...</p>
        </div>
        <div
          v-else-if="
            query && (twilioTemplates.length || unifiedTemplates.length)
          "
        >
          <p>
            {{ t('CONTENT_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
            <strong>{{ query }}</strong>
          </p>
        </div>
        <div
          v-else-if="!twilioTemplates.length && !unifiedTemplates.length"
          class="space-y-4"
        >
          <p class="text-n-slate-11">
            {{ t('CONTENT_TEMPLATES.PICKER.NO_TEMPLATES_AVAILABLE') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.label-body {
  font-family: monospace;
}
</style>
