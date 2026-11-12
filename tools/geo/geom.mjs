// Utilidades de geometría compartidas por los generadores de datos.

export const ringArea = (ring) => {
  let s = 0;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    s += (ring[j][0] + ring[i][0]) * (ring[j][1] - ring[i][1]);
  }
  return Math.abs(s) / 2;
};

/// Área aproximada en km² de un anillo en grados lon/lat.
export const polyAreaKm2 = (outer) => {
  const lat = outer.reduce((a, p) => a + p[1], 0) / outer.length;
  return ringArea(outer) * Math.cos((lat * Math.PI) / 180) * 111.19 ** 2;
};

export const bbox = (ring) => {
  let [x0, y0, x1, y1] = [Infinity, Infinity, -Infinity, -Infinity];
  for (const [x, y] of ring) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  return { x0, y0, x1, y1 };
};

export const gap = (a, b) => Math.hypot(Math.max(0, a.x0 - b.x1, b.x0 - a.x1), Math.max(0, a.y0 - b.y1, b.y0 - a.y1));

// Douglas-Peucker sobre una polilínea abierta.
function simplifyOpen(points, tol) {
  const keep = new Uint8Array(points.length);
  keep[0] = keep[points.length - 1] = 1;
  const stack = [[0, points.length - 1]];
  while (stack.length) {
    const [a, b] = stack.pop();
    let max = 0, idx = -1;
    const [ax, ay] = points[a], [bx, by] = points[b];
    const dx = bx - ax, dy = by - ay, len = Math.hypot(dx, dy) || 1;
    for (let i = a + 1; i < b; i++) {
      const d = Math.abs(dy * points[i][0] - dx * points[i][1] + bx * ay - by * ax) / len;
      if (d > max) { max = d; idx = i; }
    }
    if (max > tol) { keep[idx] = 1; stack.push([a, idx], [idx, b]); }
  }
  return points.filter((_, i) => keep[i]);
}

/// Simplifica un anillo cerrado (primer punto = último) partiéndolo por el punto más lejano.
export function simplify(ring, tol) {
  const pts = ring.slice(0, -1);
  let m = 0, far = -1;
  pts.forEach(([x, y], i) => {
    const d = Math.hypot(x - pts[0][0], y - pts[0][1]);
    if (d > far) { far = d; m = i; }
  });
  const a = simplifyOpen(pts.slice(0, m + 1), tol);
  const b = simplifyOpen([...pts.slice(m), pts[0]], tol);
  return [...a, ...b.slice(1, -1)];
}

/// Polígonos de una geometría GeoJSON como {outer, holes}.
export const polygonsOf = (geom) =>
  (geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates).map((p) => ({ outer: p[0], holes: p.slice(1) }));

/// Se queda con el polígono mayor y los que, siendo al menos `minRatio` de su área,
/// están encadenados a él a menos de `maxGapDeg` grados (descarta islas lejanas).
export function mainCluster(polys, { maxGapDeg, minRatio }) {
  for (const p of polys) { p.box = bbox(p.outer); p.km2 = polyAreaKm2(p.outer); }
  const sorted = [...polys].sort((a, b) => b.km2 - a.km2);
  const big = sorted.filter((p) => p === sorted[0] || p.km2 >= sorted[0].km2 * minRatio);
  const kept = [sorted[0]];
  let grew = true;
  while (grew) {
    grew = false;
    for (const p of big) {
      if (!kept.includes(p) && kept.some((k) => gap(k.box, p.box) <= maxGapDeg)) { kept.push(p); grew = true; }
    }
  }
  return kept;
}

/// Centroide (por área) de un anillo en coordenadas planas.
export function centroid(ring) {
  let a = 0, cx = 0, cy = 0;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const f = ring[j][0] * ring[i][1] - ring[i][0] * ring[j][1];
    a += f; cx += (ring[j][0] + ring[i][0]) * f; cy += (ring[j][1] + ring[i][1]) * f;
  }
  if (Math.abs(a) < 1e-9) return ring[0];
  return [cx / (3 * a), cy / (3 * a)];
}
