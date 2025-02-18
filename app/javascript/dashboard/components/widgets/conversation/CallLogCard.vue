<template>
  <div
    class="border border-solid border-slate-100 dark:border-slate-700 rounded-md p-2 flex flex-col gap-2"
  >
    <div class="flex justify-between items-center">
      <p class="mb-0 text-xs">Call Summary</p>
      <div class="flex gap-2">
        <woot-button
          v-if="callLog.transcript"
          variant="smooth"
          icon="closed-caption"
          size="large"
          :class="'p-0 !h-6 !w-7'"
          @click="toggleTranscriptModal"
        />
        <a
          v-if="callLog.recordingLink"
          :href="callLog.recordingLink"
          target="_blank"
        >
          <woot-button :class="'!h-6 text-xs'" variant="smooth">
            {{ 'See Recording' }}
          </woot-button>
        </a>
      </div>
    </div>
    <div
      class="w-full relative bg-slate-25 dark:bg-slate-800 rounded-md px-2 py-1"
    >
      <div class="flex justify-between items-center text-[10px]">
        <span>{{ readableTime }}</span>
        <div class="flex gap-3 items-center">
          <span>{{ callLog.callStatus }}</span>
          <span class="flex items-center text-[10px] gap-1.5">
            <fluent-icon
              :icon="'timer'"
              class="text-slate-600 dark:text-slate-400"
              size="12"
            />
            {{ formattedDuration }}
          </span>
        </div>
      </div>
      <p
        v-if="callLog.summary"
        class="text-xs mr-4 mt-2 max-h-32 overflow-y-scroll"
      >
        {{
          isExpanded ? callLog.summary : `${callLog.summary.slice(0, 100)}...`
        }}
      </p>
      <woot-button
        v-if="callLog.summary"
        variant="smooth"
        size="tiny"
        class="text-slate-600 dark:text-slate-400 absolute bottom-0 right-0 mr-1 mb-1 cursor-pointer"
        :icon="isExpanded ? 'subtract' : 'add'"
        @click="toggleSummary"
      />
    </div>
    <div class="flex gap-2">
      <woot-button
        v-if="callLog.category"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        :class="'!h-6'"
      >
        {{ callLog.category }}
      </woot-button>
      <woot-button
        v-if="callLog.sentiment"
        color-scheme="secondary"
        variant="smooth"
        size="small"
        :class="'!h-6'"
      >
        {{ callLog.sentiment }}
      </woot-button>
    </div>
    <call-transcript-modal
      v-if="showTranscriptModal"
      :show="showTranscriptModal"
      :call-transcript="callLog.transcript"
      :readable-time="readableTime"
      :formatted-duration="formattedDuration"
      @cancel="toggleTranscriptModal"
    />
  </div>
</template>

<script>
import CallTranscriptModal from './CallTranscriptModal.vue';
import timeMixin from '../../../mixins/time';

export default {
  components: {
    CallTranscriptModal,
  },
  mixins: [timeMixin],
  props: {
    callLog: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: false,
      showTranscriptModal: false,
    };
  },
  computed: {
    readableTime() {
      if (!this.callLog.callInitiatedAt) {
        return '';
      }
      try {
        const timestamp = Math.floor(
          new Date(this.callLog.callInitiatedAt).getTime() / 1000
        );
        const date = this.messageTimestamp(timestamp, 'dd MMMM yyyy');
        return `${date}`;
      } catch (error) {
        return 'Invalid date';
      }
    },
    formattedDuration() {
      const seconds = this.callLog.onCallDuration;
      if (!seconds) return '0 sec';
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const remainingSeconds = seconds % 60;
      if (hours > 0) {
        return `${hours} hour${hours > 1 ? 's' : ''} ${
          minutes > 0 ? `${minutes} min` : ''
        }`;
      }
      if (minutes > 0) {
        return `${minutes} min`;
      }
      return `${remainingSeconds} sec`;
    },
  },
  methods: {
    toggleSummary() {
      this.isExpanded = !this.isExpanded;
    },
    toggleTranscriptModal() {
      this.showTranscriptModal = !this.showTranscriptModal;
    },
  },
};
</script>
