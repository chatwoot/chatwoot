<script>
export default {
  props: {
    message: {
      type: String,
      default: '',
    },
    messageContentAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
  computed: {
    headerText() {
      return this.messageContentAttributes.header?.text || '';
    },
    bodyText() {
      return this.messageContentAttributes.body_text || this.message;
    },
    footerText() {
      return this.messageContentAttributes.footer_text || '';
    },
    buttonText() {
      return this.messageContentAttributes.action?.button_text || '';
    },
    sections() {
      return this.messageContentAttributes.sections || [];
    },
  },
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
          <div
            v-for="(row, rowIndex) in section.rows || []"
            :key="`${row.id || row.title}-${rowIndex}`"
            class="px-4 py-3"
            :class="{
              'border-b border-n-strong':
                rowIndex !== (section.rows || []).length - 1,
            }"
          >
            <p class="font-medium text-n-slate-12">
              {{ row.title }}
            </p>
            <p v-if="row.description" class="mt-1 text-sm text-n-slate-11">
              {{ row.description }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
