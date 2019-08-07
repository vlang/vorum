# vorum

Open-source blogging/forum software written in [V](https://github.com/vlang/v). 

(The name is not final, name suggestions are welcome.)

**This is pre-alpha software.**

Lots of things are broken and not implemented yet in V, vweb, and vorum.

### Setting up the database

Install Postgres and libpq, create a database `vorum` (you can use any name), and run the initalization script:

```
psql -f init_postgres_db.sql -d vorum
```

Edit Postgres connection settings (Postgres user and db name) in `main.v`.

### Building

V 0.1.17 is required.

```bash
git clone https://github.com/vlang/vorum
cd vorum
v .
./vorum

Running vorum on http://localhost:8092...
```

### Deploying

Everything, including HTML templates, is in one binary ~100 KB file `vorum`. That's all you need to deploy.

### Known problems:

- vweb HTML templates are precompiled and are part of the application's binary, so every time a template is changed, the entire app has to be rebuilt. This will be resolved in the future.

- no epoll/kqueue yet. So the performance is pretty bad until this is implemented: about 1k req/sec.

- Right now only Postgres is supported. SQLite and MySQL backends will be supported in August.

