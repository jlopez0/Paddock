// Recorta un Ogg Vorbis desde un segundo dado, copiando las cabeceras y las páginas
// posteriores (sin recodificar). Uso: node cut_ogg.mjs entrada.ogg salida.ogg segundo
import fs from 'node:fs';

const [inp, out, startSec] = process.argv.slice(2);
const buf = fs.readFileSync(inp);

const table = new Uint32Array(256);
for (let i = 0; i < 256; i++) {
  let r = i << 24;
  for (let k = 0; k < 8; k++) r = r & 0x80000000 ? (r << 1) ^ 0x04c11db7 : r << 1;
  table[i] = r >>> 0;
}
const crc = (b) => {
  let c = 0;
  for (const x of b) c = ((c << 8) ^ table[((c >>> 24) ^ x) & 0xff]) >>> 0;
  return c;
};

const pages = [];
for (let o = 0; o < buf.length; ) {
  if (buf.toString('latin1', o, o + 4) !== 'OggS') throw new Error('Ogg inválido en ' + o);
  const n = buf[o + 26];
  let body = 0;
  for (let i = 0; i < n; i++) body += buf[o + 27 + i];
  const len = 27 + n + body;
  pages.push({ data: Buffer.from(buf.subarray(o, o + len)), granule: buf.readBigInt64LE(o + 6), flags: buf[o + 5] });
  o += len;
}
const rate = pages[0].data.readUInt32LE(27 + pages[0].data[26] + 12);
const startGranule = BigInt(Math.round(Number(startSec) * rate));
let firstAudio = pages.findIndex((p, i) => i > 0 && p.granule > 0n);
const cut = pages.findIndex((p) => p.granule >= startGranule && !(p.flags & 1));
if (cut < 0) throw new Error('No hay punto de corte');
const kept = [...pages.slice(0, firstAudio), ...pages.slice(cut)];
kept.forEach((p, i) => {
  p.data.writeUInt32LE(i, 18); // nº de secuencia
  p.data.writeUInt32LE(0, 22);
  p.data.writeUInt32LE(crc(p.data), 22);
});
fs.writeFileSync(out, Buffer.concat(kept.map((p) => p.data)));
console.log(`rate ${rate} · páginas ${kept.length}/${pages.length} · ${(fs.statSync(out).size / 1e6).toFixed(1)} MB`);
