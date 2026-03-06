<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  MEDIA_FORMATS,
  BUTTON_TYPES,
  replaceTemplateVariablesByExamples,
} from 'dashboard/helper/templateHelper';

const props = defineProps({
  templateData: {
    type: Object,
    required: true,
  },
  parameterType: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();

const buttonIconMap = {
  [BUTTON_TYPES.URL]: 'i-lucide-external-link',
  [BUTTON_TYPES.PHONE_NUMBER]: 'i-lucide-phone',
  [BUTTON_TYPES.COPY_CODE]: 'i-lucide-copy',
  [BUTTON_TYPES.QUICK_REPLY]: 'i-lucide-reply',
  [BUTTON_TYPES.FLOW]: 'i-lucide-git-branch',
  QUICK_REPLY_OVERFLOW: 'i-lucide-list',
};

const previewTime = new Date().toLocaleTimeString([], {
  hour: '2-digit',
  minute: '2-digit',
});

const headerData = computed(() => props.templateData.header || {});
const bodyData = computed(() => props.templateData.body || {});
const footerData = computed(() => props.templateData.footer || {});
const buttonsData = computed(() => props.templateData.buttons || []);

const headerText = computed(() => {
  if (!headerData.value.enabled || headerData.value.format !== 'TEXT') {
    return '';
  }
  const examples =
    props.parameterType === 'named'
      ? headerData.value.example?.header_text_named_params
      : headerData.value.example?.header_text;

  return replaceTemplateVariablesByExamples({
    parameterType: props.parameterType,
    examples: examples || [],
    templateText: headerData.value.text,
  });
});

const headerMediaPreview = computed(() => {
  if (!headerData.value.enabled) return null;
  const format = headerData.value.format;
  if (!MEDIA_FORMATS.includes(format)) return null;
  return {
    format,
    url: headerData.value.media?.fileUrl || '',
    fileName: headerData.value.media?.fileName || '',
  };
});

const bodyText = computed(() => {
  if (!bodyData.value?.text) return '';
  const examples =
    props.parameterType === 'named'
      ? bodyData.value.example?.body_text_named_params
      : bodyData.value.example?.body_text;

  return replaceTemplateVariablesByExamples({
    parameterType: props.parameterType,
    examples: examples || [],
    templateText: bodyData.value.text,
  });
});

const footerText = computed(() => {
  if (!footerData.value.enabled) return '';
  return footerData.value.text || '';
});

const buttonPreviewItems = computed(() => {
  if (!buttonsData.value?.length) return [];

  const mappedButtons = buttonsData.value.map(button => {
    let text = button.text;
    if (!text && button.type === BUTTON_TYPES.COPY_CODE) {
      text = t('MESSAGE_TEMPLATES.BUILDER.BUTTONS.DROPDOWN.COPY_CODE');
    }
    return {
      ...button,
      text,
      icon: buttonIconMap[button.type] || null,
    };
  });

  if (mappedButtons.length > 3) {
    const visibleButtons = mappedButtons.slice(0, 2);
    const overflowButton = {
      type: 'QUICK_REPLY_OVERFLOW',
      text: t('MESSAGE_TEMPLATES.BUILDER.BUTTONS.SEE_ALL_OPTIONS'),
      icon: buttonIconMap.QUICK_REPLY_OVERFLOW,
    };
    return [...visibleButtons, overflowButton];
  }

  return mappedButtons;
});

const hasPreviewContent = computed(() => {
  return (
    headerText.value ||
    headerMediaPreview.value ||
    bodyText.value ||
    footerText.value ||
    buttonPreviewItems.value.length > 0
  );
});

const mediaPlaceholderLabel = computed(() => {
  if (!headerMediaPreview.value) return '';
  const format = headerMediaPreview.value.format;
  const placeholderKey = {
    IMAGE: t('MESSAGE_TEMPLATES.BUILDER.PREVIEW.IMAGE_HEADER'),
    VIDEO: t('MESSAGE_TEMPLATES.BUILDER.PREVIEW.VIDEO_HEADER'),
    DOCUMENT: t('MESSAGE_TEMPLATES.BUILDER.PREVIEW.DOCUMENT_HEADER'),
  }[format];
  return placeholderKey || format;
});

// WhatsApp rich text formatting: *bold*, _italic_, ~strikethrough~, ```monospace```
function formatWhatsAppText(text) {
  if (!text) return '';
  // Escape HTML first
  let html = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
  // Order matters: monospace first (triple backtick), then single markers
  html = html.replace(
    /```([\s\S]*?)```/g,
    '<code class="px-1 py-0.5 bg-[#f0f0f0] rounded text-[13px] font-mono">$1</code>'
  );
  html = html.replace(/\*([^\s*](?:[^*]*[^\s*])?)\*/g, '<b>$1</b>');
  html = html.replace(/_([^\s_](?:[^_]*[^\s_])?)_/g, '<i>$1</i>');
  html = html.replace(/~([^\s~](?:[^~]*[^\s~])?)~/g, '<s>$1</s>');
  // Preserve newlines
  html = html.replace(/\n/g, '<br>');
  return html;
}

const bodyHtml = computed(() => formatWhatsAppText(bodyText.value));
const headerHtml = computed(() => formatWhatsAppText(headerText.value));
</script>

<template>
  <div
    class="bg-n-solid-2 border border-n-weak rounded-lg p-4 h-full flex flex-col"
  >
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-2">
        <Icon icon="i-lucide-panel-right" class="size-5 text-n-slate-11" />
        <h4 class="font-medium text-n-slate-12">
          {{ t('MESSAGE_TEMPLATES.BUILDER.PREVIEW.TITLE') }}
        </h4>
      </div>
    </div>

    <div
      class="flex-1 bg-[#E5DDD5] border border-n-weak/60 rounded-lg flex items-center justify-center px-4 py-8"
    >
      <div v-if="hasPreviewContent" class="relative w-full max-w-sm">
        <div
          class="bg-white rounded-lg shadow-sm border border-[#E0E0E0] overflow-hidden"
        >
          <div class="relative p-0.5 space-y-[10px] text-[#1F2C34]">
            <!-- Media header preview -->
            <div v-if="headerMediaPreview">
              <div class="rounded-lg overflow-hidden border border-[#E6E6E6]">
                <img
                  v-if="
                    headerMediaPreview.format === 'IMAGE' &&
                    headerMediaPreview.url
                  "
                  :src="headerMediaPreview.url"
                  alt=""
                  class="w-full max-h-52 object-cover"
                />
                <div
                  v-else
                  class="flex flex-col items-center justify-center gap-2 py-6 px-6 text-[#8E8E8E]"
                >
                  <Icon
                    :icon="
                      {
                        VIDEO: 'i-lucide-video',
                        DOCUMENT: 'i-lucide-file-text',
                      }[headerMediaPreview.format] || 'i-lucide-image'
                    "
                    class="size-7"
                  />
                  <p class="text-xs text-center">
                    {{ mediaPlaceholderLabel }}
                  </p>
                </div>
              </div>
            </div>

            <div class="p-2">
              <!-- Header text -->
              <p
                v-if="headerText"
                class="text-base font-semibold leading-snug text-[#0B141A]"
                v-html="headerHtml"
              />

              <!-- Body text -->
              <p
                v-if="bodyText"
                class="text-sm my-auto text-[#1F2C34]"
                v-html="bodyHtml"
              />

              <!-- Footer text -->
              <p
                v-if="footerText"
                class="text-xs text-[#8294A0] mt-2 leading-tight pr-10"
              >
                {{ footerText }}
              </p>

              <!-- Timestamp -->
              <span class="absolute bottom-1 right-2 text-xs text-[#8294A0]">
                {{ previewTime }}
              </span>
            </div>
          </div>

          <!-- Button previews -->
          <div
            v-if="buttonPreviewItems.length"
            class="border-t border-[#E7EDF2]"
          >
            <button
              v-for="(button, index) in buttonPreviewItems"
              :key="`button-preview-${index}`"
              type="button"
              class="w-full flex items-center justify-center gap-2 px-4 py-3 text-sm transition-colors text-center border-t border-[#E7EDF2] first:border-t-0 text-[#0591D9] font-medium"
            >
              <Icon
                v-if="button.icon"
                :icon="button.icon"
                class="size-4 text-[#0591D9]"
              />
              <div class="min-w-0 text-center">
                <span class="block truncate">{{ button.text }}</span>
              </div>
            </button>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div
        v-else
        class="text-center text-[#667781] flex flex-col items-center gap-2"
      >
        <Icon icon="i-lucide-message-square" class="size-10" />
        <p class="text-sm font-medium text-[#1F2C34]">
          {{ t('MESSAGE_TEMPLATES.BUILDER.PREVIEW.NO_CONTENT') }}
        </p>
      </div>
    </div>
  </div>
</template>
