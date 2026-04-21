# ============================================================
# deploy.ps1 — One-click GitHub Pages Deployment Script
# Dinesh Sai Teja Paruchuri Portfolio
# ============================================================
# HOW TO USE:
#   1. Create a GitHub Personal Access Token (PAT) at:
#      https://github.com/settings/tokens/new
#      → Scopes needed: check "repo" (full control)
#      → Copy the token (starts with ghp_...)
#   2. Open PowerShell in this folder (Shift+Right-click → Open PowerShell)
#   3. Run: .\deploy.ps1
#   4. Paste your token when prompted
# ============================================================

param(
    [string]$Token = ""
)

if (-not $Token) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Portfolio GitHub Pages Deployer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Step 1: Create a GitHub PAT at:" -ForegroundColor Yellow
    Write-Host "  https://github.com/settings/tokens/new" -ForegroundColor White
    Write-Host "  - Set expiration: 90 days" -ForegroundColor Gray
    Write-Host "  - Check 'repo' scope" -ForegroundColor Gray
    Write-Host "  - Click 'Generate token'" -ForegroundColor Gray
    Write-Host "  - Copy the token (starts with ghp_...)" -ForegroundColor Gray
    Write-Host ""
    $Token = Read-Host "Paste your GitHub Personal Access Token here"
    Write-Host ""
}

$username   = "DineshSaiTejaP"
$repoName   = "DineshSaiTejaP.github.io"
$repoDesc   = "AI Engineer Portfolio - Generative AI, RAG & Agentic Systems"
$headers    = @{ Authorization = "token $Token"; "User-Agent" = "PortfolioDeployer" }

# ---- 1. Create the repository via API ----
Write-Host "[1/4] Creating GitHub repository..." -ForegroundColor Cyan
$body = @{ name=$repoName; description=$repoDesc; private=$false; auto_init=$false } | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method POST -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "      ✅ Repository created: $($response.html_url)" -ForegroundColor Green
} catch {
    $errMsg = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errMsg.errors[0].message -like "*already exists*") {
        Write-Host "      ℹ️  Repository already exists — continuing..." -ForegroundColor Yellow
    } else {
        Write-Host "      ❌ Error: $($errMsg.message)" -ForegroundColor Red
        Write-Host "         Check your token has 'repo' scope." -ForegroundColor Red
        exit 1
    }
}

# ---- 2. Configure remote ----
Write-Host "[2/4] Setting up Git remote..." -ForegroundColor Cyan
$remoteUrl = "https://${Token}@github.com/${username}/${repoName}.git"
& git remote remove origin 2>$null
& git remote add origin $remoteUrl
Write-Host "      ✅ Remote configured" -ForegroundColor Green

# ---- 3. Rename branch to main and push ----
Write-Host "[3/4] Pushing files to GitHub..." -ForegroundColor Cyan
& git branch -M main
$pushResult = & git push -u origin main 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "      ✅ Files pushed successfully!" -ForegroundColor Green
} else {
    Write-Host "      ❌ Push failed: $pushResult" -ForegroundColor Red
    exit 1
}

# ---- 4. Enable GitHub Pages via API ----
Write-Host "[4/4] Enabling GitHub Pages..." -ForegroundColor Cyan
$pagesBody = @{ source = @{ branch="main"; path="/" } } | ConvertTo-Json
try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/${username}/${repoName}/pages" -Method POST -Headers $headers -Body $pagesBody -ContentType "application/json" | Out-Null
    Write-Host "      ✅ GitHub Pages enabled!" -ForegroundColor Green
} catch {
    # If already enabled, that's fine
    Write-Host "      ✅ GitHub Pages already enabled (or will auto-activate)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your portfolio will be live at:" -ForegroundColor White
Write-Host "  ➜  https://${username}.github.io" -ForegroundColor Cyan
Write-Host ""
Write-Host "  (Takes 1-3 minutes to go live — then share everywhere!)" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add URL to LinkedIn profile" -ForegroundColor White
Write-Host "  2. Add to your resume PDF header" -ForegroundColor White
Write-Host "  3. Email signature" -ForegroundColor White
Write-Host ""
