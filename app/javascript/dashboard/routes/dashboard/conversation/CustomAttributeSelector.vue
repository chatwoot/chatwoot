<template>
  <div class="sidebar-labels-wrap">
    <div class="contact-conversation--list">
      <div
        v-on-clickaway="closeDropdownLabel"
        class="label-wrap"
        @keyup.esc="closeDropdownLabel"
      >
        <woot-button
          size="small"
          variant="link"
          icon="ion-plus"
          @click="toggleAttributeDropDown"
        >
          {{ $t('CONVERSATION_CUSTOM_ATTRIBUTES.ADD_BUTTON_TEXT') }}
        </woot-button>

        <div class="dropdown-wrap">
          <div
            :class="{ 'dropdown-pane--open': showAttributeDropDown }"
            class="dropdown-pane"
          >
            <attribute-drop-down
              v-if="showAttributeDropDown"
              @add-attribute="addAttribute"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import AttributeDropDown from './AttributeDropDown.vue';
import alertMixin from 'shared/mixins/alertMixin';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    AttributeDropDown,
  },
  mixins: [clickaway, alertMixin],
  props: {
    conversationId: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      showAttributeDropDown: false,
    };
  },

  computed: {
    attributes() {
      return this.$store.getters['attributes/getAttributesByModel'](
        'conversation_attribute'
      );
    },
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    conversationCustomAttributes() {
      return this.currentChat.custom_attributes || {};
    },
  },
  methods: {
    async addAttribute(attribute) {
      const key = attribute.attribute_key;
      try {
        await this.$store.dispatch('updateCustomAttributes', {
          conversationId: this.currentChat.id,
          customAttributes: {
            [key]: null,
            ...this.conversationCustomAttributes,
          },
        });

        this.showAlert(this.$t('CONVERSATION_CUSTOM_ATTRIBUTES.ADD.SUCCESS'));
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('CONVERSATION_CUSTOM_ATTRIBUTES.ADD.ERROR');
        this.showAlert(errorMessage);
      } finally {
        this.closeDropdownLabel();
      }
    },

    toggleAttributeDropDown() {
      this.showAttributeDropDown = !this.showAttributeDropDown;
    },

    closeDropdownLabel() {
      this.showAttributeDropDown = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.sidebar-labels-wrap {
  margin-bottom: var(--space-normal);
}
.contact-conversation--list {
  width: 100%;

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
