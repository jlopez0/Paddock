// Comprueba el contenido de assets/content/es/ (ver docs/CONTENIDO.md).
//
// Lee el JSON en crudo, sin pasar por el código de la app, para que el
// contenido se pueda validar aunque el modelo de datos cambie.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_module.dart';
import 'package:habinson/games/registry.dart';

const niveles = {'suave', 'picante', 'atrevido'};

/// Campos de texto obligatorios según el estilo de carta del mazo.
List<String> camposDe(PromptCardStyle estilo) => switch (estilo) {
      PromptCardStyle.statement => ['texto'],
      PromptCardStyle.choice => ['a', 'b'],
      PromptCardStyle.question => ['texto'],
    };

/// Mazos de cartas registrados en la app (sale de `gameModules`, no de una lista fija).
List<PromptDeckModule> get mazos => gameModules.whereType<PromptDeckModule>().toList();

/// Todos los JSON de contenido (incluidas subcarpetas, p. ej. geografía).
List<File> ficherosDeContenido() => Directory('assets/content/es')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.json'))
    .toList();

/// Todas las cadenas de un JSON, recorriendo mapas y listas (claves incluidas no).
Iterable<String> cadenas(Object? v) sync* {
  if (v is String) {
    yield v;
  } else if (v is List) {
    for (final e in v) {
      yield* cadenas(e);
    }
  } else if (v is Map) {
    for (final e in v.values) {
      yield* cadenas(e);
    }
  }
}

/// Ids retirados: no se pueden reutilizar (la app puede tenerlos guardados).
const idsRetirados = {
  'yn033', 'yn049', 'yn055', 'yn056', 'yn057', 'yn058', 'yn059', 'yn063', 'yn073', 'yn074', //
  'yn075', 'yn076', 'yn078', 'yn079', 'yn080', 'yn082', 'yn084', 'yn086', 'yn087', 'yn088',
  'yn089', 'yn092', 'yn094', 'yn096', 'yn099', 'yn107', 'yn109', 'yn111', 'yn112', 'yn115',
  'yn117', 'yn120', 'yn124', 'yn125', 'yn126', 'yn127', 'yn130', 'yn131', 'yn133', 'yn136',
  'yn137', 'yn138', 'yn140', 'yn141', 'yn143', 'yn144', 'yn145', 'yn148', 'yn150', 'yn151',
  'yn152', 'yn154', 'yn155', 'yn157', 'yn158', 'yn160', 'yn165', 'yn166', 'yn168', 'yn169',
  'yn170', 'yn171', 'yn173', 'yn174', 'yn175', 'yn176', 'yn177', 'yn178', 'yn184', 'yn193',
  'yn194', 'yn195', 'yn196', 'yn197', 'yn198', 'yn199', 'yn200', 'yn205', 'yn206', 'yn207',
  'yn208', 'yn209', 'yn210', 'yn212', 'yn213', 'yn214', 'yn216', 'yn217', 'yn221', 'yn223',
  'yn228', 'yn229', 'yn230', 'yn231', 'yn235', 'yn236', 'yn237', 'yn238', 'yn240', 'yn241',
  'yn242', 'yn243', 'yn246', 'yn247', 'yn250', 'yn251', 'yn255', 'yn256', 'yn257', 'yn260',
  'yn263', 'yn264', 'yn265', 'yn267', 'yn270', 'yn271', 'yn274', 'yn279', 'yn281', 'yn282',
  'yn283', 'yn284', 'yn285', 'yn286', 'yn288', 'yn289', 'yn291', 'yn293', 'yn295', 'yn296',
  'yn297', 'yn298', 'yn300', 'yn301', 'yn310', 'yn312', 'yn314', 'yn315', 'yn316', 'yn321',
  'yn322', 'yn323', 'yn324', 'yn325', 'yn326', 'yn329',
  // Auditoría de edad (2026-11-27): contexto familiar o de "primera vez".
  'yn108', 'yn116', 'yn318',
};

/// Prohibido en todo el contenido (normas de Google Play y App Store):
/// alcohol como objetivo, drogas, insultos fuertes, odio.
/// Palabra exacta (tras pasar a minúsculas).
const prohibidasExactas = {
  // Alcohol y borracheras: las consecuencias se expresan en fichas.
  'borracho', 'borracha', 'borrachos', 'borrachas', 'borrachera', 'pedo', 'pedos',
  'resaca', 'resacas', 'chupito', 'chupitos', 'cubata', 'cubatas', 'trago', 'tragos',
  'alcohol', 'beber', 'bebe', 'bebes', 'bebed', 'bebeos', 'bébete', 'bébetelo', 'bebida',
  'bebidas', 'botellón', 'birra', 'birras',
  'pimplar', 'cogorza', 'mamado', 'sorbo', 'sorbos', 'brindis', 'brindar', 'litrona',
  'litronas',
  // Drogas.
  'droga', 'drogas', 'porro', 'porros', 'fumado', 'fumada', 'colocado', 'colocada',
  'cocaína', 'marihuana', 'éxtasis', 'viagra',
  // Insultos fuertes y odio.
  'puta', 'puto', 'putas', 'putos', 'gilipollas', 'subnormal', 'retrasado', 'maricón',
  'zorra', 'cabrón', 'hostia', 'hostias', 'mierda', 'joder',
};

/// Raíces prohibidas en todo el contenido (prefijo de palabra).
const prohibidasRaices = ['emborrach', 'borrach', 'alcoh', 'drog'];

/// Nombres de bebidas alcohólicas: fuera de todo el contenido (Trivia incluida).
const bebidasExactas = {'cerveza', 'cervezas', 'vodka', 'tequila', 'ron', 'whisky', 'ginebra', 'vino', 'vinos', 'sangría', 'kalimotxo', 'calimocho'};

/// Prohibido en los mazos de cartas (ni siquiera en Atrevido): explícito y menores.
const explicitasExactas = {
  'sexo', 'sexual', 'sexuales', 'follar', 'follamigo', 'follamiga', 'polvo', 'polvos',
  'porno', 'pornográfica', 'pene', 'penes', 'coño', 'tetas', 'teta', 'culo', 'culos', 'ano',
  'orgasmo', 'orgasmos', 'condón', 'condones', 'anal', 'oral', 'nudes', 'virgen',
  'virginidad', 'genitales', 'pezones', 'pezón', 'orgía', 'trío', 'bukkake', 'hentai',
  'cubana', 'mamada', 'corrido', 'corrida', 'semen', 'erección', 'gatillazo', 'lubricante',
  'vello', 'púbico', 'tirarme', 'masturbado', 'desnudo', 'desnuda',
  'desnudo/a', 'menor', 'menores', 'colegio', 'instituto', 'kamasutra', 'striptease',
};

/// Frases prohibidas en los mazos de cartas (el test de palabras no las ve).
const explicitasFrases = ['juguete erótico', 'juguetes eróticos'];

/// Frases que en Picante y Atrevido remiten a menores o a la familia.
const menoresFrases = ['primera vez'];

/// En Picante y Atrevido, "padres" no puede ir junto a algo íntimo.
const familiaPalabras = {'padres', 'padre', 'madre', 'hermano', 'hermana'};
const intimoPalabras = {'íntimo', 'íntima', 'cama', 'apasionado', 'apasionada'};

/// Devuelve la primera frase prohibida encontrada (o la combinación), o null.
String? buscaFrase(String texto, List<String> frases) {
  final t = texto.toLowerCase();
  for (final f in frases) {
    if (t.contains(f)) return f;
  }
  return null;
}

String? buscaFamiliaIntima(String texto) {
  final ws = palabras(texto).toSet();
  final f = ws.intersection(familiaPalabras);
  final i = ws.intersection(intimoPalabras);
  return f.isNotEmpty && i.isNotEmpty ? '${f.first} + ${i.first}' : null;
}
const explicitasRaices = ['masturb', 'porn', 'desnud', 'sexo', 'follar', 'follam', 'eyacul', 'vagin'];

/// En Picante y Atrevido (ligue, sugerente): nada que remita al colegio o a menores.
const escolarExactas = {
  'profesor', 'profesora', 'profesores', 'profesoras', 'profe', 'profes', 'curso', 'cursos',
  'clase', 'clases', 'colegio', 'cole', 'instituto', 'insti', 'alumno', 'alumna', 'alumnos',
  'recreo', 'examen', 'exámenes', 'tutor', 'tutora', 'bachillerato', 'niño', 'niña',
  'niños', 'niñas', 'menor', 'menores', 'campamento',
};
const escolarRaices = ['adolesc', 'quincea', 'colegi'];

/// En Suave (apto para cualquier grupo) tampoco: ligue, cuernos, cama, etc.
const noSuaveExactas = {
  'liar', 'liarme', 'liado', 'liada', 'ligar', 'ligado', 'cuernos', 'infiel', 'cama',
  'íntimo', 'intimidad', 'pasión', 'striptease', 'morbo', 'erótico', 'erótica', 'chupetón',
  'crush', 'ex', 'cita', 'citas', 'besar', 'besado', 'beso',
};

List<String> palabras(String texto) => texto
    .toLowerCase()
    .split(RegExp(r'[^\p{L}/]+', unicode: true))
    .where((w) => w.isNotEmpty)
    .toList();

/// Devuelve la primera palabra prohibida encontrada, o null.
String? buscaProhibida(String texto, Set<String> exactas, List<String> raices) {
  final ws = palabras(texto);
  for (final w in ws) {
    final limpia = w.replaceAll('/', '');
    final partes = w.split('/');
    for (final p in {w, limpia, ...partes}) {
      if (exactas.contains(p)) return p;
      for (final r in raices) {
        if (p.startsWith(r)) return p;
      }
    }
  }
  return null;
}

Map<String, dynamic> leer(String ruta) =>
    jsonDecode(File(ruta).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> items(String ruta) =>
    (leer(ruta)['items'] as List).cast<Map<String, dynamic>>();

void main() {
  test('la lista negra detecta lo que debe', () {
    expect(buscaProhibida('he escrito borracho/a a mi ex', prohibidasExactas, prohibidasRaices), isNotNull);
    expect(buscaProhibida('lo he hecho muy pedo', prohibidasExactas, prohibidasRaices), 'pedo');
    expect(buscaProhibida('intenté emborrachar a alguien', prohibidasExactas, prohibidasRaices), isNotNull);
    expect(buscaProhibida('me he masturbado', explicitasExactas, explicitasRaices), isNotNull);
    expect(buscaProhibida('he tenido un follamigo/a', explicitasExactas, explicitasRaices), isNotNull);
    expect(buscaProhibida('he cenado cereales', prohibidasExactas, prohibidasRaices), isNull);
    expect(buscaProhibida('he cuidado de un bebé', prohibidasExactas, prohibidasRaices), isNull);
    expect(buscaProhibida('me he enamorado de un profesor', escolarExactas, escolarRaices), 'profesor');
    expect(buscaProhibida('a principio de curso', escolarExactas, escolarRaices), 'curso');
    expect(buscaProhibida('una copa de vino', bebidasExactas, const []), 'vino');
    expect(buscaProhibida('he consultado el Kamasutra', explicitasExactas, explicitasRaices), 'kamasutra');
    expect(buscaFrase('he tenido un juguete erótico', explicitasFrases), isNotNull);
    expect(buscaFrase('mi primera vez', menoresFrases), isNotNull);
    expect(buscaFamiliaIntima('un momento íntimo en casa de mis padres'), isNotNull);
    expect(buscaFamiliaIntima('una primera cita cenando con sus padres'), isNull);
  });

  test('hay mazos de cartas registrados y los ids de juego son únicos', () {
    expect(mazos, isNotEmpty);
    final ids = gameModules.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'ids de juego duplicados');
    final rutas = mazos.map((m) => m.contentAsset).toList();
    expect(rutas.toSet().length, rutas.length, reason: 'dos juegos con el mismo fichero');
  });

  for (final mazo in mazos) {
    final ruta = mazo.contentAsset;
    final campos = camposDe(mazo.style);
    group('${mazo.id} ($ruta)', () {
      final lista = items(ruta);

      test('ids únicos, con formato, mismo prefijo y no retirados', () {
        final ids = lista.map((p) => p['id'] as String).toList();
        expect(ids, isNotEmpty);
        expect(ids.toSet().length, ids.length, reason: 'ids duplicados');
        final formato = RegExp(r'^([a-z]+_?)\d{3}$');
        final prefijos = <String>{};
        for (final id in ids) {
          final m = formato.firstMatch(id);
          expect(m, isNotNull, reason: 'id con formato raro: $id');
          prefijos.add(m!.group(1)!);
          expect(idsRetirados.contains(id), isFalse, reason: 'id retirado reutilizado: $id');
        }
        expect(prefijos.length, 1, reason: 'prefijos de id mezclados: $prefijos');
      });

      test('solo id, nivel y campos de texto (parsePrompts)', () {
        for (final p in lista) {
          for (final v in p.values) {
            expect(v, isA<String>(), reason: '${p['id']}: parsePrompts solo admite texto');
          }
        }
      });

      test('niveles válidos y todos presentes', () {
        for (final p in lista) {
          expect(niveles.contains(p['nivel']), isTrue, reason: '${p['id']}: nivel "${p['nivel']}"');
        }
        for (final n in niveles) {
          expect(lista.where((p) => p['nivel'] == n), isNotEmpty, reason: 'sin cartas de $n');
        }
      });

      test('campos obligatorios y textos sin repetir', () {
        final vistos = <String>{};
        for (final p in lista) {
          for (final c in campos) {
            final v = p[c];
            expect(v is String && v.trim().isNotEmpty, isTrue, reason: '${p['id']} sin "$c"');
          }
          final clave = campos.map((c) => (p[c] as String).toLowerCase().trim()).join('|');
          expect(vistos.add(clave), isTrue, reason: '${p['id']} repetida');
        }
      });

      test('lista negra: alcohol, drogas, insultos y explícito', () {
        for (final p in lista) {
          final texto = campos.map((c) => p[c] as String).join(' ');
          final mala = buscaProhibida(texto, prohibidasExactas, prohibidasRaices) ??
              buscaProhibida(texto, bebidasExactas, const []) ??
              buscaProhibida(texto, explicitasExactas, explicitasRaices);
          expect(mala, isNull, reason: '${p['id']}: "$mala" en "$texto"');
        }
      });

      test('Picante y Atrevido sin contexto escolar ni de menores', () {
        for (final p in lista.where((p) => p['nivel'] != 'suave')) {
          final texto = campos.map((c) => p[c] as String).join(' ');
          final mala = buscaProhibida(texto, escolarExactas, escolarRaices) ??
              buscaFrase(texto, menoresFrases) ??
              buscaFamiliaIntima(texto);
          expect(mala, isNull, reason: '${p['id']} (${p['nivel']}): "$mala" en "$texto"');
        }
      });

      test('lista negra de frases explícitas', () {
        for (final p in lista) {
          final texto = campos.map((c) => p[c] as String).join(' ');
          final mala = buscaFrase(texto, explicitasFrases);
          expect(mala, isNull, reason: '${p['id']}: "$mala" en "$texto"');
        }
      });

      test('Suave apto para cualquier grupo', () {
        for (final p in lista.where((p) => p['nivel'] == 'suave')) {
          final texto = campos.map((c) => p[c] as String).join(' ');
          final mala = buscaProhibida(texto, noSuaveExactas, const []);
          expect(mala, isNull, reason: '${p['id']} (suave): "$mala" en "$texto"');
        }
      });
    });
  }

  test('Yo nunca: Suave tiene sustancia (~100 cartas)', () {
    final suaves = items('assets/content/es/yo_nunca.json').where((p) => p['nivel'] == 'suave');
    expect(suaves.length, greaterThanOrEqualTo(90));
  });

  test('¿Qué preferirías? no habla de fichas: no significan nada en Retos ni en Sorbos', () {
    final cartas = items('assets/content/es/que_preferirias.json');
    for (final c in cartas) {
      expect('${c['a']} ${c['b']}'.toLowerCase(), isNot(contains('ficha')), reason: '${c['id']}');
    }
    final qp043 = cartas.firstWhere((c) => c['id'] == 'qp043');
    expect(qp043['a'], 'Besar a alguien de este grupo');
    expect(qp043['b'], 'Confesar a quién de aquí besarías');
    expect(qp043['nivel'], 'atrevido');
  });

  test('¿Qué preferirías?: 120 cartas o más (3.6)', () {
    expect(items('assets/content/es/que_preferirias.json').length, greaterThanOrEqualTo(120));
  });

  group('trivia', () {
    final lista = items('assets/content/es/trivia.json');

    test('ids únicos', () {
      final ids = lista.map((q) => q['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('las preguntas de Open Trivia DB llevan fuente y licencia', () {
      for (final q in lista) {
        final deOtdb = (q['id'] as String).startsWith('ot-');
        expect(q['fuente'] == 'opentdb', deOtdb, reason: '${q['id']}: fuente "${q['fuente']}"');
        if (deOtdb) expect(q['licencia'], 'CC BY-SA 4.0', reason: '${q['id']} sin licencia');
      }
      expect(lista.where((q) => q['fuente'] == 'opentdb'), isNotEmpty);
    });

  });

  // Alcohol, bebidas, drogas e insultos: misma lista en TODOS los JSON de
  // contenido (mazos, trivia, abecedario, geografía, infiltrado, retos...).
  group('lista negra en todo el contenido', () {
    final ficheros = ficherosDeContenido();

    test('se encuentran los ficheros', () {
      expect(ficheros.length, greaterThanOrEqualTo(7));
    });

    for (final f in ficheros) {
      test(f.path.replaceAll('\\', '/'), () {
        for (final t in cadenas(jsonDecode(f.readAsStringSync()))) {
          final mala = buscaProhibida(t, prohibidasExactas, prohibidasRaices) ??
              buscaProhibida(t, bebidasExactas, const []);
          expect(mala, isNull, reason: '"$mala" en "$t"');
        }
      });
    }
  });
}
