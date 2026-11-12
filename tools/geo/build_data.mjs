// Genera el dataset de Geografía a partir de datos abiertos.
//
// Uso:  node tools/geo/build_data.mjs <carpeta_fuentes>
//
// <carpeta_fuentes> debe contener (ver créditos en la app):
//   countries.geojson   Natural Earth ne_50m_admin_0_countries   (dominio público)
//   places.geojson      Natural Earth ne_10m_populated_places    (dominio público)
//   flagpkg/package/    paquete npm flag-icons 7.2.3             (MIT)
//
// Genera:
//   assets/content/es/geografia/paises.json
//   assets/geo/siluetas.json
//   assets/geo/flags/<iso>.svg
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const src = process.argv[2];
if (!src) throw new Error('Falta la carpeta de fuentes');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const overrides = JSON.parse(fs.readFileSync(path.join(root, 'tools/geo/overrides.json'), 'utf8'));

// 193 estados miembros de la ONU (códigos ISO 3166-1 alfa-2).
const UN = `AF AL DZ AD AO AG AR AM AU AT AZ BS BH BD BB BY BE BZ BJ BT BO BA BW BR BN BG BF BI CV KH CM CA CF TD CL CN CO KM CG CD CR CI HR CU CY CZ DK DJ DM DO EC EG SV GQ ER EE SZ ET FJ FI FR GA GM GE DE GH GR GD GT GN GW GY HT HN HU IS IN ID IR IQ IE IL IT JM JP JO KZ KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MG MW MY MV ML MT MH MR MU MX FM MD MC MN ME MA MZ MM NA NR NP NL NZ NI NE NG MK NO OM PK PW PA PG PY PE PH PL PT QA RO RU RW KN LC VC WS SM ST SA SN RS SC SL SG SK SI SB SO ZA SS ES LK SD SR SE CH SY TJ TZ TH TL TG TO TT TN TR TM TV UG UA AE GB US UY UZ VU VE VN YE ZM ZW`.split(/\s+/);
if (UN.length !== 193) throw new Error(`Se esperaban 193 países y hay ${UN.length}`);

const CONTINENT = {
  Europe: 'europa', Asia: 'asia', Africa: 'africa',
  'North America': 'america', 'South America': 'america', Oceania: 'oceania',
};

// Solo el mayor polígono (evita incluir territorios lejanos).
const MAIN_ONLY = new Set(['NO']);
const CLUSTER_GAP_DEG = 6; // islas a más de esto del grupo principal no se dibujan
const MIN_AREA_RATIO = 0.008; // islas menores que esto (vs. la mayor) se omiten
const SILHOUETTE_MIN_KM2 = 10000; // países más pequeños no tienen silueta reconocible
const FLAG_DIR = path.join(src, 'flagpkg/package/flags/4x3');

const countries = JSON.parse(fs.readFileSync(path.join(src, 'countries.geojson'), 'utf8')).features;
const places = JSON.parse(fs.readFileSync(path.join(src, 'places.geojson'), 'utf8')).features
  .map((f) => f.properties)
  .filter((p) => p.ADM0CAP === 1);

// ---------- geometría ----------
const ringArea = (ring) => {
  let s = 0;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    s += (ring[j][0] + ring[i][0]) * (ring[j][1] - ring[i][1]);
  }
  return Math.abs(s) / 2;
};
const polyAreaKm2 = (outer) => {
  const lat = outer.reduce((a, p) => a + p[1], 0) / outer.length;
  return ringArea(outer) * Math.cos((lat * Math.PI) / 180) * 111.19 ** 2;
};
const bbox = (ring) => {
  let [x0, y0, x1, y1] = [Infinity, Infinity, -Infinity, -Infinity];
  for (const [x, y] of ring) { x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y); }
  return { x0, y0, x1, y1 };
};
const gap = (a, b) => Math.hypot(Math.max(0, a.x0 - b.x1, b.x0 - a.x1), Math.max(0, a.y0 - b.y1, b.y0 - a.y1));

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

// Los anillos están cerrados (primer punto = último): se parten por el punto más lejano.
function simplify(ring, tol) {
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

function silhouette(geom, iso) {
  let polys = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
  polys = polys.map((p) => ({ outer: p[0], holes: p.slice(1) }));

  // Países que cruzan el antimeridiano (Rusia, Fiyi…).
  const lons = polys.flatMap((p) => p.outer.map((c) => c[0]));
  if (Math.min(...lons) < -160 && Math.max(...lons) > 160) {
    for (const p of polys) {
      const shift = (r) => r.map(([x, y]) => [x < 0 ? x + 360 : x, y]);
      p.outer = shift(p.outer);
      p.holes = p.holes.map(shift);
    }
  }
  for (const p of polys) { p.box = bbox(p.outer); p.km2 = polyAreaKm2(p.outer); }
  const totalKm2 = polys.reduce((a, p) => a + p.km2, 0);
  polys.sort((a, b) => b.km2 - a.km2);

  // Grupo conexo (por cercanía) alrededor del polígono mayor.
  let kept = [polys[0]];
  if (!MAIN_ONLY.has(iso)) {
    let grew = true;
    while (grew) {
      grew = false;
      for (const p of polys) {
        if (!kept.includes(p) && kept.some((k) => gap(k.box, p.box) <= CLUSTER_GAP_DEG)) { kept.push(p); grew = true; }
      }
    }
    kept = kept.filter((p, i) => p === polys[0] || p.km2 >= polys[0].km2 * MIN_AREA_RATIO);
  }

  const all = kept.flatMap((p) => p.outer);
  const b = bbox(all);
  const midLat = (b.y0 + b.y1) / 2;
  const k = Math.cos((midLat * Math.PI) / 180);
  const w = (b.x1 - b.x0) * k, h = b.y1 - b.y0;
  const scale = 1000 / Math.max(w, h);
  const project = (r) => r.map(([x, y]) => [(x - b.x0) * k * scale, (b.y1 - y) * scale]);

  const rings = [];
  for (const p of kept) {
    const outer = simplify(project(p.outer), 2.2);
    if (outer.length < 4) continue;
    rings.push(outer);
    for (const hole of p.holes) {
      const hp = project(hole);
      if (ringArea(hp) < ringArea(project(p.outer)) * 0.003) continue;
      const s = simplify(hp, 2.2);
      if (s.length >= 4) rings.push(s);
    }
  }
  return {
    ok: totalKm2 >= SILHOUETTE_MIN_KM2 && rings.length > 0,
    shape: {
      w: Math.round(w * scale),
      h: Math.round(h * scale),
      p: rings.map((r) => r.flatMap(([x, y]) => [Math.round(x), Math.round(y)])),
    },
  };
}

// ---------- construcción ----------
const items = [];
const shapes = {};
const problems = [];

for (const iso of UN) {
  // Varias entidades comparten ISO_A2_EH (p. ej. Ashmore y Cartier con AU): gana la más poblada.
  const feature = countries
    .filter((f) => f.properties.ISO_A2_EH === iso)
    .sort((a, b) => b.properties.POP_EST - a.properties.POP_EST)[0];
  if (!feature) { problems.push(`${iso}: sin país en Natural Earth`); continue; }
  const p = feature.properties;
  const o = overrides[iso] ?? {};

  const capitals = places.filter((x) => x.ADM0_A3 === p.ADM0_A3);
  const capital = o.c ?? capitals[0]?.NAME_ES;
  if (!capital) problems.push(`${iso} ${p.NAME_ES}: sin capital`);
  if (!o.c && capitals.length > 1) problems.push(`${iso} ${p.NAME_ES}: varias capitales (${capitals.map((c) => c.NAME_ES).join(' / ')}) → usando ${capital}`);

  const continente = o.k ?? CONTINENT[p.CONTINENT];
  if (!continente) problems.push(`${iso} ${p.NAME_ES}: continente "${p.CONTINENT}" sin asignar`);

  const sil = silhouette(feature.geometry, iso);
  if (sil.ok) shapes[iso] = sil.shape;

  const flagFile = path.join(FLAG_DIR, `${iso.toLowerCase()}.svg`);
  if (!fs.existsSync(flagFile)) problems.push(`${iso}: sin bandera`);

  const item = {
    iso,
    nombre: o.n ?? p.NAME_ES,
    capital,
    continente,
    poblacion: Math.round(p.POP_EST),
    silueta: sil.ok,
  };
  if (o.a) item.alias = o.a;
  if (o.ca) item.aliasCapital = o.ca;
  items.push(item);
}

items.sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));

// ---------- salida ----------
const outContent = path.join(root, 'assets/content/es/geografia');
const outGeo = path.join(root, 'assets/geo');
fs.mkdirSync(outContent, { recursive: true });
fs.mkdirSync(path.join(outGeo, 'flags'), { recursive: true });
fs.writeFileSync(path.join(outContent, 'paises.json'), JSON.stringify({ version: 1, items }, null, 1));
fs.writeFileSync(path.join(outGeo, 'siluetas.json'), JSON.stringify(shapes));
for (const { iso } of items) {
  fs.copyFileSync(path.join(FLAG_DIR, `${iso.toLowerCase()}.svg`), path.join(outGeo, 'flags', `${iso.toLowerCase()}.svg`));
}

const kb = (f) => (fs.statSync(f).size / 1024).toFixed(0);
console.log(`${items.length} países · ${Object.keys(shapes).length} con silueta`);
console.log(`paises.json ${kb(path.join(outContent, 'paises.json'))} KB · siluetas.json ${kb(path.join(outGeo, 'siluetas.json'))} KB`);
const flagBytes = items.reduce((a, { iso }) => a + fs.statSync(path.join(outGeo, 'flags', `${iso.toLowerCase()}.svg`)).size, 0);
console.log(`banderas ${(flagBytes / 1024).toFixed(0)} KB`);
console.log(problems.length ? 'AVISOS:\n' + problems.join('\n') : 'Sin avisos');
