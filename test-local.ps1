# Test script to run the action locally
# This simulates how GitHub Actions would call your script
# NOTE: Script now uses fail-fast behavior - stops on first error

# Your image configuration
$imagesJson = @'
[
  {
    "repoOwner": "optivem",
    "repoName": "atdd-accelerator-template-dotnet",
    "imageName": "monolith"
  }
]
'@

# Create a temporary output file to simulate GITHUB_OUTPUT
$tempOutputFile = Join-Path $env:TEMP "github_output_test.txt"
Write-Output "Using temporary output file: $tempOutputFile"

# Run the action script
try {
    Write-Output "🧪 Testing the action locally..."
    Write-Output "Repository: optivem/resolve-latest-docker-digests"
    Write-Output "Image: monolith"
    Write-Output ""
    
    # Call the action script with your parameters
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