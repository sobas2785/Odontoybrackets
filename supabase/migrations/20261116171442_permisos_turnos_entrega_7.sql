-- Admin y recepción gestionan la agenda del consultorio.
-- Los profesionales conservan la lectura de toda la agenda y gestionan sus propios turnos.
begin;

alter policy "Miembros cargan turnos" on public.turnos
  with check (
    consultorio_id = (select public.mi_consultorio_id())
      and (
        (select public.mi_rol()) in ('admin', 'recepcion')
        or ((select public.mi_rol()) = 'profesional' and profesional_id = (select auth.uid()))
      )
  );

alter policy "Miembros modifican turnos" on public.turnos
  using (
    consultorio_id = (select public.mi_consultorio_id())
      and (
        (select public.mi_rol()) in ('admin', 'recepcion')
        or ((select public.mi_rol()) = 'profesional' and profesional_id = (select auth.uid()))
      )
  )
  with check (
    consultorio_id = (select public.mi_consultorio_id())
      and (
        (select public.mi_rol()) in ('admin', 'recepcion')
        or ((select public.mi_rol()) = 'profesional' and profesional_id = (select auth.uid()))
      )
  );

commit;
