# Quick Start Guide for Agents Fixing -autofree Issues

Esta guía te ayuda a comenzar rápidamente con cualquier issue de `-autofree`.

## 🚀 Inicio Rápido (2 minutos)

### 1. Elige un Issue

Ve a **[AUTOFREE_ISSUES_INDEX.md](AUTOFREE_ISSUES_INDEX.md)** y elige un issue basado en:
- **Complejidad:** Low-Medium = más fácil, High = más complejo
- **Prioridad:** Issues #2 y #6 son "quick wins"

### 2. Lee el Documento del Issue

Cada documento contiene TODO lo que necesitas:
- `AUTOFREE_ISSUE_00X_[NOMBRE].md`

No necesitas leer otros archivos - cada documento es standalone.

### 3. Setup del Entorno

```bash
cd /home/runner/work/v/v

# Build V compiler si no existe
make

# Build debug version para desarrollo
./v -g -keepc -o ./vnew cmd/v
```

### 4. Reproduce el Error

El documento incluye código de reproducción mínima. Ejemplo:

```bash
# Copia el código de reproducción del documento
cat > /tmp/test.v << 'EOF'
[código de reproducción del documento]
EOF

# Compila con -autofree para ver el error
./vnew -autofree -cc clang /tmp/test.v -o /tmp/test
```

### 5. Implementa el Fix

Sigue la sección "Suggested Fix Approach" del documento.

### 6. Verifica el Fix

```bash
# Recompila el compiler
./v -g -keepc -o ./vnew cmd/v

# Prueba el ejemplo que fallaba
./vnew -autofree [ejemplo_que_fallaba].v -o /tmp/test

# Ejecuta los tests
./vnew -autofree [test_file_del_documento].v
```

## 📋 Checklist para Completar un Issue

- [ ] El ejemplo original compila sin errores
- [ ] El código C generado es válido (usa `-keepc` para verificar)
- [ ] Los unit tests del documento pasan
- [ ] No hay memory leaks (valgrind si es posible)
- [ ] No hay regresiones en tests existentes

## 🎯 Issues Recomendados para Empezar

### Más Fácil: Issue #2 (1-2 días)
**[AUTOFREE_ISSUE_002_ARRAY_DEREFERENCE.md](AUTOFREE_ISSUE_002_ARRAY_DEREFERENCE.md)**
- Problema: Falta `*` en desreferencia de puntero
- Fix probable: Agregar un `*` en el lugar correcto
- Archivos: `vlib/v/gen/c/assign.v`

### Más Fácil: Issue #6 (1-2 días)
**[AUTOFREE_ISSUE_006_ENUM_DECLARATION.md](AUTOFREE_ISSUE_006_ENUM_DECLARATION.md)**
- Problema: Usa valor de enum como tipo
- Fix probable: Usar `expr.typ` en lugar de `expr.name`
- Archivos: `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/if.v`

### Mediano: Issue #4 (2-4 días)
**[AUTOFREE_ISSUE_004_FUNCTION_CALL_SYNTAX.md](AUTOFREE_ISSUE_004_FUNCTION_CALL_SYNTAX.md)**
- Problema: Cleanup rompe sintaxis de llamadas
- Fix: Reordenar generación de código
- Archivos: `vlib/v/gen/c/fn.v`

### Mediano: Issue #1 (2-4 días)
**[AUTOFREE_ISSUE_001_MATCH_EXPRESSION.md](AUTOFREE_ISSUE_001_MATCH_EXPRESSION.md)**
- Problema: `_t = if (...)` inválido en C
- Fix: Ajustar punto de inserción de cleanup
- Archivos: `vlib/v/gen/c/autofree.v`, `vlib/v/gen/c/cgen.v`

### Mediano: Issue #5 (2-4 días)
**[AUTOFREE_ISSUE_005_RESULT_OPTION_HANDLING.md](AUTOFREE_ISSUE_005_RESULT_OPTION_HANDLING.md)**
- Problema: Temporales de Result/Option mal rastreados
- Fix: Mejorar tracking de temporales
- Archivos: `vlib/v/gen/c/autofree.v`

### Complejo: Issue #3 (5-7 días)
**[AUTOFREE_ISSUE_003_UNDECLARED_IDENTIFIER.md](AUTOFREE_ISSUE_003_UNDECLARED_IDENTIFIER.md)**
- Problema: Cleanup intenta liberar variables inexistentes
- Fix: Rediseñar scope tracking
- Archivos: `vlib/v/gen/c/autofree.v` (refactor grande)

## 🔧 Comandos Útiles

### Compilación con Debug
```bash
# Compilar con info de debug
./vnew -g -keepc -cc clang file.v -o /tmp/test

# Ver código C generado
cat /tmp/v_*/test.tmp.c | less

# Buscar patterns específicos en C generado
cat /tmp/v_*/test.tmp.c | grep "pattern" -A 5 -B 5
```

### Testing
```bash
# Compilar y correr test
./vnew -autofree test_file.v

# Ver output de autofree
./vnew -autofree -d trace_autofree file.v

# Ver variables no liberadas
./vnew -autofree -print_autofree_vars file.v
```

### Valgrind (si está disponible)
```bash
./vnew -autofree -g file.v -o /tmp/test
valgrind --leak-check=full /tmp/test
```

## 📚 Estructura de Cada Documento de Issue

1. **Problem Description** - Qué está roto
2. **Symptoms** - Cómo se ve el error
3. **Affected Files** - Qué ejemplos fallan, qué código arreglar
4. **Root Cause** - Por qué pasa
5. **Reproduction Steps** - Código mínimo para reproducir
6. **Suggested Fix Approach** - Paso a paso con código de ejemplo
7. **Testing Strategy** - Qué tests crear y correr
8. **Success Criteria** - Checklist de completitud

## 💡 Tips

### Para Encontrar el Código Correcto
```bash
# Buscar donde se generan los temporales
cd vlib/v/gen/c
grep -r "_sref" .
grep -r "/* if prepend */" .
grep -r "autofree arg" .
```

### Para Entender el Flow
1. Lee el "Root Cause" primero
2. Reproduce el error
3. Examina el código C generado con `-keepc`
4. Compara con ejemplo que funciona
5. Sigue el "Suggested Fix Approach"

### Para Verificar tu Fix
1. Recompila el compiler
2. Prueba el ejemplo original
3. Corre los unit tests del documento
4. Verifica con valgrind si es posible
5. Corre tests existentes de autofree

## 🤝 Si Te Atascas

1. **Revisa "Additional Context"** en el documento
2. **Examina el código C generado** con `-keepc`
3. **Compara con ejemplos que funcionan**
4. **Usa los flags de debug**: `-d trace_autofree`, `-print_autofree_vars`
5. **Lee el código relacionado** en los archivos sugeridos

## ✅ Cuando Termines

Verifica que:
- [ ] Todos los ejemplos afectados compilan
- [ ] Código C generado es válido
- [ ] Unit tests pasan
- [ ] No hay memory leaks
- [ ] Tests existentes no tienen regresiones

Luego actualiza el issue document con:
- Estado: "Fixed"
- Commit hash
- Notas sobre el fix si son relevantes

## 📖 Referencias Rápidas

- **Index:** [AUTOFREE_ISSUES_INDEX.md](AUTOFREE_ISSUES_INDEX.md)
- **Overview:** [AUTOFREE_INVESTIGATION_SUMMARY.md](AUTOFREE_INVESTIGATION_SUMMARY.md)
- **User Guide:** [AUTOFREE_QUICK_REFERENCE.md](AUTOFREE_QUICK_REFERENCE.md)
- **All Issues:** [AUTOFREE_ISSUES.md](AUTOFREE_ISSUES.md)

¡Buena suerte! 🚀
