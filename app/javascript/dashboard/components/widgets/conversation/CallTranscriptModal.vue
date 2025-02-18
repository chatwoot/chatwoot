<template>
  <woot-modal :show="show" :on-close="onCancel" :full-height="false">
    <woot-modal-header :header-title="'Transcript'" />
    <div class="flex flex-col p-8 pt-4">
      <div
        class="w-full relative rounded-md p-3 border border-solid border-slate-100 dark:border-slate-700"
      >
        <div class="flex justify-between items-center text-xs">
          <span>{{ readableTime }}</span>
          <span class="flex items-center gap-1.5">
            <fluent-icon
              :icon="'timer'"
              class="text-slate-600 dark:text-slate-400"
              size="12"
            />
            {{ formattedDuration }}
            <woot-button
              :class="'!h-6'"
              variant="smooth"
              @click="downloadTranscript"
            >
              {{ 'Download Transcript' }}
            </woot-button>
          </span>
        </div>
        <p
          class="text-sm p-2 rounded-md mt-3 max-h-80 overflow-y-scroll bg-slate-25 dark:bg-slate-800"
        >
          {{ callTranscript }}
        </p>
      </div>
    </div>
  </woot-modal>
</template>

<script>
export default {
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    callTranscript: {
      type: String,
      required: true,
    },
    readableTime: {
      type: String,
      required: true,
    },
    formattedDuration: {
      type: String,
      required: true,
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    downloadTranscript() {
      const transcript = this.callTranscript;
      const blob = new Blob(
        [
          `Date: ${this.readableTime}\n\nDuration: ${this.formattedDuration}\n\nTranscript: \n\n${transcript}`,
        ],
        {
          type: 'text/plain',
        }
      );
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'transcript.txt';
      a.click();
      URL.revokeObjectURL(url);
    },
  },
};
</script>
