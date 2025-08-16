Perfecto. Si ya subiste **`mariadb-data/`** al repo, en un PC nuevo solo necesitas esto:

## Puesta en marcha en otro PC

1. Instala **Docker Desktop**.
2. Clona el repo y ve a `RespawnServer/`.
3. Arranca la DB:

```bat
docker compose up -d
docker compose ps
```

4. Prueba acceso:

```bat
docker exec -it respawn_mariadb mysql -u alkalo -p123456 -e "SHOW DATABASES;"
```

5. En tu `server.cfg` asegúrate de tener (antes de `ensure oxmysql`):

```cfg
setr mysql_connection_string "mysql://alkalo:123456@127.0.0.1/QBCore_A0764D?charset=utf8mb4"
ensure oxmysql
ensure qb-core
```

> Si mapeaste otro puerto (p. ej. 3307), usa `127.0.0.1:3307` en la cadena.

## Consejos rápidos

* **Repo pesado**: al versionar `mariadb-data/` el repo crecerá. Si se hace grande:

  * Usa **Git LFS** para ficheros voluminosos (`ib*`, `aria_log.*`, etc.), o
  * Cambia a estrategia “dump `.sql` + init” (más ligera) cuando quieras.
* **Resets limpios**: si necesitas recrear desde cero:

  ```bat
  docker compose down
  rmdir /s /q mariadb-data
  docker compose up -d
  ```

  (Se re-ejecutará `mariadb-init/01-init.sql` si lo tienes).
* **Seguridad**: cuando pases a producción, mueve credenciales a `.env`:

  ```
  DB_USER=alkalo
  DB_PASS=123456
  DB_NAME=QBCore_A0764D
  ```

  y en `server.cfg`:

  ```cfg
  setr mysql_connection_string "mysql://${DB_USER}:${DB_PASS}@127.0.0.1/${DB_NAME}?charset=utf8mb4"
  ```

Si quieres, te preparo un **script `verify-db.bat`** que compruebe contenedor, puerto y conexión con un solo doble-clic.



docker exec -it respawn_mariadb mysql -u alkalo -p123456 QBCore_A0764D


https://portal.cfx.re/servers/registration-keys?row=ymze6k