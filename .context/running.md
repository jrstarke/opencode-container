# Running the Sandbox

## Basic Usage

```bash
# Run from project directory
./run.sh

# Or specify workspace explicitly
WORKSPACE_DIR=/path/to/project ./run.sh
```

## Skip Firewall

For faster iteration during development:

```bash
SKIP_FIREWALL=true ./run.sh
```

This bypasses the firewall setup script.

## Debug Firewall

Edit `/workspace/init-firewall.sh` and add debug output, then rebuild:

```bash
docker build -t opencode-sandbox /workspace
docker run --rm --cap-add=NET_ADMIN --cap-add=NET_RAW \
  -v /path/to/project:/workspace \
  opencode-sandbox /usr/local/bin/init-firewall.sh
```

## Rebuild Image

The image is rebuilt each time you run `./run.sh`. To force a rebuild without cache:

```bash
docker build -t opencode-sandbox --no-cache /workspace
```

## Container Shell

To get a shell inside the container:

```bash
docker run --rm -it -v /path/to/project:/workspace \
  -e SKIP_FIREWALL=true \
  opencode-sandbox /bin/bash
```

## Check Network Access

Inside the container, test connectivity:

```bash
curl https://api.github.com/zen
curl https://registry.npmjs.org
```