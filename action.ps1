
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
        [string]$Version,
        [string]$DisplayName = $null
    )
    
    if ([string]::IsNullOrEmpty($DisplayName)) {
        $DisplayName = $ImageName
    }
    
    try {
        # Construct image tag
        $IMAGE = "ghcr.io/$RepoOwner/$RepoName/$ImageName"
        $IMAGE_WITH_TAG = "$IMAGE" + ":" + "$Version"
        Write-Output "🔍 [$DisplayName] Inspecting image: $IMAGE_WITH_TAG"

        # Pull the image to get the exact digest
        Write-Output "📥 [$DisplayName] Pulling image to get digest..."
        docker pull $IMAGE_WITH_TAG
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to pull Docker image: $IMAGE_WITH_TAG"
        }

        # Get the image digest using a more reliable method
        Write-Output "🔎 [$DisplayName] Extracting digest..."
        
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
            Write-Output "🔄 [$DisplayName] Fallback to JSON parsing..."
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
            Write-Output "⚠️ [$DisplayName] Warning: Digest format may be unexpected: $DIGEST"
        }
        
        Write-Output "✅ [$DisplayName] Image digest: $DIGEST"
        return $DIGEST
    }
    catch {
        Write-Error "❌ [$DisplayName] Error processing $IMAGE_WITH_TAG`: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "🚀 Starting batch Docker image inspection..."
    
    # Parse the JSON input
    $images = $ImagesJson | ConvertFrom-Json
    
    if ($images.Count -eq 0) {
        throw "No images provided in the input JSON"
    }
    
    Write-Output "📋 Processing $($images.Count) image(s)..."
    
    # Initialize results
    $results = @{}
    
    # Process each image
    foreach ($image in $images) {
        $imageKey = $image.'image-name'
        Write-Output ""
        Write-Output "🔄 Processing: $imageKey"
        
        try {
            # Validate required properties
            if (-not $image.'repo-owner' -or -not $image.'repo-name' -or -not $image.'image-name' -or -not $image.version) {
                throw "Missing required properties. Each image must have: repo-owner, repo-name, image-name, version"
            }
            
            $digest = Get-DockerImageDigest -RepoOwner $image.'repo-owner' -RepoName $image.'repo-name' -ImageName $image.'image-name' -Version $image.version -DisplayName $imageKey
            
            $results[$imageKey] = @{
                digest = $digest
                status = "success"
                image = "ghcr.io/$($image.'repo-owner')/$($image.'repo-name')/$($image.'image-name'):$($image.version)"
            }
            
        } catch {
            Write-Warning "Failed to process $imageKey`: $($_.Exception.Message)"
            $results[$imageKey] = @{
                digest = $null
                status = "failed"
                error = $_.Exception.Message
                image = "ghcr.io/$($image.'repo-owner')/$($image.'repo-name')/$($image.'image-name'):$($image.version)"
            }
        }
    }
    
    # Output results
    Write-Output ""
    Write-Output "📊 Summary:"
    $successCount = ($results.Values | Where-Object { $_.status -eq "success" }).Count
    $failureCount = ($results.Values | Where-Object { $_.status -eq "failed" }).Count
    Write-Output "✅ Successful: $successCount"
    Write-Output "❌ Failed: $failureCount"
    
    if ($GitHubOutput) {
        # Output JSON results
        $jsonOutput = $results | ConvertTo-Json -Compress
        "digests-json=$jsonOutput" | Out-File -FilePath $GitHubOutput -Append -Encoding utf8
        Write-Output "📝 JSON results written to GitHub output"
    }
    
    Write-Output ""
    Write-Output "🎉 Batch processing completed!"
    
    # Exit with error if any images failed
    if ($failureCount -gt 0) {
        Write-Warning "Some images failed to process. Check the logs above for details."
        exit 1
    }
    
} catch {
    Write-Error "❌ Batch processing failed: $($_.Exception.Message)"
    exit 1
}