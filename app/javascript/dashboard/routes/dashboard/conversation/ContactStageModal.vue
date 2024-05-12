<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION.CONTACT_STAGE.TITLE')"
      :header-content="$t('CONVERSATION.CONTACT_STAGE.DESCRIPTION')"
    />
    <form @submit.prevent="onSubmit">
      <div>
        <label>
          {{ $t('CONVERSATION.CONTACT_STAGE.STAGE') }}
        </label>
        <div
          class="multiselect-wrap--small"
          :class="{ 'has-multi-select-error': $v.stage.$error }"
        >
          <multiselect
            v-model="stage"
            class="no-margin"
            placeholder=""
            label="name"
            track-by="id"
            :options="stages"
            :max-height="160"
            :close-on-select="true"
            :show-labels="false"
          />
        </div>
        <label :class="{ error: $v.stage.$error }">
          <span v-if="$v.stage.$error" class="message">
            {{ $t('CONVERSATION.CONTACT_STAGE.STAGE_ERROR') }}
          </span>
        </label>
      </div>
      <div class="mt-6 flex gap-2 justify-end">
        <woot-button variant="clear" @click.prevent="onCancel">
          {{ $t('CONVERSATION.CONTACT_STAGE.CANCEL') }}
        </woot-button>
        <woot-button type="submit">
          {{ $t('CONVERSATION.CONTACT_STAGE.SUBMIT') }}
        </woot-button>
      </div>
    </form>
  </woot-modal>
</template>

<script>
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';

export default {
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      stage: null,
    };
  },
  validations: {
    stage: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      stages: 'stages/getStages',
    }),
  },
  mounted() {
    this.stage = this.contact.stage;
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$emit('submit', this.parentContact.id);
    },
    onCancel() {
      this.$emit('cancel');
    },
  },
};
</script>
