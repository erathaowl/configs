# Pi Sandbox 🐳

A lightweight Docker container for running the Pi coding agent. It gives you an isolated, reproducible environment to experiment with AI-assisted development — no local setup headaches required.

## Quick Start

### 1. Build the image

```bash
docker build -t pi-sandbox .
```

This pulls in all dependencies and prepares your sandbox. Grab a coffee ☕ — it might take a minute depending on your connection.

### 2. Run the container

```bash
docker run --rm -it -v "${PWD}:/workspace" -v pi-agent-home:/root/.pi/agent pi-sandbox
```

This starts an interactive session, mounts your current directory as `/workspace`, and persists your Pi agent config in a named volume called `pi-agent-home`. When you're done, just type `exit` — the `--rm` flag cleans up the container automatically.

## PowerShell Alias (Windows)

If you're on Windows and want a quick way to launch the sandbox without typing the full command every time, add this alias to your PowerShell profile:

```powershell
# Open or create your PowerShell profile
notepad $PROFILE

# Add this line:
function pi-sandbox {
    docker run --rm -it `
        -v "${PWD}:/workspace" `
        -v "pi-agent-home:/root/.pi/agent" `
        pi-sandbox @args
}
```

Save the file and restart PowerShell (or run `. $PROFILE` to reload it). Now you can simply type:

```powershell
pi-sandbox
```

And boom — you're in. 🚀
