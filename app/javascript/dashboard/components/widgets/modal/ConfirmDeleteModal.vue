<template>
  <modal :show.sync="show" :on-close="closeModal">
    <woot-modal-header :header-title="title" :header-content="message" />
    <form @submit.prevent="onConfirm()">
      <woot-input
        v-model="value"
        type="text"
        :class="{ error: $v.value.$error }"
        :placeholder="cofirmPlaceHolderText"
        @blur="$v.value.$touch"
      />
      <div class="button-wrapper">
        <woot-button
          color-scheme="secondary"
          class="alert nice"
          :disabled="!value || !$v.value.isEqual"
        >
          {{ confirmText }}
        </woot-button>
        <woot-button class="clear" @click.prevent="closeModal">
          {{ rejectText }}
        </woot-button>
      </div>
    </form>
  </modal>
</template>

<script>
import { required } from 'vuelidate/lib/validators';
import Modal from '../../Modal';

export default {
  components: {
    Modal,
  },

  props: {
    show: {
      type: Boolean,
      default: false,
    },
    onClose: {
      type: Function,
      default: () => {},
    },
    onConfirm: {
      type: Function,
      default: () => {},
    },
    title: {
      type: String,
      default: '',
    },
    message: {
      type: String,
      default: '',
    },
    confirmText: {
      type: String,
      default: '',
    },
    rejectText: {
      type: String,
      default: '',
    },
    confirmValue: {
      type: String,
      default: '',
    },
    cofirmPlaceHolderText: {
      type: String,
      default: '',
    },
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
        if (value !== this.confirmValue) {
          return false;
        }
        return true;
      },
    },
  },
  methods: {
    closeModal() {
      this.value = '';
      this.onClose();
    },
  },
};
</script>
