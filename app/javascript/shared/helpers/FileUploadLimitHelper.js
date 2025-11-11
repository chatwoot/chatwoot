export const DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE = 40;

export const resolveMaximumFileUploadSize = value => {
  const parsedValue = Number(value);

  if (!Number.isFinite(parsedValue) || parsedValue <= 0) {
    return DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE;
  }

  return parsedValue;
};
