<script>
import { defineModel } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

export default {
  components: {
    Modal,
  },
  props: {
    isCreating: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['create', 'cancel'],
  setup() {
    const show = defineModel('show', { type: Boolean, default: false });
    return { v$: useVuelidate(), show };
  },
  data() {
    return {
      attributeValue: '',
      attributeName: '',
    };
  },
  validations: {
    attributeName: {
      required,
      minLength: minLength(2),
    },
  },
  computed: {
    attributeNameError() {
      if (this.v$.attributeName.$error) {
        return this.$t('CUSTOM_ATTRIBUTES.FORM.NAME.ERROR');
      }
      return '';
    },
  },
  methods: {
    addCustomAttribute() {
      this.$emit('create', {
        attributeValue: this.attributeValue,
        attributeName: this.attributeName || '',
      });
      this.reset();
      this.$emit('cancel');
    },
    onClose() {
      this.reset();
      this.$emit('cancel');
    },
    reset() {
      this.attributeValue = '';
      this.attributeName = '';
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('CUSTOM_ATTRIBUTES.ADD.TITLE')"
      :header-content="$t('CUSTOM_ATTRIBUTES.ADD.DESC')"
    />
    <form class="w-full" @submit.prevent="addCustomAttribute">
      <woot-input
        v-model="attributeName"
        :class="{ error: v$.attributeName.$error }"
        class="w-full"
        :error="attributeNameError"
        :label="$t('CUSTOM_ATTRIBUTES.FORM.NAME.LABEL')"
        :placeholder="$t('CUSTOM_ATTRIBUTES.FORM.NAME.PLACEHOLDER')"
        @input="v$.attributeName.$touch"
      />
      <woot-input
        v-model="attributeValue"
        class="w-full"
        :label="$t('CUSTOM_ATTRIBUTES.FORM.VALUE.LABEL')"
        :placeholder="$t('CUSTOM_ATTRIBUTES.FORM.VALUE.PLACEHOLDER')"
      />
      <div class="flex items-center justify-end gap-2 px-0 py-2">
        <woot-button
          :is-disabled="v$.attributeName.$invalid || isCreating"
          :is-loading="isCreating"
        >
          {{ $t('CUSTOM_ATTRIBUTES.FORM.CREATE') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CUSTOM_ATTRIBUTES.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </Modal>
</template>
