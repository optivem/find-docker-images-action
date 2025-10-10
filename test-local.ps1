# Test script for the action - now returns complete digest URLs
# This demonstrates getting immutable digest URLs instead of mutable tag URLs

# Test with various registries using newline-separated format
$imageUrls = @'
ghcr.io/optivem/atdd-accelerator-template-dotnet/monolith:latest
nginx:latest
'@

# Create a temporary output file to simulate GITHUB_OUTPUT
$tempOutputFile = Join-Path $env:TEMP "github_output_refactored_test.txt"
Write-Output "Using temporary output file: $tempOutputFile"

# Run the action script
try {
    Write-Output "🧪 Testing the action - now returns complete digest URLs..."
    Write-Output "Input: Tag-based image URLs"
    Write-Output "Output: Complete digest URLs (immutable references)"
    Write-Output ""
    Write-Output "Images to test:"
    Write-Output "  1. ghcr.io/optivem/atdd-accelerator-template-dotnet/monolith:latest"
    Write-Output "  2. nginx:latest"
    Write-Output ""
    
    # Call the action script with newline-separated image URLs
    & ".\action.ps1" -ImageUrls $imageUrls -GitHubOutput $tempOutputFile
    
    Write-Output ""
    Write-Output "📄 Contents of simulated GitHub output file:"
    if (Test-Path $tempOutputFile) {
        Get-Content $tempOutputFile
    } else {
        Write-Output "No output file was created."
    }
    
} catch {
    Write-Error "❌ Test failed: $($_.Exception.Message)"
} finally {
    # Clean up
    if (Test-Path $tempOutputFile) {
        Remove-Item $tempOutputFile -Force
        Write-Output ""
        Write-Output "🧹 Cleaned up temporary output file"
    }
}