// Genera por código (síntesis aditiva, sin muestras de terceros) los sonidos de
// acierto y fallo de Trivia y Geografía: assets/audio/correct.wav y wrong.wav.
//
// Uso: node tools/audio/gen_aciertos.mjs   (desde la raíz del repositorio)
//
// - correct: arpegio mayor ascendente Do5-Mi5-Sol5-Do6 con timbre de campanilla
//   suave (fundamental + armónicos que decaen antes), ataque de 6 ms para evitar
//   clics, última nota más larga y un eco suave que le da cuerpo.
// - wrong: dos notas descendentes y apagadas (Sol4 -> Mi4), sin armónicos
//   agudos ni ataque duro: avisa sin castigar.
// Salida: WAV PCM 16 bit mono a 44,1 kHz. Obra propia, sin licencia de terceros.
import fs from 'node:fs';
import path from 'node:path';

const SR = 44100;

/** Una nota con envolvente: ataque coseno, decaimiento exponencial y cola corta. */
function note(buf, { start, freq, dur, tau, gain, partials, glide = 0 }) {
  const n = Math.floor(dur * SR);
  const s0 = Math.floor(start * SR);
  const attack = Math.floor(0.006 * SR);
  const release = Math.floor(0.03 * SR);
  let phase = [];
  for (let i = 0; i < n && s0 + i < buf.length; i++) {
    const t = i / SR;
    const f = freq * (1 + glide * t);
    let env = Math.exp(-t / tau);
    if (i < attack) env *= 0.5 - 0.5 * Math.cos((Math.PI * i) / attack);
    if (i > n - release) env *= (n - i) / release;
    let v = 0;
    partials.forEach(([mult, amp, decayMult], k) => {
      phase[k] = (phase[k] ?? 0) + (2 * Math.PI * f * mult) / SR;
      v += amp * Math.exp(-t / (tau * decayMult)) * Math.sin(phase[k]);
    });
    buf[s0 + i] += gain * env * v;
  }
}

/** Eco suave (un solo rebote) para dar cuerpo sin reverb. */
function echo(buf, delay, gain) {
  const d = Math.floor(delay * SR);
  for (let i = buf.length - 1; i >= d; i--) buf[i] += buf[i - d] * gain;
}

function normalize(buf, peak) {
  let m = 0;
  for (const x of buf) m = Math.max(m, Math.abs(x));
  for (let i = 0; i < buf.length; i++) buf[i] = (buf[i] / m) * peak;
}

function wav(buf) {
  const data = Buffer.alloc(buf.length * 2);
  buf.forEach((x, i) => data.writeInt16LE(Math.round(Math.max(-1, Math.min(1, x)) * 32767), i * 2));
  const h = Buffer.alloc(44);
  h.write('RIFF', 0);
  h.writeUInt32LE(36 + data.length, 4);
  h.write('WAVEfmt ', 8);
  h.writeUInt32LE(16, 16);
  h.writeUInt16LE(1, 20); // PCM
  h.writeUInt16LE(1, 22); // mono
  h.writeUInt32LE(SR, 24);
  h.writeUInt32LE(SR * 2, 28);
  h.writeUInt16LE(2, 32);
  h.writeUInt16LE(16, 34);
  h.write('data', 36);
  h.writeUInt32LE(data.length, 40);
  return Buffer.concat([h, data]);
}

// Campanilla: fundamental + 2.º y 3.er armónico (decaen antes) + 4.º muy leve.
const bell = [
  [1, 1.0, 1.0],
  [2, 0.28, 0.55],
  [3, 0.1, 0.35],
  [4, 0.04, 0.25],
];

// --- acierto: Do mayor, Do5 Mi5 Sol5 Do6 ---
const ok = new Float64Array(Math.floor(1.3 * SR));
[
  [0.0, 523.25, 0.14, 0.7],
  [0.075, 659.25, 0.14, 0.75],
  [0.15, 783.99, 0.16, 0.8],
  [0.225, 1046.5, 0.5, 1.0],
].forEach(([start, freq, tau, gain], i, all) =>
  note(ok, {
    start,
    freq,
    dur: i === all.length - 1 ? 0.85 : 0.5,
    tau,
    gain,
    partials: bell,
  }),
);
echo(ok, 0.13, 0.22);
normalize(ok, 0.8);

// --- fallo: Sol4 -> Mi4, apagado y corto ---
const soft = [
  [1, 1.0, 1.0],
  [2, 0.12, 0.5],
];
const ko = new Float64Array(Math.floor(0.6 * SR));
note(ko, { start: 0.0, freq: 392.0, dur: 0.3, tau: 0.1, gain: 0.7, partials: soft, glide: -0.05 });
note(ko, { start: 0.12, freq: 329.63, dur: 0.46, tau: 0.16, gain: 0.8, partials: soft, glide: -0.06 });
normalize(ko, 0.7);

const out = path.resolve('assets/audio');
fs.writeFileSync(path.join(out, 'correct.wav'), wav(ok));
fs.writeFileSync(path.join(out, 'wrong.wav'), wav(ko));
console.log('correct.wav', ok.length, 'muestras;', 'wrong.wav', ko.length, 'muestras');
