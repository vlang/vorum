# vtalk

Open-source blogging/forum software written in V. 

(The name is not final, name suggestions are welcome.)

**This is pre-alpha software.**

Lots of things are broken and not implemented yet in V, vweb, and vtalk.

### Building

```bash
git clone https://github.com/vlang/vtalk
cd vtalk
v .
./vtalk

Running vtalk on http://localhost:8092...
```

### Deploying

Everything, including HTML templates, is in one binary file `vtalk`. That's all you need to deploy.

### Known problems:

- vweb HTML templates are precompiled and are part of the application's binary, so every time a template is changed, the entire app has to be rebuilt. This will be resolved in the future.

- no epoll/kqueue yet. So the performance is pretty bad until this is implemented: about 1k req/sec.

- Right now only Postgres is supported. SQLite and MySQL backends will be supported in August.

