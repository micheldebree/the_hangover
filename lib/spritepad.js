// Spritepad files
// v1: v1.8.1 files
// v2: v2.0 beta files

function loadV1(buf) {
  // const backgroundcolor = buf.readUInt8(0);
  // const multicolor1 = buf.readUInt8(1);
  // const multicolor2 = buf.readUInt8(2);
  const data = [...buf.slice(3)];
  const numberOfSprites = Math.floor(data.length / 64);
  return {
    numberOfSprites,
    backgroundcolor: buf.readInt8(0),
    multicolor1: buf.readInt8(1),
    multicolor2: buf.readInt8(2),
    data
  };
}

function loadV2(buf) {
  const numSprites = buf.readUInt8(4) + 1;
  const data = [];
  for (let i = 0; i < numSprites; i++) {
    const offs = i * 64 + 9;
    const bytes = [];
    for (let j = 0; j < 64; j++) {
      bytes.push(buf.readUInt8(offs + j));
    }
    data.push(bytes);
  }
  return {
    numSprites,
    enableMask: (1 << numSprites) - 1,
    bg: buf.readUInt8(6),
    multicol1: buf.readUInt8(7),
    multicol2: buf.readUInt8(8),
    data
  };
}

module.exports = {
  loadV1: ({ readFileSync, resolveRelative }, filename) => loadV1(readFileSync(resolveRelative(filename))),
  loadV2: ({ readFileSync, resolveRelative }, filename) => loadV2(readFileSync(resolveRelative(filename)))
};
