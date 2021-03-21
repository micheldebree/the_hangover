// Koala
function readSegment(buffer, offset, size) {
  const result = [];
  for (let i = 0; i < size; i++) {
    result.push(buffer.readUInt8(offset + i));
  }
  return result;
}

module.exports = ({ readFileSync, resolveRelative }, filename) => {
  const buf = readFileSync(resolveRelative(filename));
  return {
    bitmap: readSegment(buf, 2, 8000),
    screenRam: readSegment(buf, 8002, 1000),
    colorRam: readSegment(buf, 9002, 1000),
    backgroundColor: buf.readUint8(10002)
  };
};
