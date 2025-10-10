# Test script for the refactored action using image URLs
# This demonstrates the new flexible approach

# Test with various registries and image URLs
$imagesJson = @'
[
  "ghcr.io/optivem/atdd-accelerator-template-dotnet/monolith:latest",
  "nginx:latest"
]
'@

# Create a temporary output file to simulate GITHUB_OUTPUT
$tempOutputFile = Join-Path $env:TEMP "github_output_refactored_test.txt"
Write-Output "Using temporary output file: $tempOutputFile"

# Run the action script
try {
    Write-Output "🧪 Testing the refactored action with image URLs..."
    Write-Output "Images to test:"
    Write-Output "  1. ghcr.io/optivem/atdd-accelerator-template-dotnet/monolith:latest"
    Write-Output "  2. nginx:latest"
    Write-Output ""
    
    # Call the action script with image URLs
    & ".\action.ps1" -ImagesJson $imagesJson -GitHubOutput $tempOutputFile
    
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