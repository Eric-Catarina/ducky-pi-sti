# Função para formatar bytes em GB
function ConvertTo-GB {
    param (
        [Parameter(Mandatory=$true)]
        [double]$Bytes
    )
    return [math]::round($Bytes / 1GB, 2)
}

# Nome da Máquina
$machineName = Get-ComputerInfo -Property CsName | Select-Object -ExpandProperty CsName

# Tamanho do HD
$diskSize = Get-PhysicalDisk | Select-Object DeviceId, Size | ForEach-Object {
    [PSCustomObject]@{
        DeviceId = $_.DeviceId
        SizeGB = ConvertTo-GB -Bytes $_.Size
    }
}

# Quantidade de RAM
$ramSize = ConvertTo-GB -Bytes (Get-ComputerInfo -Property CsTotalPhysicalMemory | Select-Object -ExpandProperty CsTotalPhysicalMemory)

# CPU
$cpuInfo = Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors

# GPU
$gpuInfo = Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM | ForEach-Object {
    [PSCustomObject]@{
        Name = $_.Name
        RAMGB = ConvertTo-GB -Bytes $_.AdapterRAM
    }
}

# Endereço MAC do Ethernet
$ethernetMAC = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -ne $null -and $_.Description -like "*Ethernet*" } | Select-Object -ExpandProperty MACAddress

# Construindo a saída
$output = @()
$output += "Nome da Maquina: $machineName"
$output += "Tamanho do HD:"
$diskSize | ForEach-Object { $output += "  Device ID: $($_.DeviceId), Size: $($_.SizeGB) GB" }
$output += "Quantidade de RAM: $ramSize GB"
$output += "CPU:"
$cpuInfo | ForEach-Object { $output += "  Name: $($_.Name), Cores: $($_.NumberOfCores), Logical Processors: $($_.NumberOfLogicalProcessors)" }
$output += "GPU:"
$gpuInfo | ForEach-Object { $output += "  Name: $($_.Name), RAM: $($_.RAMGB) GB" }
$output += "Endereco MAC do Ethernet: $ethernetMAC"

# Salvando a saída em um arquivo
$output | Out-File -FilePath "F:\dados_do_pc.txt" -Encoding utf8

# Exibindo a saída no console
$output | ForEach-Object { Write-Output $_ }

# Tratamento de erros e log
$logPath = "F:\erro_log.txt"

# Função para parar e desativar serviços com privilégios administrativos
function Stop-And-Disable-Service {
    param (
        [string]$ServiceName
    )
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Stop-Service -Name $ServiceName -ErrorAction Stop; Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop`"" -Verb RunAs -NoNewWindow -Wait
    } catch {
        $_ | Out-File -FilePath $logPath -Append
    }
}

# Parar e desativar serviços
Stop-And-Disable-Service -ServiceName "SysMain"
Stop-And-Disable-Service -ServiceName "WSearch"
Stop-And-Disable-Service -ServiceName "wuauserv"


$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path -Path $desktopPath -ChildPath "Comum.lnk"
$targetPath = "\\10.122.99.246\Comum"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.Save()


# Pausar a execução no final para evitar fechamento imediato do PowerShell
Write-Host "Pressione qualquer tecla para sair..."
[void][System.Console]::ReadKey($true)
