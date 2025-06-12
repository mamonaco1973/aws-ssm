
Write-Host "NOTE: Validating that required commands are found in your PATH." -ForegroundColor Green
$commands = @("aws", "packer", "terraform")
$all_found = $true

foreach ($cmd in $commands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "ERROR: $cmd is not found in the current PATH."
        $all_found = $false
    } else { 
        Write-Host "NOTE: $cmd is found in the current PATH." -ForegroundColor Green
    }
}

if ($all_found) {
    Write-Host "NOTE: All required commands are available." -ForegroundColor Green
} else {
    Write-Error "ERROR: One or more commands are missing." 
    exit 1
}

Write-Host "NOTE: Checking AWS CLI connection." -ForegroundColor Green
try {
    $account = aws sts get-caller-identity --query "Account" --output text
    Write-Host "NOTE: Successfully logged into AWS." -ForegroundColor Green
} catch {
    Write-Error "ERROR: Failed to connect to AWS. Please check your credentials and environment variables." 
    exit 1
}
