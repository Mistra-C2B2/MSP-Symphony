1. Open in VS Code
2. Install plugins for development in DevContainers.
3. Open repository in DevContainer.

4. Get the testdata

```
git submodule init
git submodule update
```

3. Deploy the backend

sh deploy.sh

4. Serve the frontend

cd frontend
ng serve --host 0.0.0.0 --ssl false
