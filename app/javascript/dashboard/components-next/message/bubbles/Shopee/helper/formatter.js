function currencyFormatter(value) {
  if (value === undefined || value === null) {
    return '';
  }
  let parsedValue = value;

  if (typeof value === 'string') {
    // Remove .00 from the end
    if (value.endsWith('.00')) {
      value = value.slice(0, -3);
    }
    let numberValue = value.replace(/[.,₫\s]/g, '');
    parsedValue = parseInt(numberValue, 10);
  } else {
    parsedValue = parseInt(value, 10);
  }

  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(parsedValue);
}

function percentageFormatter(value) {
  if (value === undefined || value === null) {
    return '??%';
  }

  return new Intl.NumberFormat('vi-VN', {
    style: 'percent',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value / 100);
}

function timeFormatter(value) {
  if (value === undefined || value === null) {
    return '';
  }

  return new Intl.DateTimeFormat('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}

export { currencyFormatter, percentageFormatter, timeFormatter };
