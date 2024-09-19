<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <woot-modal-header
      :header-title="
        $t('CONVERSATION.CONTACT_STAGE.TITLE', { name: currentContact.name })
      "
      :header-content="$t('CONVERSATION.CONTACT_STAGE.DESCRIPTION')"
    />
    <form @submit.prevent="onSubmit">
      <div class="gap-2 flex flex-row">
        <div class="w-[50%]">
          <label>
            {{ $t('CONVERSATION.CONTACT_STAGE.STAGE') }}
          </label>
          <div class="multiselect-wrap--small">
            <multiselect
              v-model="currentContact.stage"
              disabled
              :options="stages"
              :show-labels="false"
              label="name"
              track-by="id"
            />
          </div>
        </div>
        <div class="w-[50%]">
          <label>
            {{ $t('CONVERSATION.CONTACT_STAGE.NEW_STAGE') }}
          </label>
          <div
            class="multiselect-wrap--small"
            :class="{ 'has-multi-select-error': $v.newStage.$error }"
          >
            <multiselect
              v-model="newStage"
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
          <label :class="{ error: $v.newStage.$error }">
            <span v-if="$v.newStage.$error" class="message">
              {{ $t('CONVERSATION.CONTACT_STAGE.STAGE_ERROR') }}
            </span>
          </label>
        </div>
      </div>
      <contact-po-form
        v-show="newStage && newStage.code == 'Won'"
        ref="contactPoForm"
        :current-contact="currentContact"
        @contact-data-changed="onContactChanged"
      />
      <div class="mt-6 flex gap-2 justify-end">
        <woot-button variant="clear" @click.prevent="onClose">
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
import alertMixin from 'shared/mixins/alertMixin';
import ContactPoForm from '../contacts/components/ContactPoForm.vue';

export default {
  components: {
    ContactPoForm,
  },
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      newStage: null,
      contactItem: Object,
    };
  },
  validations: {
    newStage: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      stages: 'stages/getEnabledStages',
    }),
    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.currentChat.meta.sender.id
      );
    },
  },
  mounted() {
    this.$store.dispatch('stages/get');
  },
  methods: {
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      if (this.newStage.code === 'Won') {
        this.$refs.contactPoForm.$v.$touch();
        if (this.$refs.contactPoForm.$v.$invalid) {
          return;
        }
      }
      if (this.currentContact.stage.id === this.newStage.id) {
        return;
      }
      let contactItem = {
        id: this.currentContact.id,
        stage_id: this.newStage.id,
      };
      if (this.newStage.code === 'Won') {
        contactItem = {
          ...contactItem,
          ...this.contactItem,
        };
      }
      this.$store.dispatch('contacts/update', contactItem).then(() => {
        this.showAlert(this.$t('CONVERSATION.CONTACT_STAGE.CHANGE_STAGE'));
        this.onClose();
      });
    },
    onClose() {
      this.$emit('close');
    },
    onContactChanged(contactItem) {
      this.contactItem = contactItem;
    },
  },
};
</script>
