function readWord(buf, offs) {
  return buf.readUInt8(offs) + (buf.readUInt8(offs + 1) << 8);
}

function readWordBE(buf, offs) {
  return (buf.readUInt8(offs) << 8) + buf.readUInt8(offs + 1);
}

module.exports = ({ readFileSync, resolveRelative }, filename) => {
  const buf = readFileSync(resolveRelative(filename));
  // const version = readWordBE(buf, 4);
  const dataOffset = readWordBE(buf, 6);
  const location = readWord(buf, dataOffset);
  const init = readWordBE(buf, 0x0a);
  const play = readWordBE(buf, 0x0c);
  // const numSongs = readWord(buf, 0x0e);
  const res = {
    location,
    data: [...buf.slice(dataOffset + 2)],
    init,
    play
  };
  return res;
};
