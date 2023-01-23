<template>
  <div class="contact message-text__wrap">
    <div class="icon-wrap">
      <fluent-icon icon="book-contacts" class="file--icon" size="32" />
    </div>
    <div class="meta">
      <h5 class="text-block-title text-truncate">
        {{ phoneNumber }}
      </h5>
      <div v-if="number" class="link-wrap">
        <a
          class="clear link button small"
          href="#"
          @click.prevent="addContact"
        >
          {{ $t('CREATE_CONTACT.BUTTON_LABEL') }}
        </a>
      </div>
    </div>
  </div>
</template>

<script>
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    name: {
      type: String,
    },
    phoneNumber: {
      type: String
    },
  },
  computed: {
    number() {
      return this.phoneNumber.replace(/\s|-|[A-Za-z]/g, '');
    }
  },
  methods: {
    async addContact() {
      try {
        var contact = await this.filterContactByNumber(this.number.replace('+',''));
        if (contact === undefined) {
          contact = await this.$store.dispatch('contacts/create', this.getContactObject());
          this.showAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
        }
        this.openContactNewTab(contact.id);
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          if (error.data.includes('phone_number')) {
            this.showAlert(this.$t('CONTACT_FORM.FORM.PHONE_NUMBER.DUPLICATE'));
          }
        } else if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
    getContactObject() {
      const contactItem = {
        name: this.name,
        phone_number: this.number
      };
      return contactItem;
    },
    async filterContactByNumber(phoneNumber) {
      const query = {
        attribute_key:"phone_number",
        filter_operator:"equal_to",
        values:[phoneNumber],
        attribute_model:"standard",
        custom_attribute_type:""
      };

      const queryPayload = { payload: [query] };
      const contacts = await this.$store.dispatch('contacts/filter', { queryPayload });
      return contacts.shift();
    },
    openContactNewTab(contactId) {
      const accountId = window.location.pathname.split('/')[3];
      const url = `/app/accounts/${accountId}/contacts/${contactId}`;
      window.open(url, '_blank');
    }
  }
};
</script>

<style lang="scss" scoped>
.contact {
  display: flex;
  flex-direction: row;
  padding: var(--space-smaller) 0;
  border-top: 1px solid #414145;
  padding-top: 0.6rem;
  margin-top: 0.6rem;
  cursor: pointer;

  .icon-wrap {
    color: var(--s-600);
    line-height: 1;
    margin: 0 var(--space-smaller);
  }

  .text-block-title {
    margin: 0;
    color: var(--s-800);
    word-break: break-word;
    margin-right: 4rem;
  }

  .meta {
    display: flex;
    align-items: center;
    padding-right: 5px;
  }

  .link-wrap {
    display: flex;
  }
}
</style>
