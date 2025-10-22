const roundPriceByRange = (amount) => {
  if (amount < 1000000) {
    return Math.round(amount / 1000) * 1000; // nearest 1 ribu
  } else if (amount < 2000000) {
    return Math.round(amount / 50000) * 50000; // nearest 50 ribu
  } else if (amount < 5000000) {
    return Math.round(amount / 25000) * 25000; // nearest 25 ribu
  } else if (amount < 6000000) {
    return Math.ceil(amount / 100000) * 100000; // selalu naik ke atas 100 ribu
  } else if (amount < 10000000) {
    return Math.round(amount / 100000) * 100000; // nearest 100 ribu
  } else if (amount < 30000000) {
    return Math.round(amount / 250000) * 250000; // nearest 250 ribu
  } else {
    return Math.round(amount / 1000000) * 1000000; // nearest 1 juta
  }
};

export const durationMap = {
  monthly: 1,
  quarterly: 3,
  halfyear: 6,
  yearly: 12,
};

export const packagePrice = (plan, durationKey) => {
  if (!plan) {
    return 0;
  }
  let price;
  switch (durationKey) {
    case 'quarterly':
      price = plan.quarterly_price || 0;
      break;
    case 'halfyear':
      price = plan.semi_annual_price || 0;
      break;
    case 'yearly':
      price = plan.annual_price || 0;
      break;
    case 'monthly':
    default:
      price = plan.monthly_price || 0;
  }
  return Math.round(Number(price));
};