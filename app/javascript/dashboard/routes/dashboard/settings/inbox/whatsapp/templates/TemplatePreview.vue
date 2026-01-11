<script setup lang="ts">
import { computed } from 'vue';
import { renderWithExamples } from './utils/placeholders';
import type { HeaderFormat, ButtonType } from './validators/metaTemplateRules';

interface Props {
  headerFormat: HeaderFormat | null;
  headerText: string;
  headerTextExample: string;
  headerMediaUrl: string;
  bodyText: string;
  bodyExamples: string[];
  footerText: string;
  buttons: Array<{
    type: ButtonType;
    text?: string;
    url?: string;
    urlExample?: string;
    phoneNumber?: string;
  }>;
}

const props = defineProps<Props>();

const renderedHeaderText = computed(() => {
  if (props.headerFormat !== 'TEXT' || !props.headerText) return '';
  return renderWithExamples(props.headerText, props.headerTextExample ? [props.headerTextExample] : []);
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
        const urlWithExample = renderWithExamples(button.url, button.urlExample ? [button.urlExample] : []);
        return { ...button, displayUrl: urlWithExample };
      }
      if (button.type === 'COPY_CODE') {
        return { ...button, text: 'Copy code' };
      }
      return button;
    });
});

const hasContent = computed(() => {
  return props.headerFormat || props.bodyText || props.footerText || validButtons.value.length > 0;
});

const getButtonIcon = (type: ButtonType) => {
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
  <div class="bg-n-slate-2 rounded-xl p-4 min-h-[400px]">
    <!-- Phone frame mockup -->
    <div class="bg-[#0b141a] rounded-lg overflow-hidden shadow-xl">
      <!-- WhatsApp header -->
      <div class="bg-[#202c33] px-4 py-3 flex items-center gap-3">
        <div class="w-8 h-8 rounded-full bg-[#00a884] flex items-center justify-center">
          <i class="i-lucide-building-2 text-white text-sm" />
        </div>
        <div class="flex-1">
          <p class="text-white text-sm font-medium">Business</p>
          <p class="text-[#8696a0] text-xs">WhatsApp Business</p>
        </div>
      </div>

      <!-- Chat area -->
      <div class="bg-[#0b141a] p-4 min-h-[300px]" style="background-image: url('data:image/svg+xml,%3Csvg width=&quot;60&quot; height=&quot;60&quot; xmlns=&quot;http://www.w3.org/2000/svg&quot;%3E%3Cdefs%3E%3Cpattern id=&quot;grid&quot; width=&quot;60&quot; height=&quot;60&quot; patternUnits=&quot;userSpaceOnUse&quot;%3E%3Cpath d=&quot;M 60 0 L 0 0 0 60&quot; fill=&quot;none&quot; stroke=&quot;%23172025&quot; stroke-width=&quot;0.5&quot;/%3E%3C/pattern%3E%3C/defs%3E%3Crect width=&quot;100%25&quot; height=&quot;100%25&quot; fill=&quot;url(%23grid)&quot;/%3E%3C/svg%3E');">
        <!-- Empty state -->
        <div v-if="!hasContent" class="flex flex-col items-center justify-center h-64 text-center">
          <i class="i-lucide-message-square-dashed text-4xl text-[#8696a0] mb-3" />
          <p class="text-[#8696a0] text-sm">Template preview</p>
          <p class="text-[#667781] text-xs mt-1">Fill in the form to see preview</p>
        </div>

        <!-- Message bubble -->
        <div v-else class="max-w-[85%]">
          <div class="bg-[#005c4b] rounded-lg overflow-hidden shadow-md">
            <!-- Header -->
            <div v-if="headerFormat">
              <!-- Text Header -->
              <div v-if="headerFormat === 'TEXT' && (renderedHeaderText || headerText)" class="px-3 pt-2">
                <p class="text-white text-sm font-semibold">
                  {{ renderedHeaderText || headerText }}
                </p>
              </div>

              <!-- Image Header -->
              <div v-else-if="headerFormat === 'IMAGE'" class="bg-[#1d3c34]">
                <div class="aspect-video flex items-center justify-center">
                  <div v-if="headerMediaUrl" class="text-center">
                    <i class="i-lucide-image text-4xl text-[#00a884]" />
                  </div>
                  <div v-else class="text-center">
                    <i class="i-lucide-image-off text-3xl text-[#667781]" />
                    <p class="text-[#667781] text-xs mt-1">No image</p>
                  </div>
                </div>
              </div>

              <!-- Video Header -->
              <div v-else-if="headerFormat === 'VIDEO'" class="bg-[#1d3c34]">
                <div class="aspect-video flex items-center justify-center">
                  <div v-if="headerMediaUrl" class="text-center">
                    <div class="w-12 h-12 rounded-full bg-[#00a884]/20 flex items-center justify-center mb-2">
                      <i class="i-lucide-play text-2xl text-[#00a884]" />
                    </div>
                  </div>
                  <div v-else class="text-center">
                    <i class="i-lucide-video-off text-3xl text-[#667781]" />
                    <p class="text-[#667781] text-xs mt-1">No video</p>
                  </div>
                </div>
              </div>

              <!-- Document Header -->
              <div v-else-if="headerFormat === 'DOCUMENT'" class="bg-[#1d3c34] p-3">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded bg-[#00a884]/20 flex items-center justify-center">
                    <i class="i-lucide-file-text text-xl text-[#00a884]" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-white text-sm font-medium truncate">Document.pdf</p>
                    <p class="text-[#8696a0] text-xs">PDF • 1 page</p>
                  </div>
                </div>
              </div>

              <!-- Location Header -->
              <div v-else-if="headerFormat === 'LOCATION'" class="bg-[#1d3c34]">
                <div class="aspect-video flex items-center justify-center">
                  <div class="text-center">
                    <i class="i-lucide-map-pin text-4xl text-[#00a884]" />
                    <p class="text-[#8696a0] text-xs mt-2">Location</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Body -->
            <div class="px-3 py-2">
              <p class="text-white text-sm whitespace-pre-wrap leading-relaxed">{{ renderedBodyText || 'Message body...' }}</p>
            </div>

            <!-- Footer -->
            <div v-if="footerText" class="px-3 pb-1">
              <p class="text-[#8696a0] text-xs">{{ footerText }}</p>
            </div>

            <!-- Timestamp -->
            <div class="px-3 pb-2 flex justify-end">
              <span class="text-[#8696a0] text-[10px]">12:00</span>
            </div>
          </div>

          <!-- Buttons (outside the bubble) -->
          <div v-if="validButtons.length > 0" class="mt-1 space-y-1">
            <button
              v-for="(button, index) in validButtons"
              :key="index"
              type="button"
              class="w-full py-2.5 px-3 rounded-lg bg-[#202c33] text-sm font-medium text-[#53bdeb] hover:bg-[#2a3942] transition-colors flex items-center justify-center gap-2"
            >
              <i v-if="getButtonIcon(button.type)" :class="getButtonIcon(button.type)" class="text-base" />
              <span>{{ button.text }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
