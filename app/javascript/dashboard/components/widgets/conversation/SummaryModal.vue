<template>
  <woot-modal
    modal-type="right-aligned"
    class="text-left"
    show
    :on-close="onClose"
  >
    <div class="content">
      <div v-if="summaryAvailable">
        <p>
          <b>{{ $t('SUMMARY_MODAL.SUMMARY') }}</b>
        </p>
        <p v-dompurify-html="summary.summary" class="mb-0" />
        <br />
        <hr />
        <p>
          <strong>{{ $t('SUMMARY_MODAL.TRANSLATED_SUMMARY') }}:</strong>
        </p>
        <p v-dompurify-html="summary.translated_summary" class="mb-0" />
      </div>
      <div v-else>
        <div v-if="showLoader">
          {{ $t('SUMMARY_MODAL.GENERATING_SUMMARY') }}
        <span class="mt-4 mb-4 spinner" />
        </div>
        <p v-else>
          {{ $t('SUMMARY_MODAL.NO_SUMMARY') }}
        </p>
      </div>
    </div>
  </woot-modal>
</template>
<script>
export default {
  props: {
    summary: {
      type: Object,
      default: () => ({}),
    },
  },
  data: () => ({
    showLoader: true,
  }),
  mounted() {
    setTimeout(() => {
      this.showLoader = false;
    }, 5000);
  },
  computed: {
    summaryAvailable() {
      return !!Object.keys(this.summary).length;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
};
</script>
