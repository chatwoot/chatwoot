<script>
import Modal from 'dashboard/components/Modal.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

export default {
  components: {
    Modal,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    isCreating: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['create', 'cancel', 'update:show'],
  setup() {
    return { v$: useVuelidate() };
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
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
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
  <Modal v-model:show="localShow" :on-close="onClose">
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
        @blur="v$.attributeName.$touch"
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
