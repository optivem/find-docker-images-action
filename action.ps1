
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
    Write-Host "🚀 Starting batch Docker image digest resolution..."
    
    # Log full input
    Write-Host ""
    Write-Host "ImageUrls: $ImageUrls"
    Write-Host ""


    Write-Host "Image URLs:"

    # Parse image URLs - support both newline-separated and JSON array formats
    $imageUrlList = @()

    # Try to parse as JSON first
    $trimmedInput = $ImageUrls.Trim()
    Write-Host "🔍 Trimmed input: '$trimmedInput'"
    
    if ($trimmedInput.StartsWith('[') -and $trimmedInput.EndsWith(']')) {
        try {
            Write-Host "📋 Detected JSON array format"
            $jsonArray = $trimmedInput | ConvertFrom-Json
            if ($jsonArray -is [Array]) {
                $imageUrlList = $jsonArray | Where-Object { ![string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() }
            } else {
                # Single item in JSON array
                $imageUrlList = @($jsonArray.Trim())
            }
        } catch {
            Write-Error "❌ Invalid JSON format in image-urls input: $($_.Exception.Message)"
            exit 1
        }
    } else {
        # Parse as newline-separated format
        Write-Host "📋 Detected newline-separated format"
        $imageUrlList = $ImageUrls -split "`r?`n" | Where-Object { 
            ![string]::IsNullOrWhiteSpace($_) -and $_.Trim() -notmatch "^#" 
        } | ForEach-Object { $_.Trim() }
    }

    if ($imageUrlList.Count -eq 0) {
        Write-Error "❌ No valid image URLs provided. Please provide at least one image URL."
        exit 1
    }

    foreach ($url in $imageUrlList) {
        Write-Host "  - $url"
    }

    # Assign the parsed image URLs to the variable expected by the rest of the script
    $images = $imageUrlList

    Write-Host "📋 Processing $($images.Count) image(s)..."
    
    # Initialize results as array to preserve order
    $results = @()
    
    # Process each image URL
    foreach ($imageUrl in $images) {
        Write-Host ""
        Write-Host "🔄 Processing: $imageUrl"
        
        # Validate that we have a non-empty string
        if ([string]::IsNullOrWhiteSpace($imageUrl)) {
            Write-Error "❌ Empty or invalid image URL provided"
            exit 1
        }
        
        # Get digest - any failure will cause immediate exit
        $digest = Get-DockerImageDigest -ImageUrl $imageUrl
        
        # Create the digest URL by replacing tag with digest
        $digestUrl = ""
        if ($imageUrl -match '^(.+):([^@]+)$') {
            # Image has a tag, replace it with digest
            $digestUrl = $matches[1] + "@" + $digest
        } elseif ($imageUrl -match '^(.+)@.+$') {
            # Image already has a digest, replace it with new digest
            $digestUrl = $matches[1] + "@" + $digest
        } else {
            # No tag specified, assume :latest and replace with digest
            $digestUrl = $imageUrl + "@" + $digest
        }
        
        $results += $digestUrl
    }
    
    # Output results
    Write-Host ""
    Write-Host "📊 Summary:"
    $successCount = $results.Count
    Write-Host "✅ All $successCount image(s) processed successfully!"
    
    if ($GitHubOutput) {
        # Output JSON results - always as array format
        $jsonOutput = $results | ConvertTo-Json -Compress -AsArray
        "digests=$jsonOutput" | Out-File -FilePath $GitHubOutput -Append -Encoding utf8
        Write-Host "📝 JSON results written to GitHub output"
    }
    
    # Log full output
    Write-Host ""
    Write-Host "📤 FULL OUTPUT:"
    $formattedOutput = $results | ConvertTo-Json -Depth 10 -AsArray
    Write-Output $formattedOutput
    
    Write-Host ""
    Write-Host "🎉 Batch digest resolution completed successfully!"
    
} catch {
    Write-Error "❌ Batch digest resolution failed: $($_.Exception.Message)"
    exit 1
}