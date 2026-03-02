# Define o caminho principal das ROMs (Altere se necessário)
$romsDir = "C:\Emulation\roms"

# Verifica se a pasta base existe
if (-not (Test-Path $romsDir)) {
    Write-Host "A pasta $romsDir não foi encontrada. Verifique o caminho." -ForegroundColor Red
    Pause
    return
}

# Pega apenas as subpastas dentro do diretório principal (psx, saturn, etc.)
$consoleFolders = Get-ChildItem -Path $romsDir -Directory

foreach ($console in $consoleFolders) {
    # Busca arquivos que contenham a palavra "(Disc" no nome
    # O filtro captura tudo que está ANTES do "(Disc" para usar como Nome Base
    $discFiles = Get-ChildItem -Path $console.FullName -File | Where-Object { $_.Name -match "^(.*?)\s*\(\s*Disc\s+[^)]+\)" }

    # Agrupa os arquivos encontrados pelos nomes base
    $groupedFiles = $discFiles | Group-Object { [regex]::Match($_.Name, "^(.*?)\s*\(\s*Disc\s+[^)]+\)").Groups[1].Value.Trim() }

    foreach ($group in $groupedFiles) {
        $baseName = $group.Name
        if ([string]::IsNullOrWhiteSpace($baseName)) { continue }

        # Define os caminhos da nova pasta
        $folderName = "$baseName.m3u"
        $folderPath = Join-Path -Path $console.FullName -ChildPath $folderName

        # Cria a pasta do jogo se ela ainda não existir
        if (-not (Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
        }

        # Define o caminho do arquivo .m3u interno
        $m3uFilePath = Join-Path -Path $folderPath -ChildPath "$baseName.m3u"

        # Remove o arquivo .m3u antigo caso o script seja rodado mais de uma vez
        if (Test-Path -Path $m3uFilePath) {
            Remove-Item -Path $m3uFilePath
        }

        # Ordena os discos alfabeticamente para garantir a ordem (Disc 1, Disc 2, etc.)
        $sortedDiscs = $group.Group | Sort-Object Name

        foreach ($disc in $sortedDiscs) {
            # Move o arquivo original para dentro da pasta .m3u recém-criada
            $destinationPath = Join-Path -Path $folderPath -ChildPath $disc.Name
            Move-Item -Path $disc.FullName -Destination $destinationPath -Force

            # Escreve o nome do arquivo do disco dentro do documento .m3u
            Add-Content -Path $m3uFilePath -Value $disc.Name
        }

        Write-Host "Organizado: $baseName -> $($sortedDiscs.Count) disco(s) agrupado(s)." -ForegroundColor Green
    }
}

Write-Host "`nProcesso concluído com sucesso!" -ForegroundColor Cyan
Pause