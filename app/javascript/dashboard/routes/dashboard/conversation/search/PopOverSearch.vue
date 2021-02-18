<template>
  <div class="search-content">
    <div class="search-wrap">
      <div class="icon-text-wrap">
        <i class="ion-ios-search-strong search--icon" />
      </div>
      <input
        class="search--input"
        :placeholder="$t('CONVERSATION.SEARCH_MESSAGES')"
        @focus="onSearch"
        @blur="closeSearch"
      />
    </div>
    <div v-if="showSearchModal" class="list-wrap">
      <p class="result-wrap">
        Search Results
      </p>
      <div class="list-content">
        <div class="content">
          <div class="time-ticket-wrap">
            <div class="ticket-wrap">
              <div><span class="ticket">#1</span></div>
              <div class="user-wrap">
                <span class="user-name">John</span>
                <i class="ion-headphone" />
              </div>
            </div>
            <span class="timestamp">about 1 hour ago </span>
          </div>
          <div>
            <p class="search-messages">
              We use cookies to personalize content and ads, to provide social
              media features and to analyze our traffic.
            </p>
          </div>
        </div>
        <div class="content">
          <div class="time-ticket-wrap">
            <div class="ticket-wrap">
              <div><span class="ticket">#2</span></div>
              <div class="user-wrap">
                <span class="user-name">Jhony</span>
              </div>
            </div>
            <span class="timestamp">about 2 day ago </span>
          </div>
          <div>
            <p class="search-messages">
              We use cookies to personalize content and ads, to provide social
              media features and to analyze our traffic.
            </p>
          </div>
        </div>
        <div class="content">
          <div class="time-ticket-wrap">
            <div class="ticket-wrap">
              <div><span class="ticket">#3</span></div>
              <div class="user-wrap">
                <span class="user-name">James</span>
                <i class="ion-headphone" />
              </div>
            </div>
            <span class="timestamp">about 5 month ago </span>
          </div>
          <div>
            <p class="search-messages">
              We use cookies to personalize content and ads, and to analyze our
              traffic. https://cdn.jsdelivr.net/npm/vue/dist/vue.js
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {},
  data() {
    return {
      showSearchModal: false,
    };
  },
  computed: {},

  mounted() {},

  methods: {
    onSearch() {
      this.showSearchModal = true;
    },
    closeSearch() {
      this.showSearchModal = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.search-content {
  position: relative;
}
.search-wrap {
  display: flex;
}
.search--input {
  align-items: center;
  border: 0;
  color: var(--s-400);
  cursor: pointer;
  width: 100%;
  display: flex;
  font-size: var(--font-size-small);
  font-weight: 400;
  padding: var(--space-normal) var(--space-smaller) var(--space-slab);
  text-align: left;
  line-height: var(--font-size-large);

  &:hover {
    .search--icon {
      color: var(--w-500);
    }
  }
}

.search--icon {
  color: var(--s-600);
  font-size: var(--font-size-large);
  padding: var(--space-normal) var(--space-small) var(--space-slab)
    var(--space-medium);
}

.icon-text-wrap {
  display: flex;
}

.list-wrap {
  position: absolute;
  z-index: 10000;
  box-shadow: var(--shadow-large);
  background: white;
  width: 100%;
}
.list-content {
  list-style-type: none;
  font-size: var(--font-size-small);
  font-weight: 400;
}
.content {
  display: block;
  align-items: center;
  border-bottom: 1px solid var(--color-border-light);
  color: var(--color-body);
  padding: 0.3rem var(--space-micro) var(--space-zero) 1.7rem;
}
.content:last-child {
  border-bottom: none;
  padding-bottom: var(--space-two);
}

.content:hover {
  background-color: var(--color-background);
}

.time-ticket-wrap {
  display: flex;
  justify-content: space-between;
  padding: var(--space-small) var(--space-normal) var(--space-smaller)
    var(--space-zero);
}
.search-messages {
  padding: var(--space-micro) var(--space-normal) var(--space-zero)
    var(--space-zero);
}
.result-wrap {
  padding: var(--space-normal) var(--space-smaller) var(--space-smaller)
    var(--space-normal);
  border-top: 1px solid var(--b-200);
  font-size: var(--font-size-medium);
  font-weight: var(--font-weight-bold);
}
.ticket-wrap {
  display: flex;
}
.ticket {
  color: var(--w-600);
  font-size: var(--font-size-mini);
  font-weight: var(--font-weight-bold);
  background: var(--w-50);
  border-radius: 4px;
  padding: var(--space-micro) var(--space-smaller);
}
.user-wrap {
  display: flex;
  align-items: last baseline;
}
.user-name {
  padding-right: var(--space-smaller);
  padding-left: var(--space-smaller);
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-bold);
  color: var(--color-heading);
}
.ion-headphone {
  color: var(--w-500);
  padding: var(--space-micro);
  padding-right: var(--space-smaller);
  font-size: var(--font-size-mini);
}
.timestamp {
  font-size: var(--font-size-mini);
}
p {
  max-width: 100%;
}
.ion-record {
  font-size: 4px;
  margin-top: 13px;
  padding-right: var(--space-smaller);
}
</style>
