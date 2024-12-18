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
    @apply flex items-center justify-between p-4 border-b 
           bg-white dark:bg-slate-800 
           border-slate-200 dark:border-slate-700;

    .search-input {
      @apply w-64 px-3 py-2 border rounded
             bg-white dark:bg-slate-700 
             border-slate-300 dark:border-slate-600
             text-slate-900 dark:text-white
             placeholder-slate-500 dark:placeholder-slate-400;
      &:focus {
        border-color: #17a2b8; // Cyan for focus border
        box-shadow: 0 0 0 0.2rem rgba(23, 162, 184, 0.25); // Cyan shadow for focus
      }
    }

    .selection-controls {
      @apply flex gap-2;

      button {
        @apply px-3 py-1 text-sm border rounded
               bg-white dark:bg-slate-700
               border-slate-300 dark:border-slate-600
               text-slate-700 dark:text-white
               hover:bg-slate-50 hover:dark:bg-slate-600;
      }
    }
  }

  .contacts-list {
    @apply flex-1 overflow-y-auto bg-white dark:bg-slate-900;
    max-height: 300px; /* Set a max-height to fix modal size */
    overflow-y: auto; /* Add scrollbar when content overflows */
    border-bottom: 1px solid #e2e8f0; /* Optional: a bottom border for clarity */

    .contact-item {
      @apply flex items-center justify-between p-3 cursor-pointer
           bg-white dark:bg-slate-800 
           border-b border-slate-100 dark:border-slate-700
           hover:bg-slate-50 hover:dark:bg-slate-700;

      .contact-info {
        @apply flex flex-col;

        .contact-name {
          @apply font-medium text-slate-900 dark:text-white;
        }

        .contact-phone {
          @apply text-sm text-slate-600 dark:text-slate-400;
        }
      }

      input[type='checkbox'] {
        @apply cursor-pointer;
        accent-color: #17a2b8;
      }
    }
  }

  .selection-summary {
    @apply p-4 text-sm font-medium border-t
           bg-white dark:bg-slate-800
           text-slate-700 dark:text-white
           border-slate-200 dark:border-slate-700;
  }
}
</style>
