<template>
  <div class="custom-attribute--selector">
    <div
      v-on-clickaway="closeDropdown"
      class="label-wrap"
      @keyup.esc="closeDropdown"
    >
      <woot-button
        size="small"
        variant="link"
        icon="ion-plus"
        @click="toggleAttributeDropDown"
      >
        {{ $t('CUSTOM_ATTRIBUTES.ADD_BUTTON_TEXT') }}
      </woot-button>

      <div class="dropdown-wrap">
        <div
          :class="{ 'dropdown-pane--open': showAttributeDropDown }"
          class="dropdown-pane"
        >
          <custom-attribute-drop-down
            v-if="showAttributeDropDown"
            :attribute-type="attributeType"
            :contact-id="contactId"
            @add-attribute="addAttribute"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CustomAttributeDropDown from './CustomAttributeDropDown.vue';
import alertMixin from 'shared/mixins/alertMixin';
import attributeMixin from 'dashboard/mixins/attributeMixin';
import { mixin as clickaway } from 'vue-clickaway';
import { BUS_EVENTS } from 'shared/constants/busEvents';

export default {
  components: {
    CustomAttributeDropDown,
  },
  mixins: [clickaway, alertMixin, attributeMixin],
  props: {
    attributeType: {
      type: String,
      default: 'conversation_attribute',
    },
    contactId: { type: Number, default: null },
  },
  data() {
    return {
      showAttributeDropDown: false,
    };
  },
  methods: {
    async addAttribute(attribute) {
      try {
        const { attribute_key } = attribute;
        if (this.attributeType === 'conversation_attribute') {
          await this.$store.dispatch('updateCustomAttributes', {
            conversationId: this.conversationId,
            customAttributes: {
              ...this.customAttributes,
              [attribute_key]: null,
            },
          });
        } else {
          await this.$store.dispatch('contacts/update', {
            id: this.contactId,
            custom_attributes: {
              ...this.customAttributes,
              [attribute_key]: null,
            },
          });
        }
        bus.$emit(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, attribute_key);
        this.showAlert(this.$t('CUSTOM_ATTRIBUTES.FORM.ADD.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CUSTOM_ATTRIBUTES.FORM.ADD.ERROR');
        this.showAlert(errorMessage);
      } finally {
        this.closeDropdown();
      }
    },

    toggleAttributeDropDown() {
      this.showAttributeDropDown = !this.showAttributeDropDown;
    },

    closeDropdown() {
      this.showAttributeDropDown = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.custom-attribute--selector {
  width: 100%;
  padding: var(--space-slab) var(--space-normal);

  .label-wrap {
    line-height: var(--space-medium);
    position: relative;

    .dropdown-wrap {
      display: flex;
      left: -1px;
      margin-right: var(--space-medium);
      position: absolute;
      top: var(--space-medium);
      width: 100%;

      .dropdown-pane {
        width: 100%;
        box-sizing: border-box;
      }
    }
  }
}

.error {
  color: var(--r-500);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-medium);
}
</style>
