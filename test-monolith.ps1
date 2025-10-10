# Test script for your actual monolith image
# Use this once you have published your monolith image to ghcr.io

# Your actual image configuration (matches your GitHub Actions workflow)
$imagesJson = @'
[
  {
    "repoOwner": "optivem",
    "repoName": "resolve-latest-docker-digests",
    "imageName": "monolith"
  }
]
'@

Write-Output "🔍 Checking if your monolith image exists..."
Write-Output "Expected image: ghcr.io/optivem/resolve-latest-docker-digests/monolith:latest"
Write-Output ""

# First, let's check if the image exists without running the full script
try {
    Write-Output "🔎 Quick check - attempting to pull the image..."
    docker pull ghcr.io/optivem/resolve-latest-docker-digests/monolith:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Output "✅ Image exists! Running full test..."
        
        # Create a temporary output file to simulate GITHUB_OUTPUT
        $tempOutputFile = Join-Path $env:TEMP "github_output_monolith_test.txt"
        
        # Run the action script
        & ".\action.ps1" -ImagesJson $imagesJson -GitHubOutput $tempOutputFile
        
        Write-Output ""
        Write-Output "📄 Contents of simulated GitHub output file:"
        if (Test-Path $tempOutputFile) {
            Get-Content $tempOutputFile
        }
        
        # Clean up
        if (Test-Path $tempOutputFile) {
            Remove-Item $tempOutputFile -Force
        }
    }
} catch {
    Write-Output "❌ Image doesn't exist yet or isn't accessible."
    Write-Output ""
    Write-Output "📝 To make this test work, you need to:"
    Write-Output "   1. Build and push your monolith image to ghcr.io"
    Write-Output "   2. Make sure it's publicly accessible or you're authenticated"
    Write-Output "   3. The image should be at: ghcr.io/optivem/resolve-latest-docker-digests/monolith:latest"
    Write-Output ""
    Write-Output "🔧 Example commands to build and push:"
    Write-Output "   docker build -t ghcr.io/optivem/resolve-latest-docker-digests/monolith:latest ."
    Write-Output "   docker push ghcr.io/optivem/resolve-latest-docker-digests/monolith:latest"
}