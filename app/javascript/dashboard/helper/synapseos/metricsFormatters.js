// Formatters for SynapseOS C-Level metrics.
// All pt-BR-friendly: comma decimal, dot thousands, BRL currency.

const brlFormatter = new Intl.NumberFormat('pt-BR', {
  style: 'currency',
  currency: 'BRL',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const countFormatter = new Intl.NumberFormat('pt-BR');

export const EMPTY = '—';

export const isBlank = value => value === null || value === undefined;

export const formatBRL = cents => {
  if (isBlank(cents)) return EMPTY;
  const amount = Number(cents) / 100;
  return brlFormatter.format(amount);
};

export const formatPercent = ratio => {
  if (isBlank(ratio)) return EMPTY;
  const percent = Number(ratio) * 100;
  return `${percent.toFixed(1).replace('.', ',')}%`;
};

export const formatSeconds = seconds => {
  if (isBlank(seconds)) return EMPTY;
  const s = Math.max(0, Math.round(Number(seconds)));
  if (s < 60) return `${s}s`;
  if (s < 3600) {
    const minutes = Math.floor(s / 60);
    const rest = s % 60;
    return rest ? `${minutes}m ${rest}s` : `${minutes}m`;
  }
  const hours = Math.floor(s / 3600);
  const minutes = Math.floor((s % 3600) / 60);
  return minutes ? `${hours}h ${minutes}m` : `${hours}h`;
};

export const formatCount = n => {
  if (isBlank(n)) return EMPTY;
  return countFormatter.format(Number(n));
};
