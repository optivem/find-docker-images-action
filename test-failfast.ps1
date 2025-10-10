# Test script to demonstrate fail-fast behavior
# Shows that the script stops immediately on the first failure

Write-Output "🧪 Testing fail-fast behavior with multiple images..."
Write-Output "Expected behavior: Should stop processing after first image fails"
Write-Output ""

# Test with multiple images where the first one will fail
$imagesJson = @'
[
  {
    "repoOwner": "optivem",
    "repoName": "resolve-latest-docker-digests",
    "imageName": "this-will-fail-first"
  },
  {
    "repoOwner": "optivem", 
    "repoName": "resolve-latest-docker-digests",
    "imageName": "this-should-never-be-processed"
  },
  {
    "repoOwner": "optivem",
    "repoName": "resolve-latest-docker-digests", 
    "imageName": "neither-should-this"
  }
]
'@

# Create a temporary output file to simulate GITHUB_OUTPUT
$tempOutputFile = Join-Path $env:TEMP "github_output_failfast_test.txt"

try {
    Write-Output "📋 Input: 3 images (all non-existent)"
    Write-Output "Expected: Process only the first image, then fail immediately"
    Write-Output ""
    
    # Call the action script
    & ".\action.ps1" -ImagesJson $imagesJson -GitHubOutput $tempOutputFile
    
    Write-Output "❌ UNEXPECTED: Script completed without error!"
    
} catch {
    Write-Output "✅ EXPECTED: Script failed fast on first image"
    Write-Output "Exit code should be 1"
} finally {
    # Clean up
    if (Test-Path $tempOutputFile) {
        Remove-Item $tempOutputFile -Force
    }
}

Write-Output ""
Write-Output "📊 Check the output above:"
Write-Output "   ✅ Should show processing of 'this-will-fail-first'"
Write-Output "   ✅ Should NOT show processing of the other 2 images"
Write-Output "   ✅ Should exit with error code 1"