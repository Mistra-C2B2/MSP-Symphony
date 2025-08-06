# How to develop

1. Open in VS Code
2. Install plugins for development in DevContainers.
3. Open repository in DevContainer.
4. Get the testdata

```
git submodule init
git submodule update
```

5. Generate new certificates

In frontend/ssl

openssl req \
 -x509 -nodes -days 365 \
 -newkey rsa:2048 \
 -keyout server.key \
 -out server.crt \
 -config openssl-custom.cnf

6. Start wildfly

sh start-wildfly.sh

3. Deploy the backend

sh deploy-backend.sh

4. Serve the frontend

cd frontend
PROXY_TARGET=local ng serve --host 0.0.0.0
