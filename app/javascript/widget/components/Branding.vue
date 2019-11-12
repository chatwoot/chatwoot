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
  color: $color-gray;
  display: flex;
  filter: grayscale(1);
  font-size: $font-size-default;
  justify-content: center;
  padding: $space-one;
  text-align: center;
  text-decoration: none;

  &:hover {
    filter: grayscale(0);
  }

  img {
    margin-right: $space-small;
    max-width: $space-two;
  }
}
</style>
