<template>
  <woot-modal
    modal-type="right-aligned"
    class="text-left"
    show
    :on-close="onClose"
  >
    <div class="column content">
      <p>
        <b>{{ $t('TRANSLATE_MODAL.ORIGINAL_CONTENT') }}</b>
      </p>
      <p v-dompurify-html="content" />
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
      <p v-else>
        {{ $t('TRANSLATE_MODAL.NO_TRANSLATIONS_AVAILABLE') }}
      </p>
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
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
};
</script>
