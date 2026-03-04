<script setup>
/**
 * Renders a WhatsApp-style phone bubble preview of a template message.
 * Used in the template send modal to show agents exactly what the
 * contact will receive. Adapts to variable substitution in real-time.
 */
import { computed } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useI18n } from 'vue-i18n';
import {
  COMPONENT_TYPES,
  MEDIA_FORMATS,
  BUTTON_TYPES,
  findComponentByType,
  replaceTemplateVariables,
} from 'dashboard/helper/templateHelper';

const props = defineProps({
  template: { type: Object, required: true },
  processedParams: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const headerComponent = computed(() =>
  findComponentByType(props.template, COMPONENT_TYPES.HEADER)
);
const bodyComponent = computed(() =>
  findComponentByType(props.template, COMPONENT_TYPES.BODY)
);
const footerComponent = computed(() =>
  findComponentByType(props.template, COMPONENT_TYPES.FOOTER)
);
const buttonsComponent = computed(() =>
  findComponentByType(props.template, COMPONENT_TYPES.BUTTONS)
);

const headerText = computed(() => {
  if (!headerComponent.value || headerComponent.value.format !== 'TEXT')
    return '';
  return headerComponent.value.text || '';
});

const hasMediaHeader = computed(() =>
  MEDIA_FORMATS.includes(headerComponent.value?.format)
);

const mediaUrl = computed(() => props.processedParams?.header?.media_url || '');

const bodyText = computed(() => {
  const raw = bodyComponent.value?.text || '';
  return replaceTemplateVariables(raw, props.processedParams);
});

const footerText = computed(() => footerComponent.value?.text || '');

function iconForButton(type) {
  const map = {
    [BUTTON_TYPES.URL]: 'i-lucide-external-link',
    [BUTTON_TYPES.PHONE_NUMBER]: 'i-lucide-phone',
    [BUTTON_TYPES.COPY_CODE]: 'i-lucide-copy',
    [BUTTON_TYPES.QUICK_REPLY]: 'i-lucide-reply',
    [BUTTON_TYPES.FLOW]: 'i-lucide-git-branch',
  };
  return map[type] || 'i-lucide-reply';
}

const buttons = computed(() => {
  if (!buttonsComponent.value?.buttons) return [];
  const mapped = buttonsComponent.value.buttons.map(btn => ({
    text: btn.text,
    type: btn.type,
    icon: iconForButton(btn.type),
  }));
  if (mapped.length > 3) {
    return [
      ...mapped.slice(0, 2),
      {
        text: t('WHATSAPP_TEMPLATES.PREVIEW.SEE_ALL_OPTIONS'),
        type: 'overflow',
        icon: 'i-lucide-list',
      },
    ];
  }
  return mapped;
});

const previewTime = new Date().toLocaleTimeString([], {
  hour: '2-digit',
  minute: '2-digit',
});
</script>

<template>
  <div class="flex flex-col gap-2">
    <div class="flex items-center gap-1.5 text-xs text-n-slate-11">
      <Icon icon="i-lucide-eye" class="size-3.5" />
      <span class="font-medium">{{
        t('WHATSAPP_TEMPLATES.PREVIEW.TITLE')
      }}</span>
    </div>

    <div
      class="bg-[#E5DDD5] dark:bg-n-solid-3 rounded-lg p-4 flex justify-center"
    >
      <div class="w-full max-w-xs">
        <div
          class="bg-white dark:bg-n-solid-2 rounded-lg shadow-sm border border-[#E0E0E0] dark:border-n-weak overflow-hidden"
        >
          <!-- Media header -->
          <div v-if="hasMediaHeader">
            <img
              v-if="headerComponent?.format === 'IMAGE' && mediaUrl"
              :src="mediaUrl"
              alt=""
              class="w-full max-h-40 object-cover"
            />
            <div
              v-else
              class="flex flex-col items-center justify-center gap-1.5 py-5 text-[#8E8E8E] dark:text-n-slate-11"
            >
              <Icon
                :icon="
                  headerComponent?.format === 'VIDEO'
                    ? 'i-lucide-video'
                    : headerComponent?.format === 'DOCUMENT'
                      ? 'i-lucide-file-text'
                      : 'i-lucide-image'
                "
                class="size-6"
              />
              <span class="text-xs">{{ headerComponent?.format }}</span>
            </div>
          </div>

          <div class="p-2.5">
            <!-- Header text -->
            <p
              v-if="headerText"
              class="text-sm font-semibold leading-snug text-[#0B141A] dark:text-n-slate-12"
            >
              {{ headerText }}
            </p>

            <!-- Body -->
            <p
              v-if="bodyText"
              class="text-sm whitespace-pre-line text-[#1F2C34] dark:text-n-slate-12 mt-0.5"
            >
              {{ bodyText }}
            </p>

            <!-- Footer + time -->
            <div class="flex items-end justify-between mt-1.5">
              <p
                v-if="footerText"
                class="text-xs text-[#8294A0] dark:text-n-slate-10"
              >
                {{ footerText }}
              </p>
              <span
                class="text-xs text-[#8294A0] dark:text-n-slate-10 ml-auto shrink-0"
              >
                {{ previewTime }}
              </span>
            </div>
          </div>

          <!-- Buttons -->
          <div
            v-if="buttons.length"
            class="border-t border-[#E7EDF2] dark:border-n-weak"
          >
            <div
              v-for="(button, index) in buttons"
              :key="index"
              class="flex items-center justify-center gap-1.5 px-3 py-2.5 text-sm text-[#0591D9] dark:text-n-brand font-medium border-t border-[#E7EDF2] dark:border-n-weak first:border-t-0"
            >
              <Icon v-if="button.icon" :icon="button.icon" class="size-3.5" />
              <span class="truncate">{{ button.text }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
