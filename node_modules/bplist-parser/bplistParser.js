'use strict';

// adapted from http://code.google.com/p/plist/source/browse/trunk/src/com/dd/plist/BinaryPropertyListParser.java

var fs = require('fs');
var bigInt = require("big-integer");
var debug = false;

exports.maxObjectSize = 100 * 1000 * 1000; // 100Meg
exports.maxObjectCount = 32768;

// EPOCH = new SimpleDateFormat("yyyy MM dd zzz").parse("2001 01 01 GMT").getTime();
// ...but that's annoying in a static initializer because it can throw exceptions, ick.
// So we just hardcode the correct value.
var EPOCH = 978307200000;

// UID object definition
var UID = exports.UID = function(id) {
  this.UID = id;
}

var parseFile = exports.parseFile = function (fileNameOrBuffer, callback) {
  function tryParseBuffer(buffer) {
    var err = null;
    var result;
    try {
      result = parseBuffer(buffer);
    } catch (ex) {
      err = ex;
    }
    callback(err, result);
  }

  if (Buffer.isBuffer(fileNameOrBuffer)) {
    return tryParseBuffer(fileNameOrBuffer);
  } else {
    fs.readFile(fileNameOrBuffer, function (err, data) {
      if (err) { return callback(err); }
      tryParseBuffer(data);
    });
  }
};

var parseBuffer = exports.parseBuffer = function (buffer) {
  var result = {};

  // check header
  var header = buffer.slice(0, 'bplist'.length).toString('utf8');
  if (header !== 'bplist') {
    throw new Error("Invalid binary plist. Expected 'bplist' at offset 0.");
  }

  // Handle trailer, last 32 bytes of the file
  var trailer = buffer.slice(buffer.length - 32, buffer.length);
  // 6 null bytes (index 0 to 5)
  var offsetSize = trailer.readUInt8(6);
  if (debug) {
    console.log("offsetSize: " + offsetSize);
  }
  var objectRefSize = trailer.readUInt8(7);
  if (debug) {
    console.log("objectRefSize: " + objectRefSize);
  }
  var numObjects = readUInt64BE(trailer, 8);
  if (debug) {
    console.log("numObjects: " + numObjects);
  }
  var topObject = readUInt64BE(trailer, 16);
  if (debug) {
    console.log("topObject: " + topObject);
  }
  var offsetTableOffset = readUInt64BE(trailer, 24);
  if (debug) {
    console.log("offsetTableOffset: " + offsetTableOffset);
  }

  if (numObjects > exports.maxObjectCount) {
    throw new Error("maxObjectCount exceeded");
  }

  // Handle offset table
  var offsetTable = [];

  for (var i = 0; i < numObjects; i++) {
    var offsetBytes = buffer.slice(offsetTableOffset + i * offsetSize, offsetTableOffset + (i + 1) * offsetSize);
    offsetTable[i] = readUInt(offsetBytes, 0);
    if (debug) {
      console.log("Offset for Object #" + i + " is " + offsetTable[i] + " [" + offsetTable[i].toString(16) + "]");
    }
  }

  // Parses an object inside the currently parsed binary property list.
  // For the format specification check
  // <a href="http://www.opensource.apple.com/source/CF/CF-635/CFBinaryPList.c">
  // Apple's binary property list parser implementation</a>.
  function parseObject(tableOffset) {
    var offset = offsetTable[tableOffset];
    var type = buffer[offset];
    var objType = (type & 0xF0) >> 4; //First  4 bits
    var objInfo = (type & 0x0F);      //Second 4 bits
    switch (objType) {
    case 0x0:
      return parseSimple();
    case 0x1:
      return parseInteger();
    case 0x8:
      return parseUID();
    case 0x2:
      return parseReal();
    case 0x3:
      return parseDate();
    case 0x4:
      return parseData();
    case 0x5: // ASCII
      return parsePlistString();
    case 0x6: // UTF-16
      return parsePlistString(true);
    case 0xA:
      return parseArray();
    case 0xD:
      return parseDictionary();
    default:
      throw new Error("Unhandled type 0x" + objType.toString(16));
    }

    function parseSimple() {
      //Simple
      switch (objInfo) {
      case 0x0: // null
        return null;
      case 0x8: // false
        return false;
      case 0x9: // true
        return true;
      case 0xF: // filler byte
        return null;
      default:
        throw new Error("Unhandled simple type 0x" + objType.toString(16));
      }
    }

    function bufferToHexString(buffer) {
      var str = '';
      var i;
      for (i = 0; i < buffer.length; i++) {
        if (buffer[i] != 0x00) {
          break;
        }
      }
      for (; i < buffer.length; i++) {
        var part = '00' + buffer[i].toString(16);
        str += part.substr(part.length - 2);
      }
      return str;
    }

    function parseInteger() {
      var length = Math.pow(2, objInfo);
      if (length > 4) {
        var data = buffer.slice(offset + 1, offset + 1 + length);
        var str = bufferToHexString(data);
        return bigInt(str, 16);
      } if (length < exports.maxObjectSize) {
        return readUInt(buffer.slice(offset + 1, offset + 1 + length));
      } else {
        throw new Error("To little heap space available! Wanted to read " + length + " bytes, but only " + exports.maxObjectSize + " are available.");
      }
    }

    function parseUID() {
      var length = objInfo + 1;
      if (length < exports.maxObjectSize) {
        return new UID(readUInt(buffer.slice(offset + 1, offset + 1 + length)));
      } else {
        throw new Error("To little heap space available! Wanted to read " + length + " bytes, but only " + exports.maxObjectSize + " are available.");
      }
    }

    function parseReal() {
      var length = Math.pow(2, objInfo);
      if (length < exports.maxObjectSize) {
        var realBuffer = buffer.slice(offset + 1, offset + 1 + length);
        if (length === 4) {
          return realBuffer.readFloatBE(0);
        }
        else if (length === 8) {
          return realBuffer.readDoubleBE(0);
        }
      } else {
        throw new Error("To little heap space available! Wanted to read " + length + " bytes, but only " + exports.maxObjectSize + " are available.");
      }
    }

    function parseDate() {
      if (objInfo != 0x3) {
        console.error("Unknown date type :" + objInfo + ". Parsing anyway...");
      }
      var dateBuffer = buffer.slice(offset + 1, offset + 9);
      return new Date(EPOCH + (1000 * dateBuffer.readDoubleBE(0)));
    }

    function parseData() {
      var dataoffset = 1;
      var length = objInfo;
      if (objInfo == 0xF) {
        var int_type = buffer[offset + 1];
        var intType = (int_type & 0xF0) / 0x10;
        if (intType != 0x1) {
          console.error("0x4: UNEXPECTED LENGTH-INT TYPE! " + intType);
        }
        var intInfo = int_type & 0x0F;
        var intLength = Math.pow(2, intInfo);
        dataoffset = 2 + intLength;
        if (intLength < 3) {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        } else {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        }
      }
      if (length < exports.maxObjectSize) {
        return buffer.slice(offset + dataoffset, offset + dataoffset + length);
      } else {
        throw new Error("To little heap space available! Wanted to read " + length + " bytes, but only " + exports.maxObjectSize + " are available.");
      }
    }

    function parsePlistString (isUtf16) {
      isUtf16 = isUtf16 || 0;
      var enc = "utf8";
      var length = objInfo;
      var stroffset = 1;
      if (objInfo == 0xF) {
        var int_type = buffer[offset + 1];
        var intType = (int_type & 0xF0) / 0x10;
        if (intType != 0x1) {
          console.err("UNEXPECTED LENGTH-INT TYPE! " + intType);
        }
        var intInfo = int_type & 0x0F;
        var intLength = Math.pow(2, intInfo);
        var stroffset = 2 + intLength;
        if (intLength < 3) {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        } else {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        }
      }
      // length is String length -> to get byte length multiply by 2, as 1 character takes 2 bytes in UTF-16
      length *= (isUtf16 + 1);
      if (length < exports.maxObjectSize) {
        var plistString = new Buffer(buffer.slice(offset + stroffset, offset + stroffset + length));
        if (isUtf16) {
          plistString = swapBytes(plistString);
          enc = "ucs2";
        }
        return plistString.toString(enc);
      } else {
        throw new Error("To little heap space available! Wanted to read " + length + " bytes, but only " + exports.maxObjectSize + " are available.");
      }
    }

    function parseArray() {
      var length = objInfo;
      var arrayoffset = 1;
      if (objInfo == 0xF) {
        var int_type = buffer[offset + 1];
        var intType = (int_type & 0xF0) / 0x10;
        if (intType != 0x1) {
          console.error("0xa: UNEXPECTED LENGTH-INT TYPE! " + intType);
        }
        var intInfo = int_type & 0x0F;
        var intLength = Math.pow(2, intInfo);
        arrayoffset = 2 + intLength;
        if (intLength < 3) {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        } else {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        }
      }
      if (length * objectRefSize > exports.maxObjectSize) {
        throw new Error("To little heap space available!");
      }
      var array = [];
      for (var i = 0; i < length; i++) {
        var objRef = readUInt(buffer.slice(offset + arrayoffset + i * objectRefSize, offset + arrayoffset + (i + 1) * objectRefSize));
        array[i] = parseObject(objRef);
      }
      return array;
    }

    function parseDictionary() {
      var length = objInfo;
      var dictoffset = 1;
      if (objInfo == 0xF) {
        var int_type = buffer[offset + 1];
        var intType = (int_type & 0xF0) / 0x10;
        if (intType != 0x1) {
          console.error("0xD: UNEXPECTED LENGTH-INT TYPE! " + intType);
        }
        var intInfo = int_type & 0x0F;
        var intLength = Math.pow(2, intInfo);
        dictoffset = 2 + intLength;
        if (intLength < 3) {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        } else {
          length = readUInt(buffer.slice(offset + 2, offset + 2 + intLength));
        }
      }
      if (length * 2 * objectRefSize > exports.maxObjectSize) {
        throw new Error("To little heap space available!");
      }
      if (debug) {
        console.log("Parsing dictionary #" + tableOffset);
      }
      var dict = {};
      for (var i = 0; i < length; i++) {
        var keyRef = readUInt(buffer.slice(offset + dictoffset + i * objectRefSize, offset + dictoffset + (i + 1) * objectRefSize));
        var valRef = readUInt(buffer.slice(offset + dictoffset + (length * objectRefSize) + i * objectRefSize, offset + dictoffset + (length * objectRefSize) + (i + 1) * objectRefSize));
        var key = parseObject(keyRef);
        var val = parseObject(valRef);
        if (debug) {
          console.log("  DICT #" + tableOffset + ": Mapped " + key + " to " + val);
        }
        dict[key] = val;
      }
      return dict;
    }
  }

  return [ parseObject(topObject) ];
};

function readUInt(buffer, start) {
  start = start || 0;

  var l = 0;
  for (var i = start; i < buffer.length; i++) {
    l <<= 8;
    l |= buffer[i] & 0xFF;
  }
  return l;
}

// we're just going to toss the high order bits because javascript doesn't have 64-bit ints
function readUInt64BE(buffer, start) {
  var data = buffer.slice(start, start + 8);
  return data.readUInt32BE(4, 8);
}

function swapBytes(buffer) {
  var len = buffer.length;
  for (var i = 0; i < len; i += 2) {
    var a = buffer[i];
    buffer[i] = buffer[i+1];
    buffer[i+1] = a;
  }
  return buffer;
}
