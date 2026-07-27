# Launch Godot editor
dev:
    nohup godot project.godot &> /dev/null & disown

# Export
export:
    godot --export-release Web ./exports/web/index.html

# Run pipeline locally with woodpecker-cli
ci-local:
    #!/usr/bin/env fish
    set -l TMP (mktemp -d)

    # Decrypt secrets
    sops -d secrets/woodpecker.yaml > $TMP/secrets.yaml

    # Ensure podman socket is available (rootless)
    #  if not test -S /run/user/(id -u)/podman/podman.sock
    #      echo "Starting podman socket..."
    #      systemctl --user start podman.socket
    #      sleep 1
    #  end

    set -gx DOCKER_HOST unix:///run/user/(id -u)/podman/podman.sock

    # Run pipeline locally
    woodpecker-cli exec \
        --backend-engine docker \
        --secrets-file $TMP/secrets.yaml \
        .woodpecker.yml

    rm -rf $TMP
