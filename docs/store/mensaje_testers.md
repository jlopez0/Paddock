# Mensaje para testers y cuestionario de acceso a producción · Paddock v1.0

Borradores. No se envía nada desde aquí. Los huecos van entre corchetes: `[ASÍ]`.

Requisito (cuenta personal): al menos 12 testers con opt-in durante 14 días seguidos. Conviene reclutar 15 o más por si alguien se cae.

---

## 1. Mensaje para reclutar testers (WhatsApp, Telegram o correo)

```
¡Hola! Estoy a punto de sacar Paddock, una app de juegos para jugar en grupo con un solo móvil (trivia, El Infiltrado, carreras, retos…). Antes de publicarla, Google me pide que la prueben al menos 12 personas durante 14 días. ¿Me echas una mano?

Qué necesito:
1. Tu correo de Gmail (el que usas en Google Play). Solo lo uso para darte acceso a la prueba.
2. Cuando te avise, entra en este enlace y pulsa "Hacerse tester": [ENLACE_OPT_IN]
3. Instala Paddock desde Google Play con ese mismo correo.
4. No la desinstales durante 14 días. No hace falta jugar a diario, pero abrirla de vez en cuando ayuda.

Si algo falla, no se entiende o te sobra, cuéntamelo por aquí o desde la ficha de la app en Google Play (hay un apartado para enviar comentarios privados). Vale todo: capturas, audios o "esto no me gusta".

Ojo: la app es para mayores de 18. Solo Android de momento.

¡Gracias! Te debo una partida.
```

### Recordatorio a mitad de prueba (día 7)

```
¡Hola! Vamos por la mitad de la prueba de Paddock. Gracias por aguantar. Recuerda no desinstalarla hasta el [FECHA_FIN]. Si has jugado con más gente, ¿qué tal? ¿Algún juego que no se entendiera o que sobrara?
```

### Cierre (día 14 o después)

```
¡Prueba terminada! Ya puedes desinstalarla si quieres, aunque me encantaría que te la quedaras. Gracias por la ayuda: [CAMBIO_QUE_SALIÓ_DE_VUESTROS_COMENTARIOS] fue idea vuestra.
```

---

## 2. Cuestionario "Solicitar acceso a producción" (Play Console)

Las preguntas exactas pueden cambiar: compáralas con el formulario real antes de pegar. Responde con datos reales; Google contrasta con las métricas de la prueba.

### Sobre la prueba cerrada

**¿Qué tan fácil fue reclutar testers?**
```
Fácil. Recluté a [Nº_TESTERS] personas entre amigos, familia y compañeros de [GRUPO], mayores de 18 y con Android. Les pedí el correo de Google Play, los añadí a la lista de testers y les envié el enlace de opt-in. [Nº_OPT_IN] aceptaron y mantuvieron la app instalada los 14 días.
```

**¿Cómo describirías la participación de los testers?**
```
[ALTA/MEDIA]. La mayoría la usó en quedadas de [2-6] personas, que es el uso real de la app: un solo móvil para todo el grupo. Les envié un recordatorio a mitad de prueba. Recibí comentarios de [Nº_PERSONAS] testers por mensaje directo y [Nº] por el canal de comentarios privados de Google Play.
```

**Resumen de los comentarios recibidos y cómo los recopilaste**
```
Recogí los comentarios por mensaje directo, por el canal privado de Google Play y probando la app en persona con algunos grupos. Lo principal:
- [COMENTARIO_1, p. ej. "las reglas de El Infiltrado no quedaban claras la primera vez"].
- [COMENTARIO_2, p. ej. "el texto de algunas cartas se cortaba en móviles pequeños"].
- [COMENTARIO_3].
También revisé los informes de prelanzamiento y Android vitals: [SIN_FALLOS / FALLOS_CORREGIDOS].
```

### Sobre la app

**¿A quién va dirigida?**
```
A adultos (18+) que quedan en grupo y quieren jugar con un solo móvil, sin cuentas ni conexión. El público objetivo declarado es solo mayores de 18.
```

**¿Qué valor aporta a los usuarios?**
```
Reúne ocho juegos de grupo (trivia, geografía, El Infiltrado, carrera de caballos con fichas sin valor y tres juegos de cartas) con un marcador común para toda la noche. Funciona sin internet, no tiene anuncios ni compras y no recoge datos. El contenido tiene niveles y el más atrevido está desactivado de serie.
```

**Instalaciones previstas el primer año**
```
[RANGO, p. ej. "0 – 10.000"]
```

### Preparación para producción

**¿Qué cambios hiciste a raíz de la prueba?**
```
- [CAMBIO_1, ligado a COMENTARIO_1].
- [CAMBIO_2].
- [CAMBIO_3].
Subí la versión [VERSIÓN, p. ej. 1.0.0+2] a la prueba cerrada con estos cambios y los testers la confirmaron.
```

**¿Cómo decidiste que la app está lista?**
```
Los testers completaron los 14 días sin fallos graves pendientes, los comentarios principales están resueltos, el informe de prelanzamiento no muestra errores bloqueantes y la ficha, la clasificación de contenido y la sección de seguridad de los datos coinciden con lo que hace la app.
```

---

## Antes de enviar

- [ ] Sustituir todos los `[HUECOS]` con datos reales. No inventar cifras.
- [ ] Guardar la lista de correos solo en Play Console, nunca en git.
- [ ] Comprobar que el enlace de opt-in funciona con una cuenta que no sea la del desarrollador.
