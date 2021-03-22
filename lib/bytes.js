function asc2int(asc) {
  return asc.charCodeAt(0);
}

function asciiToScreencode(asc) {
  if (asc >= 'a' && asc <= 'z') {
    return asc2int(asc) - asc2int('a') + 1;
  }
  if (asc >= 'A' && asc <= 'Z') {
    return asc2int(asc) - asc2int('A') + 0x41;
  }
  if (asc >= '0' && asc <= '9') {
    return asc2int(asc) - asc2int('0') + 0x30;
  }
  const otherChars = {
    '@': 0,
    ' ': 0x20,
    '!': 0x21,
    '"': 0x22,
    '#': 0x23,
    $: 0x24,
    '%': 0x25,
    '&': 0x26,
    "'": 0x27,
    '(': 0x28,
    ')': 0x29,
    '*': 0x2a,
    '+': 0x2b,
    ',': 0x2c,
    '-': 0x2d,
    '.': 0x2e,
    '/': 0x2f,
    ':': 0x3a,
    ';': 0x3b,
    '<': 0x3c,
    '=': 0x3d,
    '>': 0x3e,
    '?': 0x3f
  };
  if (asc in otherChars) {
    return otherChars[asc];
  }
  throw new Error(`Could not convert '${asc}' to screencode`);
}

module.exports = {
  // low byte of n
  lo: ({}, n) => n & 0xff,
  // high byte of n
  hi: ({}, n) => (n >> 8) & 0xff,
  // low, high byte of n
  lohi: ({}, n) => [n & 0xff, (n >> 8) & 0xff],
  // low bytes of array s
  loBytes: ({}, s) => s.map(b => b & 0xff),
  // high bytes of array s
  hiBytes: ({}, s) => s.map(b => (b >> 8) & 0xff),
  // hex formatting of n
  hex: ({}, n) => {
    let pfx = n < 4096 ? '$0' : '$';
    pfx = n < 256 ? `${pfx}0` : pfx;
    pfx = n < 16 ? `${pfx}0` : pfx;
    return `${pfx}${n.toString(16)}`;
  },
  // all bytes from a file
  fromFile: ({ readFileSync, resolveRelative }, filename) => {
    const buf = readFileSync(resolveRelative(filename));
    const result = [];
    for (const v of buf.values()) {
      result.push(v);
    }
    return result;
  },
  // ascii text to screencode
  toScreencode: ({ readFileSync, resolveRelative }, txt) => {
    const buf = readFileSync(resolveRelative(txt));
    const result = [];
    for (const v of buf.values()) {
      result.push(asciiToScreencode(String.fromCharCode(v).toLowerCase().replace('\n', ' ')));
    }
    return result;
  },
  // lo and hi tables for an array of numbers
  lohiBytes: ({}, s) => ({
    loBytes: s.map(b => b & 0xff),
    hiBytes: s.map(b => (b >> 8) & 0xff)
  })
};
