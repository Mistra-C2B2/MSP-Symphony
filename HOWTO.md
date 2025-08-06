1. Open in VS Code
2. Install plugins for development in DevContainers.
3. Open repository in DevContainer.

4. Get the testdata

```
git submodule init
git submodule update
```

3. Generate new certificates

In frontend/ssl

openssl req \
 -x509 -nodes -days 365 \
 -newkey rsa:2048 \
 -keyout server.key \
 -out server.crt \
 -config openssl-custom.cnf

3. Deploy the backend

sh deploy.sh

4. Serve the frontend

cd frontend
PROXY_TARGET=local ng serve --host 0.0.0.0

curl -i \
 -X POST https://localhost:8080/symphony-ws/service/login \
 -H "Content-Type: application/json" \
 -d '{"username":"user","password":"user"}'

curl -i -k -X POST https://127.0.0.1:4200/symphony-ws/service/login -H "Content-Type: application/json" -d '{"username":"admin","password":"password123!"}'
