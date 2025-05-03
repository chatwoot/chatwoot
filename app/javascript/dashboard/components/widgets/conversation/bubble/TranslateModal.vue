<template>
  <woot-modal
    modal-type="right-aligned"
    class="text-left"
    show
    :on-close="onClose"
  >
    <div class="content">
      <p>
        <b>{{ $t('TRANSLATE_MODAL.ORIGINAL_CONTENT') }}</b>
      </p>
      <p v-dompurify-html="content" class="mb-0" />
      <br />
      <hr />
      <div v-if="translationsAvailable">
        <p>
          <b>{{ $t('TRANSLATE_MODAL.TRANSLATED_CONTENT') }}</b>
        </p>
        <div v-for="(translation, language) in translations" :key="language">
          <p>
            <strong>{{ language }}:</strong>
          </p>
          <p v-dompurify-html="translation" />
          <br />
        </div>
      </div>
      <div v-else>
        <div v-if="showLoader">
          {{ $t('TRANSLATE_MODAL.LOADING_TRANSLATIONS') }}
          <span class="mt-4 mb-4 spinner" />
        </div>
        <p v-else>
          {{ $t('TRANSLATE_MODAL.NO_TRANSLATIONS_AVAILABLE') }}
        </p>
      </div>
    </div>
  </woot-modal>
</template>
<script>
export default {
  props: {
    contentAttributes: {
      type: Object,
      default: () => ({}),
    },
    content: {
      type: String,
      default: '',
    },
  },
  computed: {
    translationsAvailable() {
      return !!Object.keys(this.translations).length;
    },
    translations() {
      return this.contentAttributes.translations || {};
    },
  },
  data: () => ({
    showLoader: true,
  }),
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  watch: {
    translations(newTranslations) {
      if (newTranslations && Object.keys(newTranslations).length) {
        this.showLoader = false;
      }
    },
  },
};
</script>
