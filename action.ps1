
param(
    [Parameter(Mandatory=$true)]
    [string]$ImagesJson,
    [Parameter(Mandatory=$false)]
    [string]$GitHubOutput = $env:GITHUB_OUTPUT
)

# Set error action preference
$ErrorActionPreference = "Stop"

function Get-DockerImageDigest {
    param(
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$ImageName,
        [string]$DisplayName = $null
    )
    
    if ([string]::IsNullOrEmpty($DisplayName)) {
        $DisplayName = $ImageName
    }
    
    try {
        # Always use "latest" as the version
        $Version = "latest"
        
        # Construct image tag
        $IMAGE = "ghcr.io/$RepoOwner/$RepoName/$ImageName"
        $IMAGE_WITH_TAG = "$IMAGE" + ":" + "$Version"
        Write-Host "🔍 [$DisplayName] Resolving image: $IMAGE_WITH_TAG"

        # Pull the image to get the exact digest
        Write-Host "📥 [$DisplayName] Pulling image to get digest..."
        docker pull $IMAGE_WITH_TAG | Out-Host
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to pull Docker image: $IMAGE_WITH_TAG"
        }

        # Get the image digest using a more reliable method
        Write-Host "🔎 [$DisplayName] Resolving digest..."
        
        # First try to get digest directly from docker inspect
        $inspectResult = docker inspect $IMAGE_WITH_TAG --format='{{index .RepoDigests 0}}' 2>$null
        
        if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($inspectResult)) {
            # Extract just the digest part (after @)
            if ($inspectResult -match '@(.+)$') {
                $DIGEST = $matches[1]
            } else {
                throw "Could not parse digest from: $inspectResult"
            }
        } else {
            # Fallback to JSON parsing
            Write-Host "🔄 [$DisplayName] Fallback to JSON parsing..."
            $inspectJson = docker inspect $IMAGE_WITH_TAG | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to inspect Docker image: $IMAGE_WITH_TAG"
            }
            
            if ($inspectJson.Count -eq 0 -or -not $inspectJson[0].RepoDigests -or $inspectJson[0].RepoDigests.Count -eq 0) {
                throw "No digest found for image: $IMAGE_WITH_TAG. The image may not be from a registry that supports digests."
            }
            
            $repoDigest = $inspectJson[0].RepoDigests[0]
            if ($repoDigest -match '@(.+)$') {
                $DIGEST = $matches[1]
            } else {
                throw "Could not parse digest from: $repoDigest"
            }
        }
        
        if ([string]::IsNullOrEmpty($DIGEST)) {
            throw "Failed to extract digest from image: $IMAGE_WITH_TAG"
        }
        
        # Validate digest format (should be sha256:...)
        if ($DIGEST -notmatch '^sha256:[a-f0-9]{64}$') {
            Write-Host "⚠️ [$DisplayName] Warning: Digest format may be unexpected: $DIGEST"
        }
        
        Write-Host "✅ [$DisplayName] Image digest resolved: $DIGEST"
        return $DIGEST
    }
    catch {
        Write-Error "❌ [$DisplayName] Error processing $IMAGE_WITH_TAG`: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "🚀 Starting batch Docker image digest resolution..."
    
    # Log full input
    Write-Output ""
    Write-Output "📥 FULL INPUT:"
    Write-Output "ImagesJson: $ImagesJson"
    Write-Output "GitHubOutput: $GitHubOutput"
    Write-Output ""
    
    # Parse the JSON input
    $images = $ImagesJson | ConvertFrom-Json
    
    # Log parsed input structure
    Write-Output "📋 PARSED INPUT STRUCTURE:"
    $formattedInput = $images | ConvertTo-Json -Depth 10
    Write-Output $formattedInput
    Write-Output ""
    
    if ($images.Count -eq 0) {
        throw "No images provided in the input JSON"
    }
    
    Write-Output "📋 Processing $($images.Count) image(s)..."
    
    # Initialize results
    $results = @{}
    
    # Process each image
    foreach ($image in $images) {
        $imageKey = $image.imageName
        Write-Output ""
        Write-Output "🔄 Processing: $imageKey"
        
        # Validate required properties
        if (-not $image.repoOwner -or -not $image.repoName -or -not $image.imageName) {
            Write-Error "❌ Missing required properties for image '$imageKey'. Each image must have: repoOwner, repoName, imageName"
            exit 1
        }
        
        # Get digest - any failure will cause immediate exit
        $digest = Get-DockerImageDigest -RepoOwner $image.repoOwner -RepoName $image.repoName -ImageName $image.imageName -DisplayName $imageKey
        
        $results[$imageKey] = @{
            digest = $digest
            status = "success"
            image = "ghcr.io/$($image.repoOwner)/$($image.repoName)/$($image.imageName):latest"
        }
    }
    
    # Output results
    Write-Output ""
    Write-Output "📊 Summary:"
    $successCount = $results.Count
    Write-Output "✅ All $successCount image(s) processed successfully!"
    
    if ($GitHubOutput) {
        # Output JSON results
        $jsonOutput = $results | ConvertTo-Json -Compress
        "digests=$jsonOutput" | Out-File -FilePath $GitHubOutput -Append -Encoding utf8
        Write-Output "📝 JSON results written to GitHub output"
    }
    
    # Log full output
    Write-Output ""
    Write-Output "📤 FULL OUTPUT:"
    $formattedOutput = $results | ConvertTo-Json -Depth 10
    Write-Output $formattedOutput
    
    Write-Output ""
    Write-Output "🎉 Batch digest resolution completed successfully!"
    
} catch {
    Write-Error "❌ Batch digest resolution failed: $($_.Exception.Message)"
    exit 1
}