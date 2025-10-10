
param(
    [Parameter(Mandatory=$true)]
    [string]$ImageUrls,
    [Parameter(Mandatory=$false)]
    [string]$GitHubOutput = $env:GITHUB_OUTPUT
)

# Set error action preference
$ErrorActionPreference = "Stop"

function Get-DockerImageDigest {
    param(
        [string]$ImageUrl
    )
    
    try {
        Write-Host "🔍 Resolving image: $ImageUrl"

        # Pull the image to get the exact digest
        Write-Host "📥 Pulling image to get digest..."
        docker pull $ImageUrl | Out-Host
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to pull Docker image: $ImageUrl"
        }

        # Get the image digest using docker inspect
        Write-Host "🔎 Resolving digest..."
        
        # First try to get digest directly from docker inspect
        $inspectResult = docker inspect $ImageUrl --format='{{index .RepoDigests 0}}' 2>$null
        
        if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($inspectResult)) {
            # Extract just the digest part (after @)
            if ($inspectResult -match '@(.+)$') {
                $DIGEST = $matches[1]
            } else {
                throw "Could not parse digest from: $inspectResult"
            }
        } else {
            # Fallback to JSON parsing
            Write-Host "🔄 Fallback to JSON parsing..."
            $inspectJson = docker inspect $ImageUrl | ConvertFrom-Json
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to inspect Docker image: $ImageUrl"
            }
            
            if ($inspectJson.Count -eq 0 -or -not $inspectJson[0].RepoDigests -or $inspectJson[0].RepoDigests.Count -eq 0) {
                throw "No digest found for image: $ImageUrl. The image may not be from a registry that supports digests."
            }
            
            $repoDigest = $inspectJson[0].RepoDigests[0]
            if ($repoDigest -match '@(.+)$') {
                $DIGEST = $matches[1]
            } else {
                throw "Could not parse digest from: $repoDigest"
            }
        }
        
        if ([string]::IsNullOrEmpty($DIGEST)) {
            throw "Failed to extract digest from image: $ImageUrl"
        }
        
        # Validate digest format (should be sha256:...)
        if ($DIGEST -notmatch '^sha256:[a-f0-9]{64}$') {
            Write-Host "⚠️ Warning: Digest format may be unexpected: $DIGEST"
        }
        
        Write-Host "✅ Image digest resolved: $DIGEST"
        return $DIGEST
    }
    catch {
        Write-Error "❌ Error processing $ImageUrl`: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "🚀 Starting batch Docker image digest resolution..."
    
    # Log full input
    Write-Output ""
    Write-Output "📥 FULL INPUT:"
    Write-Output "ImageUrls: $ImageUrls"
    Write-Output "GitHubOutput: $GitHubOutput"
    Write-Output ""
    
    # Parse the newline-separated input
    $images = $ImageUrls -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
    
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
    
    # Process each image URL
    foreach ($imageUrl in $images) {
        Write-Output ""
        Write-Output "🔄 Processing: $imageUrl"
        
        # Validate that we have a non-empty string
        if ([string]::IsNullOrWhiteSpace($imageUrl)) {
            Write-Error "❌ Empty or invalid image URL provided"
            exit 1
        }
        
        # Get digest - any failure will cause immediate exit
        $digest = Get-DockerImageDigest -ImageUrl $imageUrl
        
        $results[$imageUrl] = $digest
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