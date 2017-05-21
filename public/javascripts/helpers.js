function randRange(min, max) {
  return Math.floor(Math.random()*(max-min)) + min;
}

function map(n, start1, stop1, start2, stop2) {
  return ((n-start1)/(stop1-start1))*(stop2-start2)+start2;
};

function colorToHex(r, g, b) {
  r = r.toString(16);
  g = g.toString(16);
  b = b.toString(16);
  var color = "#" + r + g + b;
  return color;
}

