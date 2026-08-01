<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { content, contentAttributes } = useMessageContext();

const header = computed(() => contentAttributes.value.header || {});
const action = computed(() => contentAttributes.value.action || {});
const sections = computed(() => contentAttributes.value.sections || []);

const bodyText = computed(
  () =>
    contentAttributes.value.bodyText ||
    contentAttributes.value.body_text ||
    content.value ||
    ''
);

const footerText = computed(
  () =>
    contentAttributes.value.footerText ||
    contentAttributes.value.footer_text ||
    ''
);
</script>

<template>
  <BaseBubble class="p-0 overflow-hidden" data-bubble-name="interactive-list">
    <div class="w-[22rem] max-w-full">
      <div class="px-4 pt-4 pb-3 flex flex-col gap-3">
        <h4 v-if="header.text" class="text-xl font-semibold text-n-slate-12">
          {{ header.text }}
        </h4>
        <p
          v-if="bodyText"
          v-dompurify-html="bodyText"
          class="prose prose-bubble text-base font-medium"
        />
        <p v-if="footerText" class="text-sm text-n-slate-11">
          {{ footerText }}
        </p>
      </div>

      <div
        class="flex items-center justify-center gap-2 border-y border-n-container px-4 py-3 text-n-teal-11 font-medium"
      >
        <Icon icon="i-lucide-list" class="size-4" />
        <span>{{ action.buttonText || action.button_text }}</span>
      </div>

      <div class="bg-n-alpha-1 px-4 py-3 flex flex-col gap-4">
        <div
          v-for="(section, sectionIndex) in sections"
          :key="`${section.title || 'section'}-${sectionIndex}`"
          class="flex flex-col gap-2"
        >
          <p v-if="section.title" class="text-sm font-semibold text-n-slate-11">
            {{ section.title }}
          </p>
          <div class="rounded-xl border border-n-container bg-n-background">
            <div
              v-for="(row, rowIndex) in section.rows || []"
              :key="`${row.id || row.title}-${rowIndex}`"
              class="px-4 py-3 flex flex-col gap-1"
              :class="{
                'border-b border-n-container':
                  rowIndex !== (section.rows || []).length - 1,
              }"
            >
              <p class="font-medium text-n-slate-12">
                {{ row.title }}
              </p>
              <p v-if="row.description" class="text-sm text-n-slate-11">
                {{ row.description }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
