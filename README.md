# Resolve Latest Docker Digests Action

[![test](https://github.com/optivem/resolve-latest-docker-digests-action/actions/workflows/test.yml/badge.svg)](https://github.com/optivem/resolve-latest-docker-digests-action/actions/workflows/test.yml)

A GitHub Action that resolves Docker image digests from any container registry for multiple images in batch.

## Description

This action processes multiple Docker images from any container registry (Docker Hub, GitHub Container Registry, Azure Container Registry, AWS ECR, etc.) and resolves their exact digests. Perfect for microservices architectures where you need to get digests for multiple services from various registries.

## Inputs

| Input | Description | Required | Example |
|-------|-------------|----------|---------|
| `image-urls` | JSON array of image URLs to resolve digests for | Yes | `["nginx:latest", "ghcr.io/owner/repo/image:latest"]` |

### Supported Registries

Works with any Docker-compatible registry:
- **Docker Hub**: `nginx:latest`, `ubuntu:22.04`
- **GitHub Container Registry**: `ghcr.io/owner/repo/image:latest`
- **Microsoft Container Registry**: `mcr.microsoft.com/dotnet/aspnet:8.0`
- **Azure Container Registry**: `myregistry.azurecr.io/myapp:latest`
- **AWS Elastic Container Registry**: `123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest`
- **Google Container Registry**: `gcr.io/project-id/image:latest`
- **Private registries**: `my-registry.com/my-org/my-app:v1.2.3`

## Outputs

| Output | Description |
|--------|-------------|
| `image-digests` | JSON object mapping image URLs to their resolved digests |

### Output Structure

```json
{
  "nginx:latest": "sha256:abc123...",
  "ghcr.io/owner/repo/app:latest": "sha256:def456..."
}
```

## Usage Examples

### Basic Example - Mixed Registries

```yaml
name: Resolve Image Digests
on: [push]

jobs:
  resolve-digests:
    runs-on: ubuntu-latest
    steps:
      - name: Resolve Docker Image Digests
        id: resolve
        uses: optivem/resolve-latest-docker-digests-action@v1
        with:
          image-urls: |
            [
              "nginx:latest",
              "ghcr.io/myorg/frontend:latest",
              "mcr.microsoft.com/dotnet/aspnet:8.0"
            ]
      
      - name: Use Resolved Digests
        run: |
          echo "Nginx digest: ${{ fromJson(steps.resolve.outputs.image-digests)['nginx:latest'] }}"
          echo "Frontend digest: ${{ fromJson(steps.resolve.outputs.image-digests)['ghcr.io/myorg/frontend:latest'] }}"
```

### Docker Hub Images

```yaml
- name: Resolve Docker Hub Images
  uses: optivem/resolve-latest-docker-digests-action@v1
  with:
    images: |
      [
        "nginx:latest",
        "redis:alpine",
        "postgres:15"
      ]
```

### GitHub Container Registry

```yaml
- name: Resolve GitHub Container Registry Images
  uses: optivem/resolve-latest-docker-digests-action@v1
  with:
    images: |
      [
        "ghcr.io/myorg/frontend:latest",
        "ghcr.io/myorg/backend:latest",
        "ghcr.io/myorg/worker:latest"
      ]
```

### Current Repository Images

```yaml
- name: Resolve Current Repository Images
  uses: optivem/resolve-latest-docker-digests-action@v1
  with:
    images: |
      [
        "ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}/app:latest",
        "ghcr.io/${{ github.repository_owner }}/${{ github.event.repository.name }}/worker:latest"
      ]
```

### Multiple Registries

```yaml
- name: Resolve Images from Multiple Registries
  uses: optivem/resolve-latest-docker-digests-action@v1
  with:
    images: |
      [
        "nginx:latest",
        "ghcr.io/myorg/app:latest",
        "mcr.microsoft.com/dotnet/aspnet:8.0",
        "myregistry.azurecr.io/myapp:latest"
      ]
```

## Working with Private Registries

For private registries, make sure Docker is authenticated before running this action:

```yaml
- name: Login to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Resolve Private Images
  uses: optivem/resolve-latest-docker-digests-action@v1
  with:
    images: |
      [
        "ghcr.io/myorg/private-app:latest"
      ]
```

## Error Handling

The action uses **fail-fast behavior** - it will stop immediately on the first image that fails to resolve. This ensures:

- ✅ **Quick feedback**: Immediate failure detection
- ✅ **Resource efficiency**: Don't waste time on remaining images when one fails
- ✅ **Clear debugging**: Focus on the specific image that failed

### Common Error Scenarios

1. **Image not found**: Returns exit code 1 with clear error message
2. **Authentication required**: Ensure you're logged in to the registry
3. **Network issues**: Temporary failures will cause the action to fail
4. **Invalid image URL**: Malformed URLs will be rejected

## Why Use Digests?

Docker digests provide immutable references to specific image versions:

- **🔒 Immutable**: Digests never change, unlike tags
- **🔍 Precise**: Points to exact image content  
- **🛡️ Secure**: Prevents tag-based attacks
- **📋 Auditable**: Know exactly what's deployed

Example of using resolved digests:
```yaml
# Instead of: nginx:latest (mutable)
# Use: nginx@sha256:abc123... (immutable)
```

## Requirements

- Docker must be available in the runner environment
- For private registries, appropriate authentication must be configured
- Images must support digest resolution (most modern registries do)

## Contributing

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/resolve-latest-docker-digests-action.git
   cd resolve-latest-docker-digests-action
   ```

3. Make sure you have PowerShell installed for testing the script locally

4. Test the action locally by running the PowerShell script:
   ```powershell
   .\test-refactored.ps1
   ```

5. Create a Pull Request with your changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a complete list of changes.
