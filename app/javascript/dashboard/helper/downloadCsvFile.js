export const downloadCsvFile = (fileName, fileContent) => {
  const link = document.createElement('a');
  link.download = fileName;
  link.href = `data:text/csv;charset=utf-8,` + encodeURI(fileContent);
  link.click();
};
