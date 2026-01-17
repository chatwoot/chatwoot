<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { renderWithExamples } from './utils/placeholders';

const props = defineProps({
  headerFormat: { type: String, default: null },
  headerText: { type: String, default: '' },
  headerTextExample: { type: String, default: '' },
  headerMediaUrl: { type: String, default: '' },
  headerMediaName: { type: String, default: '' },
  bodyText: { type: String, default: '' },
  bodyExamples: { type: Array, default: () => [] },
  footerText: { type: String, default: '' },
  buttons: { type: Array, default: () => [] },
});

const { t } = useI18n();

// Dark mode detection
const isDarkMode = ref(document.body.classList.contains('dark'));

// Watch for dark mode changes via MutationObserver
let observer = null;

onMounted(() => {
  observer = new MutationObserver(() => {
    isDarkMode.value = document.body.classList.contains('dark');
  });
  observer.observe(document.body, {
    attributes: true,
    attributeFilter: ['class'],
  });
});

onUnmounted(() => {
  if (observer) {
    observer.disconnect();
  }
});

// Theme-aware colors
const colors = computed(() => {
  if (isDarkMode.value) {
    return {
      outerBg: 'bg-n-slate-2',
      phoneBg: '#0b141a',
      headerBg: '#202c33',
      chatBg: '#0b141a',
      chatPattern: '%23172025',
      bubbleBg: '#005c4b',
      mediaBg: '#1d3c34',
      buttonBg: '#202c33',
      buttonHover: '#2a3942',
      textPrimary: 'white',
      textSecondary: '#8696a0',
      textMuted: '#667781',
      linkColor: '#53bdeb',
      accentColor: '#00a884',
    };
  }
  // Light mode - WhatsApp light theme colors
  return {
    outerBg: 'bg-n-slate-2',
    phoneBg: '#f0f2f5',
    headerBg: '#008069',
    chatBg: '#efeae2',
    chatPattern: '%23d1cdc7',
    bubbleBg: '#d9fdd3',
    mediaBg: '#c8e6c0',
    buttonBg: '#ffffff',
    buttonHover: '#f5f5f5',
    textPrimary: '#111b21',
    textSecondary: '#667781',
    textMuted: '#8696a0',
    linkColor: '#027eb5',
    accentColor: '#008069',
  };
});

const renderedHeaderText = computed(() => {
  if (props.headerFormat !== 'TEXT' || !props.headerText) return '';
  return renderWithExamples(
    props.headerText,
    props.headerTextExample ? [props.headerTextExample] : []
  );
});

const renderedBodyText = computed(() => {
  if (!props.bodyText) return '';
  return renderWithExamples(props.bodyText, props.bodyExamples || []);
});

const validButtons = computed(() => {
  return props.buttons
    .filter(button => {
      // Only show buttons that have required fields
      if (button.type === 'COPY_CODE') return true;
      if (button.type === 'QUICK_REPLY' && button.text?.trim()) return true;
      if (button.type === 'URL' && button.text?.trim()) return true;
      if (button.type === 'PHONE_NUMBER' && button.text?.trim()) return true;
      return false;
    })
    .map(button => {
      if (button.type === 'URL' && button.url) {
        const urlWithExample = renderWithExamples(
          button.url,
          button.urlExample ? [button.urlExample] : []
        );
        return { ...button, displayUrl: urlWithExample };
      }
      if (button.type === 'COPY_CODE') {
        return { ...button, text: 'Copy code' };
      }
      return button;
    });
});

const hasContent = computed(() => {
  return (
    props.headerFormat ||
    props.bodyText ||
    props.footerText ||
    validButtons.value.length > 0
  );
});

const getButtonIcon = type => {
  switch (type) {
    case 'URL':
      return 'i-lucide-external-link';
    case 'PHONE_NUMBER':
      return 'i-lucide-phone';
    case 'COPY_CODE':
      return 'i-lucide-copy';
    case 'QUICK_REPLY':
      return 'i-lucide-reply';
    default:
      return '';
  }
};
</script>

<template>
  <div :class="colors.outerBg" class="rounded-xl p-4 min-h-[400px]">
    <!-- Phone frame mockup -->
    <div
      class="rounded-lg overflow-hidden shadow-xl"
      :style="{ backgroundColor: colors.phoneBg }"
    >
      <!-- WhatsApp header -->
      <div
        class="px-4 py-3 flex items-center gap-3"
        :style="{ backgroundColor: colors.headerBg }"
      >
        <div
          class="w-8 h-8 rounded-full flex items-center justify-center"
          :style="{ backgroundColor: colors.accentColor }"
        >
          <i class="i-lucide-building-2 text-white text-sm" />
        </div>
        <div class="flex-1">
          <p class="text-white text-sm font-medium">
            {{
              t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.BUSINESS_NAME')
            }}
          </p>
          <p
            class="text-xs"
            :style="{ color: isDarkMode ? '#8696a0' : '#ffffff99' }"
          >
            {{
              t(
                'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.BUSINESS_SUBTITLE'
              )
            }}
          </p>
        </div>
      </div>

      <!-- Chat area -->
      <div
        class="p-4 min-h-[300px]"
        :style="{
          backgroundColor: colors.chatBg,
          backgroundImage: `url('data:image/svg+xml,%3Csvg width=&quot;60&quot; height=&quot;60&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;%3E%3Cdefs%3E%3Cpattern id=&quot;grid&quot; width=&quot;60&quot; height=&quot;60&quot; patternUnits=&quot;userSpaceOnUse&quot;%3E%3Cpath d=&quot;M 60 0 L 0 0 0 60&quot; fill=&quot;none&quot; stroke=&quot;${colors.chatPattern}&quot; stroke-width=&quot;0.5&quot;/%3E%3C/pattern%3E%3C/defs%3E%3Crect width=&quot;100%25&quot; height=&quot;100%25&quot; fill=&quot;url(%23grid)&quot;/%3E%3C/svg%3E')`,
        }"
      >
        <!-- Empty state -->
        <div
          v-if="!hasContent"
          class="flex flex-col items-center justify-center h-64 text-center"
        >
          <i
            class="i-lucide-message-square-dashed text-4xl mb-3"
            :style="{ color: colors.textSecondary }"
          />
          <p class="text-sm" :style="{ color: colors.textSecondary }">
            {{ t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.EMPTY_TITLE') }}
          </p>
          <p class="text-xs mt-1" :style="{ color: colors.textMuted }">
            {{
              t(
                'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.EMPTY_DESCRIPTION'
              )
            }}
          </p>
        </div>

        <!-- Message bubble -->
        <div v-else class="max-w-[85%]">
          <div
            class="rounded-lg overflow-hidden shadow-md"
            :style="{ backgroundColor: colors.bubbleBg }"
          >
            <!-- Header -->
            <div v-if="headerFormat">
              <!-- Text Header -->
              <div
                v-if="
                  headerFormat === 'TEXT' && (renderedHeaderText || headerText)
                "
                class="px-3 pt-2"
              >
                <p
                  class="text-sm font-semibold"
                  :style="{ color: colors.textPrimary }"
                >
                  {{ renderedHeaderText || headerText }}
                </p>
              </div>

              <!-- Image Header -->
              <div
                v-else-if="headerFormat === 'IMAGE'"
                :style="{ backgroundColor: colors.mediaBg }"
              >
                <div v-if="headerMediaUrl" class="aspect-video">
                  <img
                    :src="headerMediaUrl"
                    alt="Header image"
                    class="w-full h-full object-cover"
                  />
                </div>
                <div
                  v-else
                  class="aspect-video flex items-center justify-center"
                >
                  <div class="text-center">
                    <i
                      class="i-lucide-image-off text-3xl"
                      :style="{ color: colors.textMuted }"
                    />
                    <p
                      class="text-xs mt-1"
                      :style="{ color: colors.textMuted }"
                    >
                      {{
                        t(
                          'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.NO_IMAGE'
                        )
                      }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Video Header -->
              <div
                v-else-if="headerFormat === 'VIDEO'"
                :style="{ backgroundColor: colors.mediaBg }"
              >
                <div class="aspect-video flex items-center justify-center">
                  <div v-if="headerMediaUrl" class="text-center">
                    <div
                      class="w-12 h-12 rounded-full flex items-center justify-center mb-2"
                      :style="{ backgroundColor: colors.accentColor + '33' }"
                    >
                      <i
                        class="i-lucide-play text-2xl"
                        :style="{ color: colors.accentColor }"
                      />
                    </div>
                  </div>
                  <div v-else class="text-center">
                    <i
                      class="i-lucide-video-off text-3xl"
                      :style="{ color: colors.textMuted }"
                    />
                    <p
                      class="text-xs mt-1"
                      :style="{ color: colors.textMuted }"
                    >
                      {{
                        t(
                          'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.NO_VIDEO'
                        )
                      }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Document Header -->
              <div
                v-else-if="headerFormat === 'DOCUMENT'"
                class="p-3"
                :style="{ backgroundColor: colors.mediaBg }"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 rounded flex items-center justify-center"
                    :style="{ backgroundColor: colors.accentColor + '33' }"
                  >
                    <i
                      class="i-lucide-file-text text-xl"
                      :style="{ color: colors.accentColor }"
                    />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p
                      class="text-sm font-medium truncate"
                      :style="{ color: colors.textPrimary }"
                    >
                      {{
                        headerMediaName ||
                        t(
                          'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.HEADER.DOCUMENT'
                        ) + '.pdf'
                      }}
                    </p>
                    <p class="text-xs" :style="{ color: colors.textSecondary }">
                      {{
                        t(
                          'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.DOCUMENT_INFO'
                        )
                      }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Location Header -->
              <div
                v-else-if="headerFormat === 'LOCATION'"
                :style="{ backgroundColor: colors.mediaBg }"
              >
                <div class="aspect-video flex items-center justify-center">
                  <div class="text-center">
                    <i
                      class="i-lucide-map-pin text-4xl"
                      :style="{ color: colors.accentColor }"
                    />
                    <p
                      class="text-xs mt-2"
                      :style="{ color: colors.textSecondary }"
                    >
                      {{
                        t(
                          'INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.LOCATION_LABEL'
                        )
                      }}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Body -->
            <div class="px-3 py-2">
              <p
                class="text-sm whitespace-pre-wrap leading-relaxed"
                :style="{ color: colors.textPrimary }"
              >
                {{ renderedBodyText || 'Message body...' }}
              </p>
            </div>

            <!-- Footer -->
            <div v-if="footerText" class="px-3 pb-1">
              <p class="text-xs" :style="{ color: colors.textSecondary }">
                {{ footerText }}
              </p>
            </div>

            <!-- Timestamp -->
            <div class="px-3 pb-2 flex justify-end">
              <span
                class="text-[10px]"
                :style="{ color: colors.textSecondary }"
              >
                {{
                  t('INBOX_MGMT.WHATSAPP_TEMPLATES.BUILDER.PREVIEW.TIMESTAMP')
                }}
              </span>
            </div>
          </div>

          <!-- Buttons (outside the bubble) -->
          <div v-if="validButtons.length > 0" class="mt-1 space-y-1">
            <button
              v-for="(button, index) in validButtons"
              :key="index"
              type="button"
              class="w-full py-2.5 px-3 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2"
              :style="{
                backgroundColor: colors.buttonBg,
                color: colors.linkColor,
              }"
            >
              <i
                v-if="getButtonIcon(button.type)"
                :class="getButtonIcon(button.type)"
                class="text-base"
              />
              <span>{{ button.text }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
