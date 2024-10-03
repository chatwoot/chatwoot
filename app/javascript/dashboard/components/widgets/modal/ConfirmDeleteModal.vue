<script>
import { defineModel } from 'vue';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import Modal from '../../Modal.vue';

export default {
  components: {
    Modal,
  },
  props: {
    title: { type: String, default: '' },
    message: { type: String, default: '' },
    confirmText: { type: String, default: '' },
    rejectText: { type: String, default: '' },
    confirmValue: { type: String, default: '' },
    confirmPlaceHolderText: { type: String, default: '' },
  },
  emits: ['onClose', 'onConfirm'],
  setup() {
    const show = defineModel('show', { type: Boolean, default: false });
    return { v$: useVuelidate(), show };
  },
  data() {
    return {
      value: '',
    };
  },
  validations: {
    value: {
      required,
      isEqual(value) {
        return value === this.confirmValue;
      },
    },
  },
  methods: {
    closeModal() {
      this.value = '';
      this.$emit('onClose');
    },
    onConfirm() {
      this.$emit('onConfirm');
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="closeModal">
    <woot-modal-header :header-title="title" :header-content="message" />
    <form @submit.prevent="onConfirm">
      <woot-input
        v-model="value"
        type="text"
        :class="{ error: v$.value.$error }"
        :placeholder="confirmPlaceHolderText"
        @blur="v$.value.$touch"
      />
      <div class="button-wrapper">
        <woot-button color-scheme="alert" :is-disabled="v$.value.$invalid">
          {{ confirmText }}
        </woot-button>
        <woot-button class="clear" @click.prevent="closeModal">
          {{ rejectText }}
        </woot-button>
      </div>
    </form>
  </Modal>
</template>
