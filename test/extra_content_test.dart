// Contenido nuevo de las Fases 1 y 3 (ver docs/FASES_1_3.md):
// retos.json (1.5), quien_es_mas_probable.json (3.5) e infiltrado.json (3.9).
//
// Reutiliza la lista negra de content_test.dart y añade una local para los
// retos (riesgo físico). Lee el JSON en crudo, sin pasar por lib/.
import 'package:flutter_test/flutter_test.dart';

import 'content_test.dart' as c;

const retos = 'assets/content/es/retos.json';
const qmp = 'assets/content/es/quien_es_mas_probable.json';
const infiltrado = 'assets/content/es/infiltrado.json';

/// Retos: nada con riesgo físico, comer o beber cosas, ni humillar.
const retosProhibidas = {
  'fuego', 'mechero', 'vela', 'cuchillo', 'tijeras', 'conduce', 'conducir', 'salta',
  'saltar', 'trepa', 'trepar', 'lame', 'lamer', 'escupe', 'escupir', 'traga', 'tragar',
  'come', 'comer', 'cómete', 'ingiere', 'respiración', 'equilibrio',
  'humilla', 'humillar', 'desmaya', 'ahoga', 'ahogar', 'agua', 'vaso', 'vasos',
};
const retosRaices = ['tragu', 'cómet', 'desmay', 'humill', 'asfix'];

/// Ids retirados por fichero (no se reutilizan nunca).
const idsRetirados = <String>{};

/// Validación común de los mazos con `texto`.
void mazoDeTexto(String ruta, String prefijo, {required int minimo, int minimoSuave = 0}) {
  group(ruta, () {
    final lista = c.items(ruta);

    test('cifras', () {
      expect(lista.length, greaterThanOrEqualTo(minimo));
      expect(lista.where((p) => p['nivel'] == 'suave').length, greaterThanOrEqualTo(minimoSuave));
    });

    test('ids únicos, con formato y no retirados', () {
      final ids = lista.map((p) => p['id'] as String).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids duplicados');
      for (final id in ids) {
        expect(RegExp('^${prefijo}_\\d{3}\$').hasMatch(id), isTrue, reason: 'id con formato raro: $id');
        expect(idsRetirados.contains(id), isFalse, reason: 'id retirado reutilizado: $id');
      }
    });

    test('niveles válidos y todos presentes', () {
      for (final p in lista) {
        expect(c.niveles.contains(p['nivel']), isTrue, reason: '${p['id']}: nivel "${p['nivel']}"');
      }
      for (final n in c.niveles) {
        expect(lista.where((p) => p['nivel'] == n), isNotEmpty, reason: 'sin cartas de $n');
      }
    });

    test('texto no vacío y sin repetir', () {
      final vistos = <String>{};
      for (final p in lista) {
        final t = p['texto'];
        expect(t is String && t.trim().isNotEmpty, isTrue, reason: '${p['id']} sin texto');
        expect(vistos.add((t as String).toLowerCase().trim()), isTrue, reason: '${p['id']} repetida');
      }
    });

    test('lista negra: alcohol, drogas, insultos y explícito', () {
      for (final p in lista) {
        final t = p['texto'] as String;
        final mala = c.buscaProhibida(t, c.prohibidasExactas, c.prohibidasRaices) ??
            c.buscaProhibida(t, c.bebidasExactas, const []) ??
            c.buscaProhibida(t, c.explicitasExactas, c.explicitasRaices);
        expect(mala, isNull, reason: '${p['id']}: "$mala" en "$t"');
      }
    });

    test('Picante y Atrevido sin contexto escolar ni de menores', () {
      for (final p in lista.where((p) => p['nivel'] != 'suave')) {
        final t = p['texto'] as String;
        final mala = c.buscaProhibida(t, c.escolarExactas, c.escolarRaices);
        expect(mala, isNull, reason: '${p['id']} (${p['nivel']}): "$mala" en "$t"');
      }
    });

    test('Suave apto para cualquier grupo', () {
      for (final p in lista.where((p) => p['nivel'] == 'suave')) {
        final t = p['texto'] as String;
        final mala = c.buscaProhibida(t, c.noSuaveExactas, const []);
        expect(mala, isNull, reason: '${p['id']} (suave): "$mala" en "$t"');
      }
    });
  });
}

void main() {
  test('la lista negra de retos detecta lo que debe', () {
    expect(c.buscaProhibida('cómete una guindilla', retosProhibidas, retosRaices), isNotNull);
    expect(c.buscaProhibida('salta desde el sofá', retosProhibidas, retosRaices), 'salta');
    expect(c.buscaProhibida('canta el estribillo', retosProhibidas, retosRaices), isNull);
  });

  // 1.5: ~80 retos.
  mazoDeTexto(retos, 'rt', minimo: 80, minimoSuave: 40);

  test('$retos: sin riesgo físico ni humillación', () {
    for (final p in c.items(retos)) {
      final t = p['texto'] as String;
      final mala = c.buscaProhibida(t, retosProhibidas, retosRaices);
      expect(mala, isNull, reason: '${p['id']}: "$mala" en "$t"');
    }
  });

  // 3.5: ~120 cartas, 50 o más en Suave. El texto va sin el prefijo
  // "¿Quién es más probable que" y sin la "?".
  mazoDeTexto(qmp, 'qmp', minimo: 120, minimoSuave: 50);

  test('$qmp: sin prefijo ni interrogación', () {
    for (final p in c.items(qmp)) {
      final t = p['texto'] as String;
      expect(t.contains('?') || t.contains('¿'), isFalse, reason: '${p['id']}: "$t"');
      expect(t.toLowerCase().startsWith('quién'), isFalse, reason: '${p['id']}: "$t"');
      expect(t, t.trim(), reason: '${p['id']}: espacios sobrantes');
      expect(t.endsWith('.'), isFalse, reason: '${p['id']}: punto final');
    }
  });

  // 3.9: El Infiltrado.
  group(infiltrado, () {
    final lista = c.items(infiltrado);

    test('150 palabras o más, casi todas en Suave, en 10 categorías o más', () {
      expect(lista.length, greaterThanOrEqualTo(150));
      final suaves = lista.where((p) => p['nivel'] == 'suave');
      expect(suaves.length, greaterThanOrEqualTo(150));
      final categorias = suaves.map((p) => p['categoria']).toSet();
      expect(categorias.length, greaterThanOrEqualTo(10));
    });

    test('ids únicos y con formato', () {
      final ids = lista.map((p) => p['id'] as String).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids duplicados');
      for (final id in ids) {
        expect(RegExp(r'^inf_\d{3}$').hasMatch(id), isTrue, reason: 'id con formato raro: $id');
        expect(idsRetirados.contains(id), isFalse, reason: 'id retirado reutilizado: $id');
      }
    });

    test('niveles válidos', () {
      for (final p in lista) {
        expect(c.niveles.contains(p['nivel']), isTrue, reason: '${p['id']}: nivel "${p['nivel']}"');
      }
    });

    test('palabra y categoría no vacías, solo campos de texto', () {
      for (final p in lista) {
        for (final campo in ['palabra', 'categoria']) {
          final v = p[campo];
          expect(v is String && v.trim().isNotEmpty, isTrue, reason: '${p['id']} sin "$campo"');
        }
        for (final v in p.values) {
          expect(v, isA<String>(), reason: '${p['id']}: parsePrompts solo admite texto');
        }
      }
    });

    test('palabras sin duplicar', () {
      final vistas = <String>{};
      for (final p in lista) {
        final w = (p['palabra'] as String).toLowerCase().trim();
        expect(vistas.add(w), isTrue, reason: '${p['id']}: "$w" repetida');
      }
    });

    test('lista negra', () {
      for (final p in lista) {
        final t = '${p['categoria']} ${p['palabra']}';
        final mala = c.buscaProhibida(t, c.prohibidasExactas, c.prohibidasRaices) ??
            c.buscaProhibida(t, c.bebidasExactas, const []) ??
            c.buscaProhibida(t, c.explicitasExactas, c.explicitasRaices) ??
            (p['nivel'] == 'suave' ? c.buscaProhibida(t, c.noSuaveExactas, const []) : null);
        expect(mala, isNull, reason: '${p['id']}: "$mala" en "$t"');
      }
    });
  });
}
