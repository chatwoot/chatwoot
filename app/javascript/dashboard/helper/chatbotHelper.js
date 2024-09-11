import mammoth from 'mammoth';

export async function processTextFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = e => {
      const content = e.target.result;
      resolve(content.length);
    };
    reader.onerror = reject;
    reader.readAsText(file);
  });
}

export async function processDocxFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = async event => {
      try {
        const arrayBuffer = event.target.result;
        const result = await mammoth.extractRawText({ arrayBuffer });
        resolve(result.value.length);
      } catch (error) {
        reject(
          new Error('Error extracting text from DOCX file: ' + error.message)
        );
      }
    };
    reader.onerror = () => {
      reject(new Error('Error reading DOCX file'));
    };
    reader.readAsArrayBuffer(file);
  });
}
