export const UISteps = [
  {
    name: 'onboarding_setup_profile',
    title: t => t('START_ONBOARDING.SETUP_PROFILE.TITLE'),
    icon: 'person',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_add_agent',
    title: t => t('START_ONBOARDING.ADD_AGENTS.TITLE'),
    icon: 'people-team',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_setup_inbox',
    title: t => t('START_ONBOARDING.SETUP_INBOX.TITLE'),
    icon: 'toolbox',
    isActive: false,
    isComplete: false,
  },
];

export const API_ONBOARDING_STEP_ROUTE = {
  profile_update: 'onboarding_setup_profile',
  add_agent: 'onboarding_add_agent',
  setup_inbox: 'onboarding_setup_inbox',
};
