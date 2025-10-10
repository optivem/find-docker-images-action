# Test script with an existing public image for demonstration
# This uses a real image that exists to test the functionality

# Test with a known existing image (using a popular public image)
$imagesJson = @'
[
  {
    "repoOwner": "microsoft",
    "repoName": "dotnet",
    "imageName": "aspnet"
  }
]
'@

# Create a temporary output file to simulate GITHUB_OUTPUT
$tempOutputFile = Join-Path $env:TEMP "github_output_test_existing.txt"
Write-Output "Using temporary output file: $tempOutputFile"

# Run the action script
try {
    Write-Output "🧪 Testing with existing public image..."
    Write-Output "Repository: microsoft/dotnet"
    Write-Output "Image: aspnet"
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