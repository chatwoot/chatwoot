const fs = require('fs');
const content = fs.readFileSync('app/javascript/dashboard/components-next/message/Message.vue', 'utf8');
console.log("File read successfully, size:", content.length);
