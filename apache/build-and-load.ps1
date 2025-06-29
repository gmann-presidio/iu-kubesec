# build-and-load.ps1

Write-Host "Building Docker image..."
docker build -t iu-apache:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build succeeded. Loading image into Minikube..."
    minikube image load iu-apache:latest
} else {
    Write-Host "Build failed. Skipping image load." -ForegroundColor Red
    exit 1
}
