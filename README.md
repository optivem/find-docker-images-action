# Inspect Docker Image Action

A GitHub Action that extracts the exact digest of a Docker image from GitHub Container Registry (GHCR).

## Description

This action pulls a specified Docker image from GitHub Container Registry and extracts its exact digest. This is useful for ensuring you're working with the precise version of an image, especially in security-conscious environments where you need reproducible builds.

## Inputs

| Input | Description | Required | Example |
|-------|-------------|----------|---------|
| `repo-owner` | GitHub repository owner (organization or user) | Yes | `optivem` |
| `repo-name` | GitHub repository name | Yes | `my-app` |
| `image-name` | Docker image name | Yes | `api` |
| `version` | Docker image tag or version | Yes | `v1.0.0` |

## Outputs

| Output | Description |
|--------|-------------|
| `digest` | The exact SHA256 digest of the Docker image |

## Usage

### Basic Example

```yaml
name: Get Docker Image Digest
on: [push]

jobs:
  inspect:
    runs-on: ubuntu-latest
    steps:
      - name: Inspect Docker Image
        id: inspect
        uses: optivem/inspect-docker-action@v1
        with:
          repo-owner: 'optivem'
          repo-name: 'my-application'
          image-name: 'api'
          version: 'v1.0.0'
      
      - name: Use the digest
        run: |
          echo "Image digest: ${{ steps.inspect.outputs.digest }}"
```

### Security Scanning Example

```yaml
name: Security Scan
on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Get Image Digest
        id: inspect
        uses: optivem/inspect-docker-action@v1
        with:
          repo-owner: 'myorg'
          repo-name: 'myapp'
          image-name: 'backend'
          version: 'latest'
      
      - name: Run security scan with exact digest
        run: |
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image ghcr.io/myorg/myapp/backend@${{ steps.inspect.outputs.digest }}
```

## How It Works

1. **Image Construction**: Builds the full image path as `ghcr.io/{repo-owner}/{repo-name}/{image-name}:{version}`
2. **Image Pull**: Uses `docker pull` to download the specified image
3. **Digest Extraction**: Inspects the pulled image to extract its SHA256 digest
4. **Output**: Sets the digest as an output variable for use in subsequent steps

## Requirements

- The runner must have Docker installed and accessible
- The Docker image must be publicly accessible or the runner must be authenticated to GHCR
- The specified image and tag must exist in the repository

## Authentication

If your Docker images are private, ensure your workflow is authenticated with GitHub Container Registry:

```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v2
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Inspect Private Image
  uses: optivem/inspect-docker-action@v1
  with:
    repo-owner: 'myorg'
    repo-name: 'private-repo'
    image-name: 'private-image'
    version: 'v1.0.0'
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
