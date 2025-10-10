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

& ".\action.ps1" -ImagesJson $imagesJson -GitHubOutput $tempOutputFile