<script>
import { useBranding } from 'shared/composables/useBranding';

const {
  LOGO_THUMBNAIL: logoThumbnail,
  BRAND_NAME: brandName,
  WIDGET_BRAND_URL: widgetBrandURL,
} = window.globalConfig || {};

export default {
  props: {
    disableBranding: {
      type: Boolean,
      default: false,
    },
    // Pages served on behalf of a single account pass that account's brand. Everything else
    // omits it and keeps the installation's, so the widget is untouched.
    brandName: {
      type: String,
      default: '',
    },
    // Whether the thumbnail is the mark of whoever this page belongs to, rather than a vendor
    // badge. Only that case drops the greyscale.
    ownLogo: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return {
      replaceInstallationName,
    };
  },
  data() {
    return {
      globalConfig: {
        brandName,
        logoThumbnail,
        widgetBrandURL,
      },
    };
  },
  computed: {
    displayedBrandName() {
      return this.brandName || this.globalConfig.brandName;
    },
    // Substitution first, interpolation only as a fallback, because the two differ in what they
    // preserve. POWERED_BY is translated into every language upstream ships; POWERED_BY_BRAND is
    // ours and exists in three, falling back to English everywhere else. So substituting into
    // the localized sentence keeps a French survey French, and the fork key is reached only
    // where substitution has nothing to match -- Persian and Tamil spell the vendor
    // transliterated, so the Latin name never appears. An English sentence around the right
    // brand beats a French sentence around the wrong one, and only those locales pay it.
    poweredByText() {
      const template = this.$t('POWERED_BY');
      if (!this.brandName) return this.replaceInstallationName(template);

      // Callback, not a string: in a replacement string `$$`, `$&` and `$1` are syntax, and
      // brand_name only rejects `<>`, so a brand of "ACME $$" would render "ACME $" and one of
      // "$&" would put "Chatwoot" back. A function inserts whatever it returns, verbatim.
      const substituted = template.replace(/chatwoot/gi, () => this.brandName);
      return substituted === template
        ? this.$t('POWERED_BY_BRAND', { brandName: this.brandName })
        : substituted;
    },
    brandRedirectURL() {
      try {
        const referrerHost = this.$store.getters['appConfig/getReferrerHost'];
        const url = new URL(this.globalConfig.widgetBrandURL);
        if (referrerHost) {
          url.searchParams.set('utm_source', referrerHost);
          url.searchParams.set('utm_medium', 'widget');
        } else {
          url.searchParams.set('utm_medium', 'survey');
        }
        url.searchParams.set('utm_campaign', 'branding');
        return url.toString();
      } catch (e) {
        // Suppressing the error as getter is not defined in some cases
      }
      return '';
    },
  },
};
</script>

<template>
  <div
    v-if="displayedBrandName && !disableBranding"
    class="px-0 py-3 flex justify-center"
  >
    <a
      :href="brandRedirectURL"
      rel="noreferrer noopener nofollow"
      target="_blank"
      class="branding--link text-n-slate-11 hover:text-n-slate-12 cursor-pointer text-xs inline-flex hover:opacity-100 opacity-90 no-underline justify-center items-center leading-3"
      :class="{ 'grayscale-[1] hover:grayscale-0': !ownLogo }"
    >
      <!-- Greyscale suits a vendor badge, which is what this is by default. A page carrying the
           mark of whoever owns it is not a badge, so that one keeps its colour.
           max-w rather than a square box: an account's mark is a wide email header logo, and
           squeezing it into 12x12 leaves an illegible smudge. A square installation thumbnail
           still renders exactly as before.

           Height, not just width, is what has to give for a wide mark: a 391x121 logo capped at
           12px tall comes out 39px wide, so max-w-16 never engages and the wordmark inside is
           unreadable. Only the own-logo case is raised -- the vendor badge stays the size it
           has always been. -->
      <img
        class="ltr:mr-1 rtl:ml-1 w-auto object-contain"
        :class="ownLogo ? 'max-h-5 max-w-24' : 'max-h-3 max-w-16'"
        :alt="displayedBrandName"
        :src="globalConfig.logoThumbnail"
      />
      <span>
        {{ poweredByText }}
      </span>
    </a>
  </div>
  <div v-else class="p-3" />
</template>
