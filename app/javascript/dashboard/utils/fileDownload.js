export default function downloadFile(fileName, content) {
  let csvContent = 'data:text/csv;charset=utf-8,' + content;
  var encodedUri = encodeURI(csvContent);
  var downloadLink = document.createElement('a');
  downloadLink.href = encodedUri;
  downloadLink.download = fileName;
  document.body.appendChild(downloadLink);
  downloadLink.click();
  document.body.removeChild(downloadLink);
}
