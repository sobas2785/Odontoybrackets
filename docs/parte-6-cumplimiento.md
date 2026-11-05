# Parte 6: implementación, pruebas y evidencias

[Entrega completa en PDF](Odontoybrackets_Parte6_Completo.pdf)

Fecha de la entrega: 5 de noviembre de 2026.

Función principal: registrar un turno y consultar el resultado.

El PDF conserva el diseño original y agrega siete historias de usuario, revisión del alcance y modelo de datos, recorrido paso a paso, correspondencia con las siete consignas, resultados reales de integración y seis capturas explicadas.

## Pruebas ejecutadas

Se probaron las cuatro cuentas ficticias de `supabase/seed.sql` contra el Supabase configurado en la aplicación. Se verificaron inicio de sesión, lectura limitada a la organización, creación y consulta de una reserva temporal, asociación automática a consultorio y creador, e inaccesibilidad del turno por ID desde otra organización.

Se comprobaron rechazos de contraseña incorrecta, superposición, fecha vacía, paciente de otro consultorio, día sin atención y horario fuera de atención. Se eliminó únicamente el turno creado por la prueba. No se ejecutaron `schema.sql` ni `seed.sql` durante estos ensayos.

Resultados sin claves ni tokens:

- [Autenticación y lectura](evidencias-parte-6/resultados-conexion.json)
- [Persistencia y validaciones](evidencias-parte-6/resultados-turnos.json)

## Evidencia visual aportada por el autor

- [E1: formulario completo](evidencias-parte-6/e1.png)
- [E2: Lucas Romero guardado en la agenda de Pablo, 06/11 a las 09:30](evidencias-parte-6/e2.png)
- [E3: agenda de Laura para la misma fecha, sin el turno de Pablo](evidencias-parte-6/e3.png)
- [E4: validación del nombre obligatorio del paciente](evidencias-parte-6/e4.png)
- [E5: detalle de otra reserva, Lucas López](evidencias-parte-6/e5.png)
- [E6: identidad y configuración de Sonrisas](evidencias-parte-6/e6.png)

E1 y E2 corresponden a una misma reserva. E5 es un ejemplo independiente. Las capturas fueron aportadas por el autor; no se presentan como un recorrido automatizado del navegador.

## Límites y mejoras

La agenda implementada y mostrada es diaria con cambio de fecha; no se acredita una vista semanal. La selección de profesional amplía el MVP original. El enlace a WhatsApp es manual.

El éxito se observa al volver a la agenda con el turno guardado; agregar un aviso textual de confirmación es una mejora recomendada. No se acredita una recarga manual del detalle ni la visualización de todos los errores de red/servidor. La superposición se probó por inserción duplicada, no mediante dos navegadores simultáneos.
