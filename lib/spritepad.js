// Spritepad files
// v1: v1.8.1 files
// v2: v2.0 beta files

function loadV1(buf, filename) {
  const data = [...buf.slice(3)];
  const numberOfSprites = Math.floor(data.length / 64);
  console.log(`${numberOfSprites} Spritepad v1 sprites loaded from ${filename}`);
  return {
    numberOfSprites,
    backgroundcolor: buf.readInt8(0),
    multicolor1: buf.readInt8(1),
    multicolor2: buf.readInt8(2),
    data
  };
}

// TODO: untested
function loadV2(buf, filename) {
  const numberOfSprites = buf.readUInt8(4) + 1;
  const data = [...buf.slice(9)];
  console.log(`${numberOfSprites} Spritepad v2 sprites loaded from ${filename}`);
  return {
    numberOfSprites,
    enableMask: (1 << numberOfSprites) - 1,
    backgroundcolor: buf.readUInt8(6),
    multicolor1: buf.readUInt8(7),
    multicolor2: buf.readUInt8(8),
    data
  };
}

module.exports = {
  loadV1: ({ readFileSync, resolveRelative }, filename) => loadV1(readFileSync(resolveRelative(filename)), filename),
  loadV2: ({ readFileSync, resolveRelative }, filename) => loadV2(readFileSync(resolveRelative(filename)), filename)
};
