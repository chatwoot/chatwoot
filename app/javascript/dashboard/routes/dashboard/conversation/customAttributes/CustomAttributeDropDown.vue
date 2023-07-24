<template>
  <div class="flex flex-col w-full max-h-[12.5rem]">
    <h4
      class="text-sm text-slate-800 dark:text-slate-100 mb-1 overflow-hidden whitespace-nowrap text-ellipsis flex-grow"
    >
      {{ $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.TITLE') }}
    </h4>
    <div class="mb-2 flex-shrink-0 flex-grow-0 flex-auto max-h-8">
      <input
        ref="searchbar"
        v-model="search"
        type="text"
        class="search-input"
        autofocus="true"
        :placeholder="$t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.PLACEHOLDER')"
      />
    </div>
    <div
      class="flex justify-start items-start flex-grow flex-shrink flex-auto overflow-auto h-32"
    >
      <div class="w-full h-full">
        <woot-dropdown-menu>
          <custom-attribute-drop-down-item
            v-for="attribute in filteredAttributes"
            :key="attribute.attribute_display_name"
            :title="attribute.attribute_display_name"
            @click="onAddAttribute(attribute)"
          />
        </woot-dropdown-menu>
        <div
          v-if="noResult"
          class="w-full justify-center items-center flex mb-2 h-[70%] text-slate-500 dark:text-slate-300 py-2 px-2.5 overflow-hidden whitespace-nowrap text-ellipsis text-sm"
        >
          {{ $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_SELECT.NO_RESULT') }}
        </div>
        <woot-button
          class="float-right"
          icon="add"
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
.search-input {
  @apply m-0 w-full border border-solid border-transparent h-8 text-sm text-slate-700 dark:text-slate-100 rounded-md focus:border-woot-500 bg-slate-50 dark:bg-slate-900;
}
</style>
