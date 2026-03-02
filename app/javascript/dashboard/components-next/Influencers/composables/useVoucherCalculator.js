import { ref, computed } from 'vue';

// EUR per quality-adjusted follower (≈ 0.08 PLN / 4.2)
const RATE = 0.019;

const CONTENT_ELEMENTS = {
  reel: { weight: 0.5, defaultOn: true },
  carousel: { weight: 0.2, defaultOn: true },
  stories: { weight: 0.3, defaultOn: true },
};

const RIGHTS_MULTIPLIERS = {
  standard: 1.0,
  extended: 1.5,
};

const CONTENT_FLOOR = 0.1;

export function useVoucherCalculator(profile) {
  const includeReel = ref(CONTENT_ELEMENTS.reel.defaultOn);
  const includeCarousel = ref(CONTENT_ELEMENTS.carousel.defaultOn);
  const includeStories = ref(CONTENT_ELEMENTS.stories.defaultOn);
  const rightsLevel = ref('standard');

  const contentMultiplier = computed(() => {
    let sum = 0;
    if (includeReel.value) sum += CONTENT_ELEMENTS.reel.weight;
    if (includeCarousel.value) sum += CONTENT_ELEMENTS.carousel.weight;
    if (includeStories.value) sum += CONTENT_ELEMENTS.stories.weight;
    return Math.max(sum, CONTENT_FLOOR);
  });

  const rightsMultiplier = computed(
    () => RIGHTS_MULTIPLIERS[rightsLevel.value] || 1.0
  );

  const voucherValue = computed(() => {
    const fqs = profile.value?.fqs_score;
    const followers = Number(profile.value?.followers_count || 0);
    if (fqs == null || !followers) return null;
    return (
      followers *
      (fqs / 100) *
      RATE *
      contentMultiplier.value *
      rightsMultiplier.value
    );
  });

  return {
    RATE,
    CONTENT_ELEMENTS,
    RIGHTS_MULTIPLIERS,
    includeReel,
    includeCarousel,
    includeStories,
    rightsLevel,
    contentMultiplier,
    rightsMultiplier,
    voucherValue,
  };
}
