# Resolve Latest Docker Digests Action

A GitHub Action that resolves the latest Docker image digests from GitHub Container Registry for multiple images in batch.

## Description

This action processes multiple Docker images from GitHub Container Registry and resolves their exact digests. Perfect for microservices architectures where you need to get digests for frontend applications, multiple backend services, and other components all at once.

## Inputs

| Input | Description | Required | Example |
|-------|-------------|----------|---------|
| `images` | JSON array of images to resolve. Each image should have: `repoOwner`, `repoName`, `imageName` (version is always "latest") | Yes | See examples below |

### Image Object Structure

Each image in the JSON array should have:
- `repoOwner`: GitHub repository owner (organization or user)
- `repoName`: GitHub repository name  
- `imageName`: Docker image name

**Note**: The version is always set to "latest" automatically.

## Outputs

| Output | Description |
|--------|-------------|
| `digests` | JSON object containing all resolved image digests with status information |

## Usage Examples

### Multiple Microservices from Different Repositories

```yaml
name: Resolve All Service Digests
on: [push]

jobs:
  resolve-digests:
    runs-on: ubuntu-latest
    steps:
      - name: Resolve Docker Image Digests
        id: inspect
        uses: optivem/inspect-docker-action@v1
        with:
          images: |
            [
              {
                "repoOwner": "myorg",
                "repoName": "frontend-repo",
                "imageName": "frontend"
              },
              {
                "repoOwner": "myorg", 
                "repoName": "user-service-repo",
                "imageName": "user-service"
              },
              {
                "repoOwner": "myorg",
                "repoName": "order-service-repo", 
                "imageName": "order-service"
              },
              {
                "repoOwner": "myorg",
                "repoName": "payment-service-repo",
                "imageName": "payment-service"
              }
            ]
      
      - name: Use the digests
        run: |
          # Extract individual digests from JSON
          RESULTS='${{ steps.inspect.outputs.digests }}'
          FRONTEND_DIGEST=$(echo "$RESULTS" | jq -r '.frontend.digest')
          USER_SERVICE_DIGEST=$(echo "$RESULTS" | jq -r '."user-service".digest')
          ORDER_SERVICE_DIGEST=$(echo "$RESULTS" | jq -r '."order-service".digest')
          
          echo "Frontend: $FRONTEND_DIGEST"
          echo "User Service: $USER_SERVICE_DIGEST"
          echo "Order Service: $ORDER_SERVICE_DIGEST"
          echo "All results: $RESULTS"
```

### Same Repository, Multiple Images

```yaml
name: Resolve Multi-Container App Digests
on: [push]

jobs:
  resolve-digests:
    runs-on: ubuntu-latest
    steps:
      - name: Resolve Multiple Images from Same Repo
        id: inspect
        uses: optivem/inspect-docker-action@v1
        with:
          images: |
            [
              {
                "repoOwner": "myorg",
                "repoName": "my-app",
                "imageName": "frontend"
              },
              {
                "repoOwner": "myorg", 
                "repoName": "my-app",
                "imageName": "backend"
              },
              {
                "repoOwner": "myorg",
                "repoName": "my-app", 
                "imageName": "worker"
              }
            ]
      
      - name: Deploy with exact digests
        run: |
          # Extract digests from JSON
          RESULTS='${{ steps.inspect.outputs.digests }}'
          FRONTEND_DIGEST=$(echo "$RESULTS" | jq -r '.frontend.digest')
          BACKEND_DIGEST=$(echo "$RESULTS" | jq -r '.backend.digest')
          WORKER_DIGEST=$(echo "$RESULTS" | jq -r '.worker.digest')
          
          echo "Deploying frontend@$FRONTEND_DIGEST"
          echo "Deploying backend@$BACKEND_DIGEST"
          echo "Deploying worker@$WORKER_DIGEST"
```

### Security Scanning Example

```yaml
name: Security Scan All Services
on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Resolve Service Digests
        id: inspect
        uses: optivem/inspect-docker-action@v1
        with:
          images: |
            [
              {
                "repoOwner": "myorg",
                "repoName": "services",
                "imageName": "api"
              },
              {
                "repoOwner": "myorg",
                "repoName": "services", 
                "imageName": "web"
              }
            ]
      
      - name: Scan API with exact digest
        run: |
          RESULTS='${{ steps.inspect.outputs.digests }}'
          API_DIGEST=$(echo "$RESULTS" | jq -r '.api.digest')
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image ghcr.io/myorg/services/api@$API_DIGEST
      
      - name: Scan Web with exact digest  
        run: |
          RESULTS='${{ steps.inspect.outputs.digests }}'
          WEB_DIGEST=$(echo "$RESULTS" | jq -r '.web.digest')
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image ghcr.io/myorg/services/web@$WEB_DIGEST
```

### Using GitHub Context Variables

```yaml
- name: Resolve Current Repository Images
  id: inspect
  uses: optivem/inspect-docker-action@v1
  with:
    images: |
      [
        {
          "repoOwner": "${{ github.repository_owner }}",
          "repoName": "${{ github.event.repository.name }}",
          "imageName": "frontend"
        },
        {
          "repoOwner": "${{ github.repository_owner }}",
          "repoName": "${{ github.event.repository.name }}",
          "imageName": "backend"
        }
      ]

- name: Use resolved digests
  run: |
    RESULTS='${{ steps.inspect.outputs.digests }}'
    echo "Results: $RESULTS"
```

### Using JSON Output for Dynamic Processing

```yaml
- name: Process All Digests
  run: |
    # Parse the JSON output
    RESULTS='${{ steps.inspect.outputs.digests }}'
    echo "All digests: $RESULTS"
    
    # Extract specific digests using jq
    echo "$RESULTS" | jq -r 'to_entries[] | "\(.key): \(.value.digest)"'
    
    # Check status of each image
    echo "$RESULTS" | jq -r 'to_entries[] | select(.value.status == "failed") | "Failed: \(.key) - \(.value.error)"'
    
    # Get only successful digests
    echo "$RESULTS" | jq -r 'to_entries[] | select(.value.status == "success") | "\(.key)=\(.value.digest)"'
```

## JSON Output Format

The `digests` output contains a JSON object where each key is the image name and the value contains:

```json
{
  "frontend": {
    "digest": "sha256:abc123...",
    "status": "success",
    "image": "ghcr.io/myorg/app/frontend:latest"
  },
  "backend": {
    "digest": "sha256:def456...",
    "status": "success", 
    "image": "ghcr.io/myorg/app/backend:latest"
  },
  "worker": {
    "digest": null,
    "status": "failed",
    "error": "Failed to pull Docker image: ghcr.io/myorg/app/worker:latest",
    "image": "ghcr.io/myorg/app/worker:latest"
  }
}
```

### Accessing Individual Digests

```bash
# Extract a specific digest
FRONTEND_DIGEST=$(echo "$RESULTS" | jq -r '.frontend.digest')

# Check if an image was successful
STATUS=$(echo "$RESULTS" | jq -r '.frontend.status')
if [ "$STATUS" = "success" ]; then
  echo "Frontend processed successfully"
fi

# Get all successful images
jq -r 'to_entries[] | select(.value.status == "success") | .key' <<< "$RESULTS"
```

## How It Works

1. **JSON Parsing**: Parses the input JSON array of images
2. **Batch Processing**: Processes each image in sequence
3. **Image Pull**: Uses `docker pull` to download each specified image
4. **Digest Resolution**: Inspects each image to resolve its SHA256 digest
5. **JSON Output**: Creates a comprehensive JSON object with all results and status information
6. **Error Handling**: Continues processing other images if one fails

## Requirements

- The runner must have Docker installed and accessible
- The Docker images must be publicly accessible or the runner must be authenticated to GHCR
- All specified images and tags must exist in their respective repositories

## Authentication for Private Images

If your Docker images are private, ensure your workflow is authenticated with GitHub Container Registry:

```yaml
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v2
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Inspect Private Images
  uses: optivem/inspect-docker-action@v1
  with:
    images: |
      [
        {
          "repoOwner": "myorg",
          "repoName": "private-repo",
          "imageName": "private-service"
        }
      ]
```

## Error Handling

- If any image fails to process, the action will continue with remaining images
- The action exits with code 1 if any images failed
- Failed images are included in the JSON output with error details and `"status": "failed"`
- Successful images have `"status": "success"` and contain the digest

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
