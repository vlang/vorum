# vorum

Open-source blogging/forum software written in [V](https://github.com/vlang/v). 

(The name is not final, name suggestions are welcome.)

**This is pre-alpha software.**

Lots of things are broken and not implemented yet in V, vweb, and vorum.

### Setting up the database

Install Postgres and libpq, create a database `vorum` (you can use any name), and run the initialization script:

```
psql -f init_postgres_db.sql -d vorum
```

Edit Postgres connection settings (Postgres user and db name) in `main.v`.

### Building

V 0.1.23 is required.

```bash
git clone https://github.com/vlang/vorum
cd vorum
v .
./vorum

Running vorum on http://localhost:8092...
```

### Deploying

Everything, including HTML templates, is in one binary ~100 KB file `vorum`. That's all you need to deploy.

### Setting up GitHub authentication

Right now only GitHub authentication is supported. (Traditional registration via email will be implemented soon.)

Create a GitHub oauth app (GitHub Settings => OAuth Apps).

Set Authorization callback URL to https://your-forum-url.com/oauth_cb.

Copy Client ID and Client Secret, and update the values in `oauth.v` or set VORUM_OAUTH_CLIENT_ID and VORUM_OAUTH_SECRET env vars.




### Known problems:

- vweb HTML templates are precompiled and are part of the application's binary, so every time a template is changed, the entire app has to be rebuilt. This will be resolved in the future.

- no epoll/kqueue yet. So the performance is pretty bad until this is implemented: about 1k req/sec.

- Right now only Postgres is supported. SQLite, MySQL, and MS SQL backends will be supported in the future.

