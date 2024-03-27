export const UISteps = [
  {
    name: 'onboarding_setup_profile',
    title: 'Setup Profile',
    icon: 'person',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_setup_company',
    title: 'Setup Company',
    icon: 'toolbox',
    isActive: false,
    isComplete: false,
  },
  {
    name: 'onboarding_invite_team',
    title: 'Invite your team',
    icon: 'people-team',
    isActive: false,
    isComplete: false,
  },
];

export const API_ONBOARDING_STEP_ROUTE = {
  profile_update: 'onboarding_setup_profile',
  account_update: 'onboarding_setup_company',
  invite_team: 'onboarding_invite_team',
};
