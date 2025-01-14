export const VARIANT_OPTIONS = ['solid', 'outline', 'faded', 'link', 'ghost'];
export const COLOR_OPTIONS = ['blue', 'ruby', 'amber', 'slate', 'teal'];
export const SIZE_OPTIONS = ['xs', 'sm', 'md', 'lg'];

export const EXCLUDED_ATTRS = [
  'variant',
  'color',
  'size',
  'icon',
  'trailingIcon',
  'isLoading',
  ...VARIANT_OPTIONS,
  ...COLOR_OPTIONS,
  ...SIZE_OPTIONS,
];
