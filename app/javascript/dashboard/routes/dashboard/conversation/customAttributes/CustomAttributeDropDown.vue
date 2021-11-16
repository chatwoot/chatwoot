<template>
  <div class="dropdown-search-wrap">
    <h4 class="text-block-title">
      {{ $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.TITLE') }}
    </h4>
    <div class="search-wrap">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="$t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.PLACEHOLDER')"
      />
    </div>
    <div class="list-wrap">
      <div class="list">
        <woot-dropdown-menu>
          <custom-attribute-drop-down-item
            v-for="attribute in filteredAttributes"
            :key="attribute.attribute_display_name"
            :title="attribute.attribute_display_name"
            @click="onAddAttribute(attribute)"
          />
        </woot-dropdown-menu>
        <div v-if="noResult" class="no-result">
          {{ $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.NO_RESULT') }}
        </div>
        <woot-button
          class="add"
          icon="ion-plus-round"
          size="tiny"
          @click="addNewAttribute"
        >
          {{ $t('CUSTOM_ATTRIBUTES.FORM.ADD.TITLE') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
import CustomAttributeDropDownItem from './CustomAttributeDropDownItem.vue';
import attributeMixin from 'dashboard/mixins/attributeMixin';
export default {
  components: {
    CustomAttributeDropDownItem,
  },
  mixins: [attributeMixin],
  props: {
    attributeType: {
      type: String,
      default: 'conversation_attribute',
    },
    contactId: { type: Number, default: null },
  },

  data() {
    return {
      search: '',
    };
  },

  computed: {
    filteredAttributes() {
      return this.attributes
        .filter(
          item =>
            !Object.keys(this.customAttributes).includes(item.attribute_key)
        )
        .filter(attribute => {
          return attribute.attribute_display_name
            .toLowerCase()
            .includes(this.search.toLowerCase());
        });
    },

    noResult() {
      return this.filteredAttributes.length === 0;
    },
  },

  mounted() {
    this.focusInput();
  },

  methods: {
    focusInput() {
      this.$refs.searchbar.focus();
    },
    addNewAttribute() {
      this.$router.push(
        `/app/accounts/${this.accountId}/settings/custom-attributes/list`
      );
    },
    async onAddAttribute(attribute) {
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
