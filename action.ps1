
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoOwner,
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ImageName,
    [Parameter(Mandatory=$true)]
    [string]$Version,
    [Parameter(Mandatory=$false)]
    [string]$GitHubOutput = $env:GITHUB_OUTPUT
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    # Construct image tag
    $IMAGE = "ghcr.io/$RepoOwner/$RepoName/$ImageName"
    $IMAGE_WITH_TAG = "$IMAGE" + ":" + "$Version"
    Write-Output "🔍 Inspecting image: $IMAGE_WITH_TAG"

    # Pull the image to get the exact digest
    Write-Output "📥 Pulling image to get digest..."
    docker pull $IMAGE_WITH_TAG
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to pull Docker image: $IMAGE_WITH_TAG"
    }

    # Get the image digest
    Write-Output "🔎 Extracting digest..."
    $inspectResult = docker inspect $IMAGE_WITH_TAG | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to inspect Docker image: $IMAGE_WITH_TAG"
    }
    
    if ($inspectResult.Count -eq 0 -or -not $inspectResult[0].RepoDigests) {
        throw "No digest found for image: $IMAGE_WITH_TAG"
    }
    
    $DIGEST = $inspectResult[0].RepoDigests[0] -replace '.*@', ''
    
    if ([string]::IsNullOrEmpty($DIGEST)) {
        throw "Failed to extract digest from image: $IMAGE_WITH_TAG"
    }
    
    Write-Output "✅ Image digest: $DIGEST"

    # Set outputs
    if ($GitHubOutput) {
        "digest=$DIGEST" | Out-File -FilePath $GitHubOutput -Append -Encoding utf8
        Write-Output "📝 Digest written to GitHub output"
    }
    else {
        Write-Output "⚠️ GITHUB_OUTPUT not set, digest not written to output file"
    }
    
    Write-Output "🎉 Successfully extracted digest for $IMAGE_WITH_TAG"
}
catch {
    Write-Error "❌ Error: $($_.Exception.Message)"
    exit 1
}