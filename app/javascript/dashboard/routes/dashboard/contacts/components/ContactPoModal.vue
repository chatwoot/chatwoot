<!-- eslint-disable vue/no-mutating-props -->
<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="
          $t('CONTACT_PO.HEADER.TITLE', { name: currentContact.name })
        "
        :header-content="$t('CONTACT_PO.HEADER.CONTENT')"
      />
      <form class="conversation--form w-full" @submit.prevent="onFormSubmit">
        <contact-po-form
          ref="contactPoForm"
          :current-contact="currentContact"
          @contact-data-changed="onContactChanged"
        />
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <button class="button clear" @click.prevent="onCancel">
            {{ $t('CONTACT_PO.BUTTON.CANCEL') }}
          </button>
          <woot-button type="submit">
            {{ $t('CONTACT_PO.BUTTON.SUBMIT') }}
          </woot-button>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import ContactPoForm from './ContactPoForm.vue';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';

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
    contactId: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      contactItem: Object,
    };
  },
  computed: {
    currentContact() {
      return this.$store.getters['contacts/getContact'](this.contactId);
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    onContactChanged(contactItem) {
      this.contactItem = contactItem;
    },
    onFormSubmit() {
      this.$refs.contactPoForm.$v.$touch();
      if (this.$refs.contactPoForm.$v.$invalid) {
        return;
      }
      try {
        this.$store.dispatch('contacts/update', this.contactItem).then(() => {
          this.showAlert(this.$t('CONTACT_PO.MESSAGE.SUCCESS'));
          this.onSuccess();
        });
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('CONTACT_PO.MESSAGE.ERROR'));
        }
      }
    },
  },
};
</script>
