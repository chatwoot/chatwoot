<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WhatsappTemplatesAPI from 'dashboard/api/whatsappTemplates';
import TemplatePreview from './TemplatePreview.vue';
import EmojiInput from 'shared/components/emoji/EmojiInput.vue';
import { validateTemplate, VALIDATION_KEYS, LIMITS } from './validators/metaTemplateRules';
import { buildTemplatePayload } from './builders/components';
import { countPlaceholders } from './utils/placeholders';
import type { HeaderFormat, ButtonType, TemplateCategory } from './validators/metaTemplateRules';

interface Props {
  isCreating: boolean;
  inboxId: number | string;
}

interface Emits {
  (e: 'create', payload: any): void;
  (e: 'cancel'): void;
}

const props = defineProps<Props>();
const emit = defineEmits<Emits>();
const { t } = useI18n();

// Form data
const templateName = ref('');
const category = ref<TemplateCategory>('MARKETING');
const language = ref('pt_BR');
const allowCategoryChange = ref(true);

// Header
const headerFormat = ref<HeaderFormat | null>(null);
const headerText = ref('');
const headerTextExample = ref('');
const headerMediaUrl = ref(''); // preview only
const headerMediaHandle = ref('');
const isUploadingMedia = ref(false);
const mediaUploadError = ref('');
const mediaFileInput = ref<HTMLInputElement | null>(null);

// Body
const bodyText = ref('');
const bodyExamples = ref<string[]>([]);
const bodyTextarea = ref<HTMLTextAreaElement | null>(null);
const showEmojiPicker = ref(false);

// Footer
const footerText = ref('');

// Buttons
const buttons = ref<Array<{
  type: ButtonType;
  text?: string;
  url?: string;
  urlExample?: string;
  phoneNumber?: string;
}>>([]);

// Constants
const CATEGORIES: TemplateCategory[] = ['AUTHENTICATION', 'MARKETING', 'UTILITY'];
const HEADER_FORMATS: Array<{ value: HeaderFormat | null; label: string; icon: string }> = [
  { value: null, label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.NONE'), icon: 'i-lucide-x' },
  { value: 'TEXT', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT'), icon: 'i-lucide-type' },
  { value: 'IMAGE', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.IMAGE'), icon: 'i-lucide-image' },
  { value: 'VIDEO', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.VIDEO'), icon: 'i-lucide-video' },
  { value: 'DOCUMENT', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.DOCUMENT'), icon: 'i-lucide-file-text' },
  { value: 'LOCATION', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.LOCATION'), icon: 'i-lucide-map-pin' },
];
const BUTTON_TYPES: Array<{ value: ButtonType; label: string; icon: string }> = [
  { value: 'QUICK_REPLY', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.QUICK_REPLY'), icon: 'i-lucide-reply' },
  { value: 'URL', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.URL'), icon: 'i-lucide-external-link' },
  { value: 'PHONE_NUMBER', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.PHONE'), icon: 'i-lucide-phone' },
  { value: 'COPY_CODE', label: t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.COPY_CODE'), icon: 'i-lucide-copy' },
];
const LANGUAGES = [
  { value: 'pt_BR', label: 'Português (Brasil)' },
  { value: 'en_US', label: 'English (US)' },
  { value: 'en', label: 'English' },
  { value: 'es', label: 'Español' },
  { value: 'es_ES', label: 'Español (España)' },
  { value: 'es_MX', label: 'Español (México)' },
  { value: 'fr', label: 'Français' },
  { value: 'de', label: 'Deutsch' },
  { value: 'it', label: 'Italiano' },
  { value: 'ja', label: '日本語' },
  { value: 'ko', label: '한국어' },
  { value: 'zh_CN', label: '简体中文' },
  { value: 'zh_TW', label: '繁體中文' },
];

const CATEGORY_ICONS: Record<string, string> = {
  AUTHENTICATION: 'i-lucide-key-round',
  MARKETING: 'i-lucide-megaphone',
  UTILITY: 'i-lucide-wrench',
};

// Watch body text for placeholders and auto-adjust examples
watch(bodyText, (newText) => {
  const count = countPlaceholders(newText);
  if (count > bodyExamples.value.length) {
    const missing = count - bodyExamples.value.length;
    bodyExamples.value.push(...Array(missing).fill(''));
  } else if (count < bodyExamples.value.length) {
    bodyExamples.value.splice(count);
  }
});

watch(headerFormat, newFormat => {
  // Clear media state when switching header formats
  if (newFormat !== 'IMAGE' && newFormat !== 'VIDEO' && newFormat !== 'DOCUMENT') {
    headerMediaUrl.value = '';
    headerMediaHandle.value = '';
  }
});

// Validation
const validation = computed(() => {
  return validateTemplate({
    name: templateName.value,
    category: category.value,
    headerFormat: headerFormat.value,
    headerText: headerText.value,
    headerTextExample: headerTextExample.value,
    headerMediaHandle: headerMediaHandle.value,
    bodyText: bodyText.value,
    bodyExamples: bodyExamples.value,
    footerText: footerText.value,
    buttons: buttons.value,
  });
});

const isValid = computed(() => validation.value.isValid);
const isBrowserAutomation = computed(() => !!window?.navigator?.webdriver);
const mediaInfoKey = computed(() => {
  if (headerFormat.value === 'VIDEO') {
    return 'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_INFO_VIDEO';
  }
  if (headerFormat.value === 'DOCUMENT') {
    return 'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_INFO_DOCUMENT';
  }
  return 'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_INFO_IMAGE';
});

const mediaAccept = computed(() => {
  if (headerFormat.value === 'VIDEO') return 'video/*';
  if (headerFormat.value === 'DOCUMENT') return 'application/pdf';
  return 'image/*';
});

// Translate validation error keys to i18n messages
const translateError = (errorKey: string): string => {
  // Check if error key is a known validation key
  const validationKeys = Object.values(VALIDATION_KEYS) as string[];
  if (validationKeys.includes(errorKey)) {
    const i18nKey = `INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.VALIDATION.${errorKey}`;
    const translated = t(i18nKey, {
      limit: LIMITS.TEMPLATE_NAME,
      categories: 'AUTHENTICATION, MARKETING, UTILITY',
      type: headerFormat.value?.toLowerCase() || 'media',
      index: '{{n}}',
    });
    // If translation exists (not same as key), return it
    if (translated !== i18nKey) {
      return translated;
    }
  }
  // Return original error if no translation found
  return errorKey;
};

const handleMediaFile = async (file: File) => {
  if (!file) return;

  // Preview
  headerMediaUrl.value = URL.createObjectURL(file);
  headerMediaHandle.value = '';
  mediaUploadError.value = '';

  isUploadingMedia.value = true;
  try {
    const { data } = await WhatsappTemplatesAPI.uploadMedia(props.inboxId, file);
    headerMediaHandle.value = data?.handle || '';
    if (!headerMediaHandle.value) {
      throw new Error('Upload succeeded but handle was missing');
    }
  } catch (error: any) {
    headerMediaHandle.value = '';
    // Keep preview; validation will block creation.
    mediaUploadError.value =
      error?.response?.data?.error ||
      error?.message ||
      'Failed to upload media';
  } finally {
    isUploadingMedia.value = false;
  }
};

const handleMediaFileSelected = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;
  await handleMediaFile(file);
};

const handleMediaDrop = async (event: DragEvent) => {
  const file = event.dataTransfer?.files?.[0];
  if (!file) return;
  await handleMediaFile(file);
};

// Button management
const addButton = () => {
  buttons.value.push({
    type: 'QUICK_REPLY',
    text: '',
  });
};

const removeButton = (index: number) => {
  buttons.value.splice(index, 1);
};

// Submit
const handleCreate = () => {
  if (!isValid.value) return;

  const payload = buildTemplatePayload({
    name: templateName.value,
    category: category.value,
    language: language.value,
    allowCategoryChange: allowCategoryChange.value,
    headerFormat: headerFormat.value,
    headerText: headerText.value,
    headerTextExample: headerTextExample.value,
    headerMediaUrl: headerMediaUrl.value,
    headerMediaHandle: headerMediaHandle.value,
    bodyText: bodyText.value,
    bodyExamples: bodyExamples.value,
    footerText: footerText.value,
    buttons: buttons.value,
  });

  emit('create', payload);
};

const handleCancel = () => {
  emit('cancel');
};

// Text formatting helpers
const toggleEmojiPicker = () => {
  showEmojiPicker.value = !showEmojiPicker.value;
};

const insertEmoji = (emoji: string) => {
  if (!bodyTextarea.value) return;
  
  const textarea = bodyTextarea.value;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = bodyText.value;
  
  bodyText.value = text.slice(0, start) + emoji + text.slice(end);
  showEmojiPicker.value = false;
  
  // Restore cursor position after emoji
  nextTick(() => {
    textarea.focus();
    const newPos = start + emoji.length;
    textarea.setSelectionRange(newPos, newPos);
  });
};

const wrapSelection = (wrapper: string) => {
  if (!bodyTextarea.value) return;
  
  const textarea = bodyTextarea.value;
  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const text = bodyText.value;
  const selectedText = text.slice(start, end);
  
  if (selectedText) {
    // Wrap selected text
    const wrappedText = wrapper + selectedText + wrapper;
    bodyText.value = text.slice(0, start) + wrappedText + text.slice(end);
    
    nextTick(() => {
      textarea.focus();
      // Position cursor after wrapped text
      const newEnd = start + wrappedText.length;
      textarea.setSelectionRange(newEnd, newEnd);
    });
  } else {
    // Insert wrapper characters and position cursor in middle
    const insertion = wrapper + wrapper;
    bodyText.value = text.slice(0, start) + insertion + text.slice(end);
    
    nextTick(() => {
      textarea.focus();
      const cursorPos = start + wrapper.length;
      textarea.setSelectionRange(cursorPos, cursorPos);
    });
  }
};

const insertVariable = () => {
  if (!bodyTextarea.value) return;
  
  const textarea = bodyTextarea.value;
  const start = textarea.selectionStart;
  const text = bodyText.value;
  
  // Find the next variable number
  const existingVars = text.match(/\{\{(\d+)\}\}/g) || [];
  const usedNumbers = existingVars.map(v => parseInt(v.replace(/\D/g, ''), 10));
  let nextNum = 1;
  while (usedNumbers.includes(nextNum)) {
    nextNum++;
  }
  
  const variable = `{{${nextNum}}}`;
  bodyText.value = text.slice(0, start) + variable + text.slice(start);
  
  nextTick(() => {
    textarea.focus();
    const newPos = start + variable.length;
    textarea.setSelectionRange(newPos, newPos);
  });
};
</script>

<template>
  <div class="p-6 w-[1100px] flex flex-col max-h-[85vh]">
    <h2 class="text-lg font-medium text-n-slate-12 mb-6 flex-shrink-0">
      {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.CREATE_TITLE') }}
    </h2>
    
    <div class="flex gap-6 flex-1 min-h-0 overflow-hidden">
    <!-- Builder Form -->
    <div class="flex-1 overflow-y-auto pr-4 space-y-6">
      <!-- Basic Info Section -->
      <section class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container">
        <div class="flex items-center gap-2 mb-4">
          <i class="i-lucide-settings-2 text-lg text-n-slate-11" />
          <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.TITLE') }}
          </h3>
        </div>

        <div class="space-y-4">
          <!-- Template Name -->
          <div>
            <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.NAME') }}
              <span class="text-red-500 ml-0.5">*</span>
            </label>
            <input
              v-model="templateName"
              type="text"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500 transition-colors"
              :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.NAME_PLACEHOLDER')"
            />
            <p class="text-xs text-n-slate-11 mt-1.5">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.NAME_HELP') }}
            </p>
          </div>

          <!-- Category & Language -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.CATEGORY') }}
                <span class="text-red-500 ml-0.5">*</span>
              </label>
              <div class="relative">
                <select
                  v-model="category"
                  class="w-full px-3 py-2 pl-9 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm focus:ring-2 focus:ring-woot-500 focus:border-woot-500 cursor-pointer"
                >
                  <option v-for="cat in CATEGORIES" :key="cat" :value="cat" class="bg-n-solid-3 text-n-slate-12">
                    {{ $t(`INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.CATEGORIES.${cat}`) }}
                  </option>
                </select>
                <i :class="CATEGORY_ICONS[category]" class="absolute left-3 top-1/2 -translate-y-1/2 text-n-slate-11 pointer-events-none" />
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.LANGUAGE') }}
                <span class="text-red-500 ml-0.5">*</span>
              </label>
              <select
                v-model="language"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm focus:ring-2 focus:ring-woot-500 focus:border-woot-500 cursor-pointer"
              >
                <option v-for="lang in LANGUAGES" :key="lang.value" :value="lang.value" class="bg-n-solid-3 text-n-slate-12">
                  {{ lang.label }}
                </option>
              </select>
            </div>
          </div>

          <!-- Allow Category Change -->
          <label class="flex items-center gap-2.5 cursor-pointer group">
            <input
              v-model="allowCategoryChange"
              type="checkbox"
              class="w-4 h-4 rounded border-n-weak text-woot-500 focus:ring-woot-500 cursor-pointer bg-n-alpha-2"
            />
            <span class="text-sm text-n-slate-12 group-hover:text-n-slate-11">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.ALLOW_CATEGORY_CHANGE') }}
            </span>
          </label>

          <!-- Authentication Warning -->
          <div 
            v-if="category === 'AUTHENTICATION'" 
            class="p-3 rounded-lg bg-amber-500/10 border border-amber-500/30 flex items-start gap-2"
          >
            <i class="i-lucide-alert-triangle text-amber-500 flex-shrink-0 mt-0.5" />
            <div class="text-sm">
              <p class="font-medium text-amber-600 dark:text-amber-400">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.AUTH_WARNING_TITLE') }}
              </p>
              <p class="text-amber-600/80 dark:text-amber-400/80 mt-1">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BASICS.AUTH_WARNING_TEXT') }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Header Section -->
      <section class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container">
        <div class="flex items-center gap-2 mb-4">
          <i class="i-lucide-layout-template text-lg text-n-slate-11" />
          <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TITLE') }}
          </h3>
        </div>

        <div class="space-y-4">
          <!-- Header Type Selection -->
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="format in HEADER_FORMATS"
              :key="format.value ?? 'none'"
              type="button"
              class="flex flex-col items-center gap-1.5 p-3 rounded-lg border-2 transition-all text-sm"
              :class="headerFormat === format.value
                ? 'border-woot-500 bg-woot-500/10 text-woot-500'
                : 'border-n-weak bg-n-alpha-2 text-n-slate-11 hover:border-n-slate-6 hover:bg-n-alpha-3'"
              @click="headerFormat = format.value"
            >
              <i :class="format.icon" class="text-lg" />
              <span class="text-xs font-medium">{{ format.label }}</span>
            </button>
          </div>

          <!-- Text Header -->
          <div v-if="headerFormat === 'TEXT'" class="space-y-3 pt-2">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT_CONTENT') }}
                <span class="text-red-500 ml-0.5">*</span>
              </label>
              <input
                v-model="headerText"
                type="text"
                maxlength="60"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT_PLACEHOLDER')"
              />
              <div class="flex justify-between mt-1">
                <p class="text-xs text-n-slate-11">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT_HELP') }}</p>
                <span class="text-xs text-n-slate-11">{{ headerText.length }}/60</span>
              </div>
            </div>

            <div v-if="headerText.includes('{{1}}')">
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT_EXAMPLE') }}
                <span class="text-red-500 ml-0.5">*</span>
              </label>
              <input
                v-model="headerTextExample"
                type="text"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.TEXT_EXAMPLE_PLACEHOLDER')"
              />
            </div>
          </div>

          <!-- Media Header -->
          <div v-if="headerFormat === 'IMAGE' || headerFormat === 'VIDEO' || headerFormat === 'DOCUMENT'" class="space-y-3 pt-2">
            <div class="bg-blue-500/10 border border-blue-500/30 rounded-lg p-3 mb-3">
              <p class="text-xs text-blue-600 dark:text-blue-400">
                <i class="i-lucide-info inline-block mr-1" />
                    {{ $t(mediaInfoKey) }}
              </p>
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-1.5">
                    {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_URL') }}
                <span class="text-red-500 ml-0.5">*</span>
              </label>
                  <div
                    class="relative w-full rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm focus:ring-2 focus:ring-woot-500 focus:border-woot-500 px-3 py-4 cursor-pointer transition-colors overflow-hidden"
                    :class="isUploadingMedia ? 'opacity-60 cursor-not-allowed' : 'hover:bg-n-alpha-3'"
                    @dragover.prevent
                    @drop.prevent="handleMediaDrop"
                  >
                    <p class="text-sm text-n-slate-12">
                      {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_DROP_HINT') }}
                    </p>
                    <p v-if="isBrowserAutomation" class="text-xs text-amber-600 dark:text-amber-400 mt-1.5">
                      {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.FILE_PICKER_AUTOMATION_NOTICE') }}
                    </p>
                    <p v-if="headerMediaUrl" class="text-xs text-n-slate-11 mt-1.5">
                      {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.PREVIEW_ONLY') }}: {{ headerFormat?.toLowerCase() }}
                    </p>
                    <input
                      ref="mediaFileInput"
                      type="file"
                      :accept="mediaAccept"
                      class="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                      @dragover.prevent
                      @drop.prevent="handleMediaDrop"
                      @change="handleMediaFileSelected"
                    />
                  </div>
              <p v-if="isUploadingMedia" class="text-xs text-n-slate-11 mt-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_UPLOADING') }}
              </p>
              <p v-else-if="headerMediaHandle" class="text-xs text-green-600 dark:text-green-400 mt-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.MEDIA_UPLOADED') }}
              </p>
              <p v-else-if="mediaUploadError" class="text-xs text-red-600 dark:text-red-400 mt-1.5">
                {{ mediaUploadError }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Body Section -->
      <section class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container">
        <div class="flex items-center gap-2 mb-4">
          <i class="i-lucide-text text-lg text-n-slate-11" />
          <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.TITLE') }}
            <span class="text-red-500 ml-0.5">*</span>
          </h3>
        </div>

        <div class="space-y-4">
          <div>
            <!-- Formatting Toolbar -->
            <div class="relative">
              <div class="flex items-center gap-1 mb-2 p-1.5 bg-n-alpha-2 rounded-lg border border-n-weak">
                <button
                  type="button"
                  class="p-1.5 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors"
                  title="Emoji"
                  @click="toggleEmojiPicker"
                >
                  <i class="i-lucide-smile text-base" />
                </button>
                <div class="w-px h-5 bg-n-weak mx-1"></div>
                <button
                  type="button"
                  class="p-1.5 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors font-bold text-sm"
                  title="Bold (*text*)"
                  @click="wrapSelection('*')"
                >
                  B
                </button>
                <button
                  type="button"
                  class="p-1.5 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors italic text-sm"
                  title="Italic (_text_)"
                  @click="wrapSelection('_')"
                >
                  I
                </button>
                <button
                  type="button"
                  class="p-1.5 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors line-through text-sm"
                  title="Strikethrough (~text~)"
                  @click="wrapSelection('~')"
                >
                  S
                </button>
                <button
                  type="button"
                  class="p-1.5 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors font-mono text-xs"
                  title="Monospace (```text```)"
                  @click="wrapSelection('```')"
                >
                  &lt;/&gt;
                </button>
                <div class="w-px h-5 bg-n-weak mx-1"></div>
                <button
                  type="button"
                  class="px-2 py-1 rounded hover:bg-n-alpha-3 text-n-slate-11 hover:text-n-slate-12 transition-colors text-xs flex items-center gap-1"
                  :title="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.FORMATTING.ADD_VARIABLE')"
                  @click="insertVariable"
                >
                  <i class="i-lucide-plus text-xs" />
                  <span class="font-mono">{{ '{' + '{n}' + '}' }}</span>
                </button>
              </div>
              
              <!-- Emoji Picker - positioned below toolbar -->
              <div 
                v-if="showEmojiPicker" 
                class="absolute z-50 left-0 top-full mt-1 emoji-picker-override"
              >
                <EmojiInput :on-click="insertEmoji" />
              </div>
            </div>
            
            <textarea
              ref="bodyTextarea"
              v-model="bodyText"
              rows="15"
              maxlength="1024"
              class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500 resize-y"
              style="min-height: 200px;"
              :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.TEXT_PLACEHOLDER')"
              @click="showEmojiPicker = false"
            ></textarea>
            <div class="flex justify-between mt-1">
              <p class="text-xs text-n-slate-11">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.TEXT_HELP') }}</p>
              <span class="text-xs text-n-slate-11">{{ bodyText.length }}/1024</span>
            </div>
          </div>

          <!-- Variable Examples -->
          <div v-if="bodyExamples.length > 0" class="space-y-3 pt-2 border-t border-n-weak">
            <label class="block text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.EXAMPLES') }}
              <span class="text-red-500 ml-0.5">*</span>
            </label>
            <div
              v-for="(example, index) in bodyExamples"
              :key="index"
              class="flex items-center gap-3"
            >
              <div class="flex-shrink-0 w-14 h-8 rounded bg-woot-500/20 flex items-center justify-center">
                <span class="text-xs font-mono font-semibold text-woot-500">&#123;&#123;{{ index + 1 }}&#125;&#125;</span>
              </div>
              <input
                v-model="bodyExamples[index]"
                type="text"
                class="flex-1 px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BODY.EXAMPLE_PLACEHOLDER', { index: index + 1 })"
              />
            </div>
          </div>
        </div>
      </section>

      <!-- Footer Section -->
      <section class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container">
        <div class="flex items-center gap-2 mb-4">
          <i class="i-lucide-footer text-lg text-n-slate-11" />
          <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.FOOTER.TITLE') }}
          </h3>
        </div>

        <div>
          <input
            v-model="footerText"
            type="text"
            maxlength="60"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-2 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
            :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.FOOTER.TEXT_PLACEHOLDER')"
          />
          <div class="flex justify-between mt-1">
            <p class="text-xs text-n-slate-11">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.FOOTER.TEXT_HELP') }}</p>
            <span class="text-xs text-n-slate-11">{{ footerText.length }}/60</span>
          </div>
        </div>
      </section>

      <!-- Buttons Section -->
      <section class="bg-n-solid-2 rounded-2xl p-5 shadow outline-1 outline outline-n-container">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2">
            <i class="i-lucide-mouse-pointer-click text-lg text-n-slate-11" />
            <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
              {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.TITLE') }}
            </h3>
          </div>
          <NextButton
            v-if="buttons.length < 10"
            ghost
            size="sm"
            icon="i-lucide-plus"
            :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.ADD')"
            @click="addButton"
          />
        </div>

        <div v-if="buttons.length === 0" class="text-center py-6 text-n-slate-11">
          <i class="i-lucide-mouse-pointer-click text-3xl mb-2 opacity-50" />
          <p class="text-sm">{{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.EMPTY') }}</p>
        </div>

        <div class="space-y-3">
          <div
            v-for="(button, index) in buttons"
            :key="index"
            class="bg-n-alpha-2 rounded-xl p-4 space-y-3 outline-1 outline outline-n-container"
          >
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium text-n-slate-12">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.BUTTON_TYPE') }} {{ index + 1 }}
              </span>
              <button
                type="button"
                class="p-1.5 rounded-lg text-red-500 hover:bg-red-500/10 transition-colors"
                @click="removeButton(index)"
              >
                <i class="i-lucide-trash-2" />
              </button>
            </div>

            <!-- Button Type Selection -->
            <div class="grid grid-cols-4 gap-2">
              <button
                v-for="type in BUTTON_TYPES"
                :key="type.value"
                type="button"
                class="flex flex-col items-center gap-1 p-2 rounded-lg border transition-all text-xs"
                :class="button.type === type.value
                  ? 'border-woot-500 bg-woot-500/10 text-woot-500'
                  : 'border-n-weak bg-n-alpha-1 text-n-slate-11 hover:border-n-slate-6'"
                @click="button.type = type.value"
              >
                <i :class="type.icon" />
                <span class="font-medium truncate w-full text-center">{{ type.label }}</span>
              </button>
            </div>

            <!-- Button Text -->
            <div v-if="button.type !== 'COPY_CODE'">
              <input
                v-model="button.text"
                type="text"
                maxlength="25"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.TEXT_PLACEHOLDER')"
              />
              <div class="flex justify-end mt-1">
                <span class="text-xs text-n-slate-11">{{ (button.text || '').length }}/25</span>
              </div>
            </div>

            <!-- URL Input -->
            <div v-if="button.type === 'URL'" class="space-y-2">
              <input
                v-model="button.url"
                type="url"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.URL_PLACEHOLDER')"
              />
              <div v-if="button.url && button.url.includes('{{1}}')" class="mt-2">
                <input
                  v-model="button.urlExample"
                  type="text"
                  class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                  :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.URL_EXAMPLE_PLACEHOLDER')"
                />
              </div>
            </div>

            <!-- Phone Input -->
            <div v-if="button.type === 'PHONE_NUMBER'">
              <input
                v-model="button.phoneNumber"
                type="tel"
                class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 text-sm placeholder:text-n-slate-10 focus:ring-2 focus:ring-woot-500 focus:border-woot-500"
                :placeholder="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.PHONE_PLACEHOLDER')"
              />
              <p class="text-xs text-n-slate-11 mt-1.5">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.PHONE_HELP') }}
              </p>
            </div>

            <!-- Copy Code Info -->
            <div v-if="button.type === 'COPY_CODE'" class="bg-amber-500/10 border border-amber-500/30 rounded-lg p-3">
              <p class="text-xs text-amber-500">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.BUTTONS.COPY_CODE_HELP') }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <!-- Validation Errors -->
      <div v-if="!isValid && validation.errors.length > 0">
        <div class="bg-red-500/10 border border-red-500/30 rounded-xl p-4">
          <div class="flex items-start gap-3">
            <i class="i-lucide-alert-circle text-lg text-red-500 flex-shrink-0 mt-0.5" />
            <div>
              <p class="text-sm font-medium text-red-500 mb-2">
                {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.VALIDATION_ERRORS') }}
              </p>
              <ul class="space-y-1">
                <li v-for="(error, index) in validation.errors" :key="index" class="text-sm text-red-400 flex items-start gap-2">
                  <span class="text-red-500/50">•</span>
                  <span>{{ translateError(error) }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Preview Panel -->
    <div class="w-[360px] flex-shrink-0 overflow-y-auto">
      <div>
        <div class="flex items-center gap-2 mb-4">
          <i class="i-lucide-smartphone text-lg text-n-slate-11" />
          <h3 class="text-sm font-semibold text-n-slate-12 uppercase tracking-wide">
            {{ $t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.TITLE') }}
          </h3>
        </div>
        <TemplatePreview
          :header-format="headerFormat"
          :header-text="headerText"
          :header-text-example="headerTextExample"
          :header-media-url="headerMediaUrl"
          :body-text="bodyText"
          :body-examples="bodyExamples"
          :footer-text="footerText"
          :buttons="buttons"
        />
      </div>
    </div>
    </div>

    <!-- Actions Footer -->
    <div class="flex-shrink-0 flex justify-end gap-3 pt-6 mt-6 border-t border-n-container">
      <NextButton
        ghost
        :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.CANCEL')"
        @click="handleCancel"
      />
      <NextButton
        :is-loading="isCreating"
        :disabled="!isValid"
        :label="$t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.CREATE')"
        @click="handleCreate"
      />
    </div>
  </div>
</template>

<style>
/* Override EmojiInput's default absolute positioning */
.emoji-picker-override .emoji-dialog {
  position: static !important;
  top: auto !important;
  right: auto !important;
}
</style>

