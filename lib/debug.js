module.exports = {
  log({}, ...s) {
    console.log(s.reduce((a, e) => a + e));
  }
};
