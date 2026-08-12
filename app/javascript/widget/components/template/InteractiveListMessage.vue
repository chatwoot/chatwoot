<script setup>
import { computed } from 'vue';
import { IFrameHelper } from 'widget/helpers/utils';

const props = defineProps({
  message: {
    type: String,
    default: '',
  },
  messageContentAttributes: {
    type: Object,
    default: () => ({}),
  },
});

const headerText = computed(
  () => props.messageContentAttributes.header?.text || ''
);
const bodyText = computed(
  () => props.messageContentAttributes.body_text || props.message
);
const footerText = computed(
  () => props.messageContentAttributes.footer_text || ''
);
const buttonText = computed(
  () => props.messageContentAttributes.action?.button_text || ''
);
const sections = computed(() => props.messageContentAttributes.sections || []);
const onRowClick = row => {
  if (!IFrameHelper.isIFrame()) return;

  IFrameHelper.sendMessage({
    event: 'postback',
    data: { payload: row.id },
  });
};
</script>

<template>
  <div class="flex flex-col gap-3 max-w-80">
    <div
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12 rounded-lg overflow-hidden"
    >
      <div class="px-4 pt-4 pb-3">
        <p v-if="headerText" class="text-xl font-semibold text-n-slate-12">
          {{ headerText }}
        </p>
        <p class="mt-3 text-base font-medium text-n-slate-12">
          {{ bodyText }}
        </p>
        <p v-if="footerText" class="mt-2 text-sm text-n-slate-11">
          {{ footerText }}
        </p>
      </div>

      <div
        class="border-t border-n-strong px-4 py-3 flex items-center justify-center text-n-brand font-medium"
      >
        {{ buttonText }}
      </div>
    </div>

    <div
      class="chat-bubble agent bg-n-background dark:bg-n-solid-3 text-n-slate-12 rounded-lg p-4 flex flex-col gap-4"
    >
      <div
        v-for="(section, sectionIndex) in sections"
        :key="`${section.title || 'section'}-${sectionIndex}`"
        class="flex flex-col gap-2"
      >
        <p v-if="section.title" class="text-sm font-semibold text-n-slate-11">
          {{ section.title }}
        </p>
        <div class="rounded-lg border border-n-strong overflow-hidden">
          <button
            v-for="(row, rowIndex) in section.rows || []"
            :key="`${row.id || row.title}-${rowIndex}`"
            type="button"
            class="w-full text-left px-4 py-3"
            :class="{
              'border-b border-n-strong':
                rowIndex !== (section.rows || []).length - 1,
            }"
            @click="onRowClick(row)"
          >
            <p class="font-medium text-n-slate-12">
              {{ row.title }}
            </p>
            <p v-if="row.description" class="mt-1 text-sm text-n-slate-11">
              {{ row.description }}
            </p>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
