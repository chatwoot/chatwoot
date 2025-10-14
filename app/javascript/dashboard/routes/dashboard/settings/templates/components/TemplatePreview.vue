<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import TemplatesAPI from 'dashboard/api/templates';
import { useAlert } from 'dashboard/composables';
import AppleLogo from 'dashboard/assets/images/apple-logo.png';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

// State
const selectedChannel = ref('apple_messages_for_business');
const testParameters = ref({});
const renderedPreview = ref(null);
const loading = ref(false);

// Computed
const availableChannels = computed(() => {
  return props.template.supportedChannels.map(channel => ({
    value: channel,
    label: getChannelLabel(channel),
    icon: getChannelIcon(channel),
  }));
});

const parameterInputs = computed(() => {
  return Object.entries(props.template.parameters || {}).map(
    ([name, config]) => ({
      name,
      ...config,
    })
  );
});

// Methods
const getChannelLabel = channel => {
  const labels = {
    apple_messages_for_business: t('TEMPLATES.CHANNELS.APPLE_MESSAGES'),
    whatsapp: t('TEMPLATES.CHANNELS.WHATSAPP'),
    web_widget: t('TEMPLATES.CHANNELS.WEB_WIDGET'),
    sms: t('TEMPLATES.CHANNELS.SMS'),
    email: t('TEMPLATES.CHANNELS.EMAIL'),
  };
  return labels[channel] || channel;
};

const getChannelIcon = channel => {
  const icons = {
    apple_messages_for_business: null, // Will use Apple logo image
    whatsapp: 'i-lucide-message-circle',
    web_widget: 'i-lucide-globe',
    sms: 'i-lucide-message-square',
    email: 'i-lucide-mail',
  };
  return icons[channel] || 'i-lucide-message-circle';
};

const isAppleMessagesChannel = channel => {
  return channel === 'apple_messages_for_business';
};

const renderPreview = async () => {
  if (!props.template.id) {
    useAlert('Please save the template first to see preview');
    return;
  }

  loading.value = true;
  try {
    const response = await TemplatesAPI.render(
      props.template.id,
      testParameters.value,
      selectedChannel.value
    );
    renderedPreview.value = response.data;
  } catch (error) {
    useAlert(t('TEMPLATES.API.TEST_ERROR'));
    renderedPreview.value = null;
  } finally {
    loading.value = false;
  }
};

const generateMockPreview = () => {
  // Generate a simple preview without API call for unsaved templates
  const preview = {
    contentType: 'preview',
    blocks: props.template.contentBlocks.map(block => {
      const processedProps = processProperties(block.properties);
      return {
        type: block.blockType,
        properties: processedProps,
      };
    }),
  };
  return preview;
};

const processProperties = properties => {
  const processed = { ...properties };

  // Replace parameter placeholders with test values
  Object.entries(testParameters.value).forEach(([key, value]) => {
    const placeholder = new RegExp(`{{${key}}}`, 'g');

    Object.keys(processed).forEach(propKey => {
      if (typeof processed[propKey] === 'string') {
        processed[propKey] = processed[propKey].replace(placeholder, value);
      }
    });
  });

  return processed;
};

// Helper to get image data from identifier
const getImageData = (imageIdentifier, blockProperties) => {
  if (!imageIdentifier) return null;
  const images = blockProperties.images || [];
  const image = images.find(img => img.identifier === imageIdentifier);
  return image?.data || null;
};

// Initialize test parameters with defaults or examples
watch(
  () => props.template.parameters,
  newParams => {
    if (!newParams) return;

    Object.entries(newParams).forEach(([name, config]) => {
      if (!testParameters.value[name]) {
        testParameters.value[name] = config.default || config.example || '';
      }
    });
  },
  { immediate: true, deep: true }
);

// Auto-render when channel changes
watch(selectedChannel, () => {
  if (props.template.id) {
    renderPreview();
  }
});
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-lg font-semibold text-n-slate-12">
        {{ t('TEMPLATES.BUILDER.PREVIEW.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ t('TEMPLATES.BUILDER.PREVIEW.DESCRIPTION') }}
      </p>
    </div>

    <!-- Channel Selector -->
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-3">
        {{ t('TEMPLATES.BUILDER.PREVIEW.SELECT_CHANNEL') }}
      </label>
      <div class="grid grid-cols-3 gap-3">
        <button
          v-for="channel in availableChannels"
          :key="channel.value"
          class="flex items-center gap-3 px-4 py-3 border-2 rounded-lg transition-all"
          :class="[
            selectedChannel === channel.value
              ? 'border-n-blue-7 bg-n-blue-2 text-n-blue-11'
              : 'border-n-slate-7 hover:border-n-slate-8',
          ]"
          @click="selectedChannel = channel.value"
        >
          <img
            v-if="isAppleMessagesChannel(channel.value)"
            :src="AppleLogo"
            alt="Apple Messages"
            class="w-5 h-5"
          />
          <i v-else class="text-xl" :class="[channel.icon]" />
          <span class="text-sm font-medium">{{ channel.label }}</span>
        </button>
      </div>
    </div>

    <!-- Test Parameters -->
    <div v-if="parameterInputs.length > 0">
      <div class="flex items-center justify-between mb-3">
        <label class="block text-sm font-medium text-n-slate-12">
          {{ t('TEMPLATES.BUILDER.PREVIEW.TEST_PARAMETERS') }}
        </label>
        <Button
          v-if="template.id"
          :loading="loading"
          icon="i-lucide-eye"
          @click="renderPreview"
        >
          {{ t('TEMPLATES.BUILDER.PREVIEW.DESCRIPTION') }}
        </Button>
      </div>

      <div class="grid grid-cols-2 gap-4 p-4 bg-n-slate-2 rounded-lg">
        <div v-for="param in parameterInputs" :key="param.name">
          <label class="block text-xs font-medium text-n-slate-11 mb-1">
            {{ param.name }}
            <span v-if="param.required" class="text-n-red-11">*</span>
          </label>
          <input
            v-model="testParameters[param.name]"
            :type="param.type === 'number' ? 'number' : 'text'"
            :placeholder="
              param.example || param.default || `Enter ${param.name}`
            "
            class="w-full px-3 py-2 text-sm border border-n-slate-7 bg-white rounded focus:outline-none focus:ring-2 focus:ring-n-blue-7"
          />
          <p v-if="param.description" class="text-xs text-n-slate-10 mt-1">
            {{ param.description }}
          </p>
        </div>
      </div>
    </div>

    <!-- Preview Area -->
    <div class="border-2 border-n-slate-7 rounded-lg overflow-hidden">
      <!-- Preview Header -->
      <div class="bg-n-slate-3 px-4 py-3 border-b border-n-slate-7">
        <div class="flex items-center gap-2">
          <img
            v-if="isAppleMessagesChannel(selectedChannel)"
            :src="AppleLogo"
            alt="Apple Messages"
            class="w-4 h-4"
          />
          <i
            v-else
            class="text-n-slate-11"
            :class="[getChannelIcon(selectedChannel)]"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{ getChannelLabel(selectedChannel) }} Preview
          </span>
        </div>
      </div>

      <!-- Preview Content -->
      <div class="bg-white p-6 min-h-96">
        <div v-if="loading" class="flex items-center justify-center h-64">
          <div class="text-n-slate-10">Loading preview...</div>
        </div>

        <div v-else-if="!template.id" class="text-center py-12">
          <i class="i-lucide-save text-4xl text-n-slate-8 mb-3" />
          <p class="text-sm text-n-slate-11">
            Save the template to see a detailed preview
          </p>
        </div>

        <div v-else-if="!renderedPreview" class="text-center py-12">
          <i class="i-lucide-eye text-4xl text-n-slate-8 mb-3" />
          <p class="text-sm text-n-slate-11 mb-4">
            {{ t('TEMPLATES.BUILDER.PREVIEW.ENTER_PARAMETERS') }}
          </p>
          <Button icon="i-lucide-play" @click="renderPreview">
            Generate Preview
          </Button>
        </div>

        <!-- Rendered Preview -->
        <div v-else class="space-y-4">
          <!-- Content Blocks Preview -->
          <div
            v-for="(block, index) in template.contentBlocks"
            :key="index"
            class="p-4 border border-n-slate-7 rounded-lg bg-n-slate-1"
          >
            <div class="flex items-center gap-2 mb-2">
              <img
                v-if="isAppleMessagesChannel(selectedChannel)"
                :src="AppleLogo"
                alt="Apple Messages"
                class="w-3.5 h-3.5"
              />
              <i
                v-else
                class="text-n-slate-10 text-sm"
                :class="[getChannelIcon(selectedChannel)]"
              />
              <span class="text-xs font-medium text-n-slate-11 uppercase">
                {{ block.blockType.replace('_', ' ') }}
              </span>
            </div>

            <!-- Text Block -->
            <div
              v-if="block.blockType === 'text'"
              class="text-sm text-n-slate-12"
            >
              {{ processProperties(block.properties).content }}
            </div>

            <!-- Quick Reply Block -->
            <div
              v-else-if="block.blockType === 'quick_reply'"
              class="space-y-3"
            >
              <div
                v-if="block.properties.summary_text"
                class="text-sm text-n-slate-11"
              >
                {{ processProperties(block.properties).summary_text }}
              </div>
              <div
                v-if="block.properties.received_title"
                class="font-medium text-n-slate-12"
              >
                {{ processProperties(block.properties).received_title }}
              </div>
              <div
                v-if="block.properties.received_subtitle"
                class="text-sm text-n-slate-11"
              >
                {{ processProperties(block.properties).received_subtitle }}
              </div>
              <div class="flex gap-2 flex-wrap mt-3">
                <button
                  v-for="(item, i) in block.properties.items || block.properties.replies || []"
                  :key="i"
                  disabled
                  class="px-4 py-2 bg-n-blue-2 border border-n-blue-7 text-n-blue-11 rounded-full text-sm font-medium hover:bg-n-blue-3 transition-colors cursor-pointer"
                >
                  {{ item.title }}
                </button>
              </div>
            </div>

            <!-- Time Picker Block -->
            <div
              v-else-if="block.blockType === 'time_picker'"
              class="space-y-2"
            >
              <div class="font-medium text-n-slate-12">
                {{ processProperties(block.properties).title }}
              </div>
              <div class="text-sm text-n-slate-11">
                {{ processProperties(block.properties).description }}
              </div>
              <div class="flex gap-2 flex-wrap">
                <div
                  v-for="i in 3"
                  :key="i"
                  class="px-3 py-2 bg-n-blue-2 text-n-blue-11 rounded text-sm"
                >
                  <i class="i-lucide-clock mr-1" />
                  Time Slot {{ i }}
                </div>
              </div>
            </div>

            <!-- List Picker Block -->
            <div
              v-else-if="block.blockType === 'list_picker'"
              class="space-y-2"
            >
              <div
                v-if="block.properties.received_title"
                class="font-medium text-n-slate-12"
              >
                {{ processProperties(block.properties).received_title }}
              </div>
              <div
                v-if="block.properties.received_subtitle"
                class="text-sm text-n-slate-11"
              >
                {{ processProperties(block.properties).received_subtitle }}
              </div>
              <div class="space-y-2">
                <template
                  v-for="(section, sectionIdx) in (block.properties.sections || []).slice(0, 2)"
                  :key="sectionIdx"
                >
                  <div
                    v-if="section.title"
                    class="text-xs font-semibold text-n-slate-11 uppercase mt-3 first:mt-0"
                  >
                    {{ section.title }}
                  </div>
                  <div
                    v-for="(item, i) in (section.items || []).slice(0, 3)"
                    :key="`${sectionIdx}-${i}`"
                    class="flex items-center gap-3 p-3 border border-n-slate-7 rounded hover:bg-n-slate-2 transition-colors"
                  >
                    <div
                      v-if="item.imageIdentifier || item.image_identifier"
                      class="w-10 h-10 bg-n-slate-3 rounded flex items-center justify-center overflow-hidden flex-shrink-0"
                    >
                      <img
                        v-if="getImageData(item.imageIdentifier || item.image_identifier, block.properties)"
                        :src="getImageData(item.imageIdentifier || item.image_identifier, block.properties)"
                        alt=""
                        class="w-full h-full object-cover"
                      />
                      <i v-else class="i-lucide-image text-n-slate-9" />
                    </div>
                    <div class="flex-1">
                      <div class="text-sm font-medium text-n-slate-12">
                        {{ item.title }}
                      </div>
                      <div
                        v-if="item.subtitle"
                        class="text-xs text-n-slate-10"
                      >
                        {{ item.subtitle }}
                      </div>
                    </div>
                  </div>
                </template>
              </div>
            </div>

            <!-- Payment Block -->
            <div v-else-if="block.blockType === 'payment'" class="space-y-3">
              <div class="flex items-center gap-2">
                <i class="i-lucide-credit-card text-n-green-11" />
                <span class="font-medium text-n-slate-12">Payment Request</span>
              </div>
              <div class="space-y-1">
                <div class="text-sm text-n-slate-11">
                  Merchant:
                  {{ processProperties(block.properties).merchantName }}
                </div>
                <div class="text-lg font-semibold text-n-slate-12">
                  {{ processProperties(block.properties).currency }}
                  {{ processProperties(block.properties).amount }}
                </div>
                <div class="text-sm text-n-slate-11">
                  {{ processProperties(block.properties).description }}
                </div>
              </div>
              <div class="pt-2">
                <div
                  class="px-4 py-2 bg-n-green-9 text-white rounded text-center font-medium"
                >
                  Pay Now
                </div>
              </div>
            </div>

            <!-- Form Block -->
            <div v-else-if="block.blockType === 'form'" class="space-y-3">
              <div class="font-medium text-n-slate-12">
                {{ processProperties(block.properties).title }}
              </div>
              <div class="space-y-2">
                <div
                  v-for="(field, i) in block.properties.fields.slice(0, 4)"
                  :key="i"
                  class="space-y-1"
                >
                  <label class="text-xs font-medium text-n-slate-11">
                    {{ field.label }}
                    <span v-if="field.required" class="text-n-red-11">*</span>
                  </label>
                  <input
                    type="text"
                    :placeholder="field.placeholder"
                    disabled
                    class="w-full px-3 py-2 text-sm border border-n-slate-7 rounded bg-n-slate-1"
                  />
                </div>
              </div>
            </div>

            <!-- Generic Block -->
            <div v-else class="text-sm text-n-slate-11">
              {{ block.blockType }} block preview
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Info Note -->
    <div class="bg-n-blue-2 border border-n-blue-7 rounded-lg p-4">
      <div class="flex items-start gap-3">
        <i class="i-lucide-info text-n-blue-11 mt-0.5" />
        <div class="text-sm text-n-blue-11">
          <p class="font-medium mb-1">Preview Note</p>
          <p>
            This is a simplified preview. Actual rendering may vary by channel
            capabilities and configurations. Test with real messages to ensure
            proper display.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
