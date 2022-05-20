<template>
  <div class="medium-12 columns">
    <div class="templates__list-search">
      <fluent-icon icon="search" class="search-icon" size="16" />
      <input
        ref="search"
        v-model="query"
        type="search"
        :placeholder="$t('WHATSAPP_TEMPLATES.PICKER.SEARCH_PLACEHOLDER')"
        class="templates__search-input"
      />
    </div>
    <div class="template__list-container">
      <button
        v-for="template in filteredTemplates"
        :key="template.id"
        class="template__list-item"
        @click="$emit('onSelect', template)"
      >
        <p>
          {{ template.name }}
        </p>
      </button>
      <div v-if="!filteredTemplates.length">
        <p>
          {{ $t('WHATSAPP_TEMPLATES.PICKER.NO_TEMPLATES_FOUND') }}
          <strong>{{ query }}</strong>
        </p>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      query: '',
      // Mock data
      templates: [
        {
          id: 1,
          name: 'Transaction Alert',
          message: {
            content:
              "Hi {name} You've have been charged $ {amount} for {product_name} on {date}",
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'amount',
                type: 'number',
                value: '',
              },
              {
                name: 'product_name',
                type: 'string',
                value: '',
              },
              {
                name: 'date',
                type: 'date',
                value: '',
              },
            ],
          },
        },
        {
          id: 2,
          name: 'Diwali Promotional Message',
          message: {
            content:
              'Hi {name}, get {discount} off on your next purchase, use coupon code {code}',
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'discount',
                type: 'number',
                value: '',
              },
              {
                name: 'code',
                type: 'string',
                value: '',
              },
            ],
          },
        },
        {
          id: 3,
          name: 'Account Opening Welcome message',
          message: {
            content:
              'Hi {name} Welcome to {business_name} Thank you for choosing us',
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'business_name',
                type: 'string',
                value: '',
              },
            ],
          },
        },
        {
          id: 4,
          name: 'Account Verification OTP',
          message: {
            content:
              'Hi {name} Your OTP is {otp} Please use this OTP to verify your account',
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'otp',
                type: 'number',
                value: '',
              },
            ],
          },
        },
        {
          id: 5,
          name: 'Transaction Alert 2',
          message: {
            content:
              "Hi {name} You've have succesfully subscribed to {product} on {date}, you will be charged {amount}",
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'product',
                type: 'string',
                value: '',
              },
              {
                name: 'date',
                type: 'date',
                value: '',
              },
              {
                name: 'amount',
                type: 'number',
                value: '',
              },
            ],
          },
        },
        {
          id: 6,
          name: 'Christmas Promotional Message',
          message: {
            content:
              'Hi {name}, Get {discount} off on your next Christmas, use coupon code {code}',
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'discount',
                type: 'number',
                value: '',
              },
              {
                name: 'code',
                type: 'string',
                value: '',
              },
            ],
          },
        },
        {
          id: 7,
          name: 'Account Deletion message',
          message: {
            content: 'Hi {name} Your account has been deleted on {date}',
            variables: [
              {
                name: 'name',
                type: 'string',
                value: '',
              },
              {
                name: 'date',
                type: 'date',
                value: '',
              },
            ],
          },
        },
      ],
    };
  },
  computed: {
    filteredTemplates() {
      return this.templates.filter(template =>
        template.name.toLowerCase().includes(this.query.toLowerCase())
      );
    },
  },
};
</script>

<style scoped lang="scss">
.templates__list-search {
  display: flex;
  align-items: center;
  padding: 0 var(--space-one);
  border: 1px solid var(--s-100);
  border-radius: var(--border-radius-medium);
  background-color: var(--s-25);
  margin-bottom: var(--space-one);
  .search-icon {
    color: var(--s-400);
  }
  .templates__search-input {
    border: 0;
    font-size: var(--font-size-mini);
    margin: 0;
    background-color: transparent;
    height: unset;
  }
}
.template__list-container {
  background-color: var(--s-25);
  max-height: 16rem;
  padding: var(--space-one);
  overflow-y: auto;
  border-radius: var(--border-radius-medium);
  .template__list-item {
    width: 100%;
    display: block;
    text-align: left;
    padding: var(--space-one);
    cursor: pointer;
    border-radius: var(--border-radius-medium);
    &:hover {
      background-color: var(--w-50);
    }
  }
}
</style>
