Write-Host "Generating traffic for A1 Water Tech Backend..."

for ($i = 1; $i -le 50; $i++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing | Out-Null
        Invoke-WebRequest -Uri "http://localhost:3000/metrics" -UseBasicParsing | Out-Null
        Write-Host -NoNewline "."
    } catch {
        Write-Host -NoNewline "x"
    }
    Start-Sleep -Milliseconds 200
}

Write-Host "`nTraffic generation complete! Check Prometheus dashboard."
