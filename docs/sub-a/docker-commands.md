# Docker Commands

Essential container management.

## Images

```bash
docker build -t myapp .
docker images
```

### Removing Images

```bash
docker rmi myapp
```

## Containers

```bash
docker run -d -p 8080:80 myapp
docker ps
docker stop container_id
```
