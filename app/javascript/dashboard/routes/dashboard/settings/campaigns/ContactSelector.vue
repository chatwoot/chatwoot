<script>
export default {
  name: 'ContactSelector',
  props: {
    contacts: {
      type: Array,
      required: true,
    },
    // selectedContacts: {
    //   type: Array,
    //   default: () => [],
    // },
  },
  data() {
    return {
      searchQuery: '',
      localSelectedContacts: [],
    };
  },
  computed: {
    filteredContacts() {
      return this.contacts.filter(
        contact =>
          contact.name.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
          contact.phone_number.includes(this.searchQuery)
      );
    },
  },
  methods: {
    toggleContact(contact) {
      const index = this.localSelectedContacts.findIndex(
        c => c.id === contact.id
      );
      if (index === -1) {
        this.localSelectedContacts.push(contact);
      } else {
        this.localSelectedContacts.splice(index, 1);
      }
      this.$emit('contactsSelected', this.localSelectedContacts);
    },
    isSelected(contact) {
      return this.localSelectedContacts.some(c => c.id === contact.id);
    },
    selectAll() {
      this.localSelectedContacts = [...this.filteredContacts];
      this.$emit('contactsSelected', this.localSelectedContacts);
    },
    clearSelection() {
      this.localSelectedContacts = [];
      this.$emit('contactsSelected', this.localSelectedContacts);
    },
  },
};
</script>

<template>
  <div class="contact-selector">
    <div class="search-header">
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="$t('CAMPAIGN.CONTACT_SELECTOR.SEARCH_PLACEHOLDER')"
        class="search-input"
      />
      <div class="selection-controls">
        <button @click="selectAll">
          {{ $t('CAMPAIGN.CONTACT_SELECTOR.SELECT_ALL') }}
        </button>
        <button @click="clearSelection">
          {{ $t('CAMPAIGN.CONTACT_SELECTOR.CLEAR') }}
        </button>
      </div>
    </div>
    <div class="contacts-list">
      <div
        v-for="contact in filteredContacts"
        :key="contact.id"
        class="contact-item"
        :class="{ selected: isSelected(contact) }"
        @click="toggleContact(contact)"
      >
        <div class="contact-info">
          <span class="contact-name">{{ contact.name }}</span>
          <span class="contact-phone">{{ contact.phone_number }}</span>
        </div>
        <input type="checkbox" :checked="isSelected(contact)" @click.stop />
      </div>
    </div>
    <div class="selection-summary">
      {{
        $t('CAMPAIGN.CONTACT_SELECTOR.SELECTED_CONTACTS', {
          count: localSelectedContacts.length,
        })
      }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
.contact-selector {
  @apply flex flex-col h-full;

  .search-header {
    @apply flex items-center justify-between p-4 border-b;
    background-color: #343a40; // Dark gray for the header background
    border-color: #495057; // Slightly lighter gray for the border

    .search-input {
      @apply w-64 px-3 py-2 border rounded;
      background-color: #495057; // Darker gray for the input field
      border-color: #6c757d; // Medium gray for the input border
      color: #ffffff; // White text for input
      &::placeholder {
        color: #adb5bd; // Light gray for placeholder text
      }
      &:focus {
        border-color: #17a2b8; // Cyan for focus border
        box-shadow: 0 0 0 0.2rem rgba(23, 162, 184, 0.25); // Cyan shadow for focus
      }
    }

    .selection-controls {
      @apply flex gap-2;

      button {
        @apply px-3 py-1 text-sm border rounded;
        background-color: #495057; // Darker gray for buttons
        border-color: #6c757d; // Medium gray for button border
        color: #ffffff; // White text for buttons
        &:hover {
          background-color: #6c757d; // Slightly lighter gray for hover state
        }
      }
    }
  }

  .contacts-list {
    @apply flex-1 overflow-y-auto;
    background-color: #212529; // Dark gray for the contact list background

    .contact-item {
      @apply flex items-center justify-between p-3 cursor-pointer;
      background-color: #343a40; // Consistent gray background for all contacts
      border-bottom: 1px solid #495057; // Medium gray for borders

      &:hover {
        background-color: #495057; // Lighter gray for hover state
      }

      .contact-info {
        @apply flex flex-col;

        .contact-name {
          @apply font-medium;
          color: #ffffff; // White for contact names
        }

        .contact-phone {
          @apply text-sm;
          color: #adb5bd; // Muted light gray for phone numbers
        }
      }

      input[type='checkbox'] {
        @apply cursor-pointer;
        accent-color: #17a2b8; // Cyan checkbox to indicate selection
      }
    }
  }

  .selection-summary {
    @apply p-4 text-sm font-medium border-t;
    background-color: #343a40; // Dark gray for the summary background
    color: #ffffff; // White text for the summary
    border-color: #495057; // Medium gray for the border
  }
}
</style>
