# Cafetería · Registro de pedidos

## 1. Supabase
1. Crea un proyecto en supabase.com.
2. **SQL Editor** → pega y ejecuta todo `supabase.sql`.
3. **Authentication → Providers → Email**: desactiva *Confirm email*.
4. **Authentication → Users → Add user**: crea los usuarios con correo `usuario@cafeteria.app` y su clave. En la app se ingresa solo con `usuario`.
5. Convierte al primero en administrador (SQL Editor):
   `update profiles set role='admin' where username='admin';`
   Los demás quedan como `mesero` por defecto.
6. **Settings → API**: copia *Project URL* y la clave *anon public*.

## 2. Configurar
En `index.html`, al inicio del `<script>`, reemplaza `SUPABASE_URL` y `SUPABASE_KEY`.
La clave *anon* es pública por diseño; la seguridad la dan las políticas RLS del SQL.

## 3. Desplegar en GitHub
1. Crea un repositorio y sube `index.html` (y los demás archivos).
2. **Settings → Pages → Deploy from a branch → main / root**.
3. Tu app queda en `https://TU-USUARIO.github.io/TU-REPO/`.

## Nuevos niveles
- Crea un rol nuevo: `update profiles set role='cocina' where username='ana';`
- En `index.html`, agrega una línea en `PERMS`, por ejemplo `cocina:['pedidos','resumen']`.
