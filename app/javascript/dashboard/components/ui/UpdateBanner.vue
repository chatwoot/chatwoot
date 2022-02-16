<template>
  <div class="banner">
    <div class="banner__items">
      <div class="banner___text">
        <p>
          {{
            $t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
              latestChatwootVersion: latestChatwootVersion,
            })
          }}
          <a href="https://github.com/chatwoot/chatwoot/releases">
            {{ $t('GENERAL_SETTINGS.LEARN_MORE') }}
            <span aria-hidden="true">→</span>
          </a>
        </p>
      </div>
      <div class="banner__close">
        <woot-button
          icon="dismiss"
          variant="hollow"
          @click="dismissUpdateBanner"
        />
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    latestChatwootVersion: {
      type: String,
      default: '',
    },
    dismissUpdateBanner: {
      type: Function,
      required: true,
    },
  },
};
</script>

<style lang="scss" scoped>
.banner {
  background-color: var(--w-500);
  padding: var(--space-small) var(--space-two);
  .banner__items {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    .banner___text {
      display: flex;
      width: 0;
      flex: 1 1 0%;
      align-items: center;
      p {
        font-weight: var(--font-weight-medium);
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        margin: 0 0 0 var(--space-small);
        color: var(--white);
      }
      a {
        margin-left: 0 var(--space-small);
        color: var(--white);
        text-decoration: underline;
        font-weight: var(--font-weight-black);
      }
    }
    .banner__close {
      button {
        border: 0;
        color: var(--white);
        &:hover,
        &:focus {
          border: 1px solid var(--white);
          color: var(--white);
        }
      }
    }
  }
}
</style>
