#!/usr/bin/env powershell
# Скрипт для запуску TourismDemo проєкту

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "TourismDemo - Запуск навчального проєкту" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Перейти до папки проєкту
$projectPath = "C:\Users\Влад\Desktop\БД ЛАБИ\TourismDemo"
Set-Location $projectPath

Write-Host "📁 Робоча папка: $projectPath" -ForegroundColor Yellow
Write-Host ""

# Перевірити .NET версію
Write-Host "🔍 Перевіркa .NET SDK версії..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version
Write-Host "✓ .NET версія: $dotnetVersion" -ForegroundColor Green
Write-Host ""

# Restore
Write-Host "📦 Восстановление залежностей (restore)..." -ForegroundColor Yellow
dotnet restore
Write-Host "✓ Restore завершено" -ForegroundColor Green
Write-Host ""

# Build
Write-Host "🔨 Компіляція проєкту (build)..." -ForegroundColor Yellow
dotnet build
Write-Host "✓ Build завершено" -ForegroundColor Green
Write-Host ""

# Run
Write-Host "🚀 Запуск проєкту..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⏳ Дочекайтеся, поки сервер стартує..." -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 Інформація про запуск:" -ForegroundColor Yellow
Write-Host "   - Веб-сайт: https://localhost:5001" -ForegroundColor White
Write-Host "   - Swagger API: https://localhost:5001/swagger" -ForegroundColor White
Write-Host ""
Write-Host "💡 Порти можуть бути інші. Дивіться вивід нижче." -ForegroundColor Cyan
Write-Host ""

dotnet run

Write-Host ""
Write-Host "🛑 Проєкт зупинено" -ForegroundColor Yellow
Write-Host ""
