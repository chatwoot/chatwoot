<template>
  <a
    class="branding"
    href="https://www.chatwoot.com?utm_source=widget_branding"
    rel="noreferrer noopener nofollow"
    target="_blank"
  >
    <img src="~widget/assets/images/logo.svg" />
    <span>Powered by Chatwoot</span>
  </a>
</template>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.branding {
  align-items: center;
  color: $color-light-gray;
  opacity: 0.9;
  display: flex;
  filter: grayscale(1);
  font-size: $font-size-mini;
  justify-content: center;
  padding: $space-one;
  text-align: center;
  text-decoration: none;
  cursor: pointer;

  &:hover {
    filter: grayscale(0);
    opacity: 1;
    color: $color-gray;
  }

  img {
    margin-right: $space-smaller;
    max-width: $space-slab;
  }
}
</style>
