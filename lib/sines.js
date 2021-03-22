function sine(len, amp, i) {
  return amp * Math.sin((i / len) * Math.PI * 2.0);
}

module.exports = {
  sine01: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center + Math.min(0, sine(len, amp, i))),
  sine02: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center + Math.max(0, sine(len, amp, i))),
  sine03: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center + sine(len, amp, i)),
  sine04: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center - Math.abs(sine(len, amp, i))),
  sine05: ({}, center, amp, len) =>
    Array(len)
      .fill(0)
      .map((v, i) => center + Math.abs(sine(len, amp, i)))
};
