# Local openEQUELLA

Single-node openEQUELLA 2026.1.1 with PostgreSQL 15, Java 21, ImageMagick,
FFmpeg, and Ghostscript. The image builds from the official release commit
`eef854b1048eeb1b2686aeca1dd202751d5b9dfc`, because the GitHub release has no
installer assets. Node matches the release's `.nvmrc`; SBT uses its upstream
wrapper. The bundled Scala GraphQL client is published to the build's local
Ivy cache first, as required by upstream's contributor guide. The first build
downloads and compiles the application and may take
a considerable amount of time and disk space. Allow at least 6 GB of available
RAM for the build; the running application's Java heap is capped at 1 GB.

## Start

Docker Engine with the Compose and BuildKit plugins is required.

Create a local database credential (do not commit it):

```sh
umask 077
printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 32)" > .env
docker compose up -d --build --wait --wait-timeout 600
```

Open <http://localhost:8082/admin/>. Only the HTTP port is published, on loopback;
PostgreSQL and the legacy manager port are not exposed. If Docker runs on a
remote development machine, forward port 8082 to your local browser.

The image uses the [upstream Docker installer defaults](https://github.com/openequella/openEQUELLA/blob/2026.1.1/docker/defaults.xml).
The bootstrap server administrator password is `admin`. Follow the admin
pages to initialize the database if prompted, then change the server
administrator password immediately. Create or import an institution through
Institution Management, using `http://localhost:8082/your-institution/` as its
URL. Set its own administrator password; the institution superuser is
`TLE_ADMINISTRATOR`. The admin page is not itself a content repository.

See the [official installation guide](https://openequella.github.io/gettingstarted/InstallingEquella.html)
for the institution import workflow. The guide's Java 8 prerequisite is old;
this release's Docker configuration uses Java 21.

## Operate

```sh
docker compose ps
docker compose logs -f openequella
docker compose stop
docker compose up -d --wait --wait-timeout 600
docker compose down
```

Database, filestore, search indexes, and logs use named Docker volumes and
survive container recreation and `docker compose down`. **Do not use
`docker compose down -v` unless you intend to permanently delete all data.**
Keep `.env`: changing its password does not change an existing database role.
Back up PostgreSQL and the filestore together while writes are stopped.

The health check verifies that the admin HTTP endpoint responds, not that an
institution has been configured or that all user workflows work.

This setup is for local evaluation, not production. Before any network
exposure, configure HTTPS, a real hostname, strong credentials, backups, and
appropriate resource limits. Changing the published port also requires
changing `EQ_ADMIN_URL` and any institution URLs.
