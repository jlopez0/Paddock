// Genera los mapas de divisiones administrativas (estados, provincias…).
//
// Uso:  node tools/geo/build_maps.mjs <carpeta_fuentes>
//
// <carpeta_fuentes>/admin1.geojson = Natural Earth ne_10m_admin_1_states_provinces (dominio público).
// Configuración: tools/geo/maps.json.  Salida: assets/content/es/geografia/mapas/<id>.json
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { bbox, centroid, mainCluster, polygonsOf, ringArea, simplify } from './geom.mjs';

const src = process.argv[2];
if (!src) throw new Error('Falta la carpeta de fuentes');
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const config = JSON.parse(fs.readFileSync(path.join(root, 'tools/geo/maps.json'), 'utf8'));
const features = JSON.parse(fs.readFileSync(path.join(src, 'admin1.geojson'), 'utf8')).features;

const SIZE = 2000; // lado mayor del mapa en unidades de salida
const TOLERANCE = 1.6; // simplificación, en unidades de salida
const MAX_GAP_DEG = 1.5; // islas a más distancia de su región no se dibujan
const MIN_RATIO = 0.01; // islas menores que esto (vs. la mayor de la región) se omiten

const rad = (d) => (d * Math.PI) / 180;
const stripMacrons = (s) => s.normalize('NFD').replace(/[̄]/g, '').normalize('NFC');

function projection(p, refLat) {
  if (p.tipo === 'albers') {
    const [l0, f0, f1, f2] = [rad(p.lon0), rad(p.lat0), rad(p.lat1), rad(p.lat2)];
    const n = (Math.sin(f1) + Math.sin(f2)) / 2;
    const C = Math.cos(f1) ** 2 + 2 * n * Math.sin(f1);
    const rho0 = Math.sqrt(C - 2 * n * Math.sin(f0)) / n;
    return ([lon, lat]) => {
      const rho = Math.sqrt(C - 2 * n * Math.sin(rad(lat))) / n;
      const th = n * (rad(lon) - l0);
      return [rho * Math.sin(th), -(rho0 - rho * Math.cos(th))];
    };
  }
  const k = Math.cos(rad(refLat));
  return ([lon, lat]) => [rad(lon) * k, -rad(lat)];
}

const outDir = path.join(root, 'assets/content/es/geografia/mapas');
fs.mkdirSync(outDir, { recursive: true });

for (const [id, cfg] of Object.entries(config)) {
  if (id.startsWith('_')) continue;
  const excluded = new Set(cfg.excluir);
  const insetOf = {};
  for (const [name, inset] of Object.entries(cfg.insets)) for (const r of inset.ids) insetOf[r] = name;

  // 1. Regiones con sus polígonos (sin islas lejanas).
  const regions = features
    .filter((f) => f.properties.adm0_a3 === cfg.adm0 && !excluded.has(f.properties.iso_3166_2))
    .map((f) => {
      let polys = polygonsOf(f.geometry);
      if (cfg.antimeridiano) {
        const shift = (r) => r.map(([x, y]) => [x > 0 ? x - 360 : x, y]);
        polys = polys.map((p) => ({ outer: shift(p.outer), holes: p.holes.map(shift) }));
      }
      return { f, iso: f.properties.iso_3166_2, polys: mainCluster(polys, { maxGapDeg: MAX_GAP_DEG, minRatio: MIN_RATIO }) };
    });

  // 2. Proyección del mapa principal.
  const main = regions.filter((r) => !insetOf[r.iso]);
  const mainLats = main.flatMap((r) => r.polys.flatMap((p) => p.outer.map((c) => c[1])));
  const proj = projection(cfg.proyeccion, (Math.min(...mainLats) + Math.max(...mainLats)) / 2);
  const projected = new Map(); // iso → [{outer, holes}] proyectados
  const projectRegion = (r, fn) => projected.set(r.iso, r.polys.map((p) => ({ outer: p.outer.map(fn), holes: p.holes.map((h) => h.map(fn)) })));
  for (const r of main) projectRegion(r, proj);
  const mb = bbox(main.flatMap((r) => projected.get(r.iso).flatMap((p) => p.outer)));
  const [mw, mh] = [mb.x1 - mb.x0, mb.y1 - mb.y0];

  // 3. Recuadros: cada grupo con su propia proyección, encajado en su rectángulo.
  const frames = [];
  for (const inset of Object.values(cfg.insets)) {
    const group = regions.filter((r) => inset.ids.includes(r.iso));
    const lats = group.flatMap((r) => r.polys.flatMap((p) => p.outer.map((c) => c[1])));
    const local = projection({ tipo: 'plana' }, (Math.min(...lats) + Math.max(...lats)) / 2);
    const gb = bbox(group.flatMap((r) => r.polys.flatMap((p) => p.outer.map(local))));
    const [fx, fy, fw, fh] = inset.rect;
    const rect = { x: mb.x0 + fx * mw, y: mb.y0 + fy * mh, w: fw * mw, h: fh * mh };
    const s = Math.min(rect.w / (gb.x1 - gb.x0), rect.h / (gb.y1 - gb.y0)) * 0.88;
    const ox = rect.x + (rect.w - (gb.x1 - gb.x0) * s) / 2;
    const oy = rect.y + (rect.h - (gb.y1 - gb.y0) * s) / 2;
    const fn = (c) => { const [x, y] = local(c); return [ox + (x - gb.x0) * s, oy + (y - gb.y0) * s]; };
    for (const r of group) projectRegion(r, fn);
    frames.push(rect);
  }

  // 4. Normalización a SIZE y simplificación.
  const all = [...projected.values()].flatMap((ps) => ps.flatMap((p) => p.outer));
  const ab = bbox([...all, ...frames.flatMap((f) => [[f.x, f.y], [f.x + f.w, f.y + f.h]])]);
  const scale = SIZE / Math.max(ab.x1 - ab.x0, ab.y1 - ab.y0);
  const T = ([x, y]) => [(x - ab.x0) * scale, (y - ab.y0) * scale];
  const flat = (ring) => ring.flatMap(([x, y]) => [Math.round(x), Math.round(y)]);

  const out = [];
  for (const r of regions) {
    const rings = [];
    let biggest = null, biggestArea = -1;
    for (const p of projected.get(r.iso)) {
      const outer = p.outer.map(T);
      const area = ringArea(outer);
      if (area > biggestArea) { biggestArea = area; biggest = outer; }
      const s = simplify(outer, TOLERANCE);
      if (s.length >= 3) rings.push(flat(s));
      for (const h of p.holes) {
        const hs = simplify(h.map(T), TOLERANCE);
        if (hs.length >= 3 && ringArea(h.map(T)) > area * 0.01) rings.push(flat(hs));
      }
    }
    const props = r.f.properties;
    const o = cfg.nombres[r.iso] ?? {};
    const name = o.n ?? stripMacrons(props.name_es ?? props.name);
    const aliases = [...new Set([...(o.a ?? []), stripMacrons(props.name), stripMacrons(props.name_es ?? ''), props.name_en ?? ''])]
      .filter((a) => a && a.toLowerCase() !== name.toLowerCase() && !(o.quitar ?? []).includes(a));
    const [cx, cy] = centroid(biggest);
    const region = { id: r.iso, nombre: name, c: [Math.round(cx), Math.round(cy)], p: rings };
    if (aliases.length) region.alias = aliases;
    out.push(region);
  }
  out.sort((a, b) => a.nombre.localeCompare(b.nombre, 'es'));

  const data = {
    version: 1,
    id,
    titulo: cfg.titulo,
    pregunta: cfg.pregunta,
    bandera: cfg.bandera,
    w: Math.round((ab.x1 - ab.x0) * scale),
    h: Math.round((ab.y1 - ab.y0) * scale),
    recuadros: frames.map((f) => [...T([f.x, f.y]), f.w * scale, f.h * scale].map(Math.round)),
    regiones: out,
  };
  const file = path.join(outDir, `${id}.json`);
  fs.writeFileSync(file, JSON.stringify(data));
  console.log(`${id}: ${out.length} regiones · ${data.w}x${data.h} · ${(fs.statSync(file).size / 1024).toFixed(0)} KB`);
}
