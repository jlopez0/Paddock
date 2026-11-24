# Reglas comunes de Javier (todos los proyectos)

Este archivo se instala en `~/.claude/CLAUDE.md` y se aplica en todos los repos. El `CLAUDE.md` de cada proyecto manda sobre este si chocan.

## Cómo trabajar
- Responde en español, conciso y directo. Sin relleno.
- Ship over plan: ante la duda, el siguiente paso más pequeño que deje algo funcionando.
- Antes de tocar código, lee el `CLAUDE.md` / `AGENTS.md` del repo y respeta sus restricciones duras.
- Antes de cambios grandes, resume en ≤5 líneas qué vas a hacer y espera OK.
- Commits pequeños y con sentido. Build y tests en verde antes de dar algo por terminado.
- Registra decisiones no obvias en `docs/decisions.md` (fecha, decisión, motivo).

## Seguridad y datos
- Nunca secretos, claves, cadenas de conexión, saldos ni datos personales en git. Van a variables de entorno o a la base de datos.
- Correos: solo borradores, nunca enviar.
- Todo aviso accionable para Javier se crea como tarea en Todoist (es donde mira).

## Enrutado de modelos (equipo habin-agents-gang)
Delega en subagentes según la tarea; el contexto principal es para coordinar.

| Tipo de trabajo | Agente | Modelo · esfuerzo |
|---|---|---|
| Ejecutar un plan entero coordinando al equipo (sesión principal: `claude --agent jefe`) | `jefe` | Opus · medio |
| Decidir arquitectura, partir en fases, algo ambiguo | `arquitecto` | Opus · alto |
| Ejecutar una fase ya especificada | `implementador` | Sonnet · medio |
| Revisar un diff antes de cerrar | `revisor` | Sonnet · alto |
| Renombrar, boilerplate, mover textos, cambios masivos simples | `mecanico` | Haiku · bajo |
| Textos en español: microcopy, fichas de tienda, contenido | `redactor-es` | Opus · medio |
| Publicar app Flutter en Google Play / App Store | `release-movil` | Sonnet · medio |
| Explorar el código sin cambiar nada | `Explore` (integrado) | — |

Reglas de escalado:
- Si `implementador` falla los tests dos veces en lo mismo, para y escala a `arquitecto`.
- Cambios de riesgo (auth, pagos, datos, migraciones, borrados) → `revisor` siempre antes de cerrar.
- Los agentes del proyecto (`.claude/agents/` del repo) tienen prioridad sobre los genéricos para su dominio.
- No anidar más de un nivel: la sesión principal (o el `jefe`) reparte; los subagentes no lanzan otros.
