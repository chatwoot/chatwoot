<template>
  <div class="dropdown-search-wrap">
    <h4 class="text-block-title">
      {{ $t('CONVERSATION_CUSTOM_ATTRIBUTES.ATTRIBUTE_SELECT.TITLE') }}
    </h4>
    <div class="search-wrap">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="
          $t('CONVERSATION_CUSTOM_ATTRIBUTES.ATTRIBUTE_SELECT.PLACEHOLDER')
        "
      />
    </div>
    <div class="list-wrap">
      <div class="list">
        <woot-dropdown-menu>
          <attribute-drop-down-item
            v-for="label in filteredAttributes"
            :key="label.title"
            :title="label.title"
            :color="label.color"
            :icon="label.icon"
            :selected="selectedLabels.includes(label.title)"
            @click="onAddRemove(label)"
          />
        </woot-dropdown-menu>
        <div v-if="noResult" class="no-result">
          {{ $t('CONVERSATION_CUSTOM_ATTRIBUTES.ATTRIBUTE_SELECT.NO_RESULT') }}
        </div>
        <woot-button
          variant="hollow"
          class="add"
          icon="ion-plus-round"
          size="tiny"
          @click="addNewAttribute"
        >
          {{ $t('CONVERSATION_CUSTOM_ATTRIBUTES.ADD.TITLE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import AttributeDropDownItem from './AttributeDropDownItem.vue';
import { mapGetters } from 'vuex';
export default {
  components: {
    AttributeDropDownItem,
  },
  props: {
    accountLabels: {
      type: Array,
      default: () => [],
    },
    selectedLabels: {
      type: Array,
      default: () => [],
    },
  },

  data() {
    return {
      search: '',
    };
  },

  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      currentChat: 'getSelectedChat',
    }),
    attributes() {
      return this.$store.getters['attributes/getAttributesByModel'](
        'conversation_attribute'
      );
    },
    conversationCustomAttributes() {
      return this.currentChat.custom_attributes || {};
    },

    filteredAttributes() {
      const mappedAttributes = this.attributes.map(item => ({
        id: item.id,
        title: item.attribute_display_name,
        attribute_key: item.attribute_key,
        icon: this.attributeIcon(item.attribute_display_type),
      }));

      const filteredAttributes = mappedAttributes.filter(
        item =>
          !Object.keys(this.conversationCustomAttributes).includes(
            item.attribute_key
          )
      );

      return filteredAttributes.filter(attribute => {
        return attribute.title
          .toLowerCase()
          .includes(this.search.toLowerCase());
      });
    },

    noResult() {
      return this.filteredAttributes.length === 0 && this.search !== '';
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    attributeIcon(type) {
      switch (type) {
        case 'date':
          return 'ion-calendar';
        case 'link':
          return 'ion-link';
        case 'currency':
          return 'ion-social-usd';
        case 'number':
          return 'ion-android-call';
        case 'percent':
          return 'ion-calculator';
        default:
          return 'ion-edit';
      }
    },
    focusInput() {
      this.$refs.searchbar.focus();
    },

    updateLabels(label) {
      this.$emit('update', label);
    },

    onAdd(label) {
      this.$emit('add', label);
    },

    onRemove(label) {
      this.$emit('remove', label);
    },
    addNewAttribute() {
      this.$router.push(
        `/app/accounts/${this.accountId}/settings/attributes/list`
      );
    },
    async onAddRemove(attribute) {
      this.$emit('add-attribute', attribute);
    },
  },
};
</script>

<style lang="scss" scoped>
.dropdown-search-wrap {
  display: flex;
  flex-direction: column;
  width: 100%;
  max-height: 20rem;

  .search-wrap {
    margin-bottom: var(--space-small);
    flex: 0 0 auto;
    max-height: var(--space-large);

    .search-input {
      margin: 0;
      width: 100%;
      border: 1px solid transparent;
      height: var(--space-large);
      font-size: var(--font-size-small);
      padding: var(--space-small);
      background-color: var(--color-background);
    }

    input:focus {
      border: 1px solid var(--w-500);
    }
  }

  .list-wrap {
    display: flex;
    justify-content: flex-start;
    align-items: flex-start;
    flex: 1 1 auto;
    overflow: auto;

    .list {
      width: 100%;
      .add {
        float: right;
      }
    }

    .no-result {
      display: flex;
      justify-content: center;
      color: var(--s-700);
      padding: var(--space-smaller) var(--space-one);
      font-weight: var(--font-weight-medium);
      font-size: var(--font-size-small);
    }
  }
}
</style>
