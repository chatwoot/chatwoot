function currencyFormatter(value) {
  if (value === undefined || value === null) {
    return '';
  }

  let numberValue = value.replace('₫', '');
  numberValue = numberValue.replace(/,/g, '');
  numberValue = numberValue.replace(/\.00$/, '');
  numberValue = numberValue.replace(/\./g, '');

  const parsedValue = parseFloat(numberValue);

  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(parsedValue);
}

export { currencyFormatter };
