import getDay from 'date-fns/getDay';

// Steps 3-8 are the only blue tokens that stay a background in both themes,
// so the count keeps AA contrast against text-n-slate-12 in light and dark mode.
// Keep these as complete literals so Tailwind's scanner includes every class.
export const CELL_INTENSITY_CLASSES = [
  'bg-n-blue-3 text-n-slate-12',
  'bg-n-blue-5 text-n-slate-12',
  'bg-n-blue-6 text-n-slate-12',
  'bg-n-blue-7 text-n-slate-12',
  'bg-n-blue-8 text-n-slate-12',
];

export const DAY_LABEL_FORMAT = 'dd/MM';
export const EMPTY_CELL = '·';

export const intensityClassFor = (value, maxValue) => {
  if (!value) {
    return '';
  }

  const ratio = maxValue ? value / maxValue : 0;
  const level = Math.max(
    0,
    Math.min(
      CELL_INTENSITY_CLASSES.length - 1,
      Math.ceil(ratio * CELL_INTENSITY_CLASSES.length) - 1
    )
  );
  return CELL_INTENSITY_CLASSES[level];
};

export const isWeekend = date => [0, 6].includes(getDay(date));
