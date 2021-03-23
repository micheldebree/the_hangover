function sine(len, amp, i) {
  return amp * Math.sin((i / len) * Math.PI);
}

module.exports = {
  sine01: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center - sine(len, amp, i))
};
