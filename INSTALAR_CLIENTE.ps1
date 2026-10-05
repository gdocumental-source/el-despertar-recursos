# Instalador del cliente de «El Despertar» (Windows). Un solo paso: instala Fabric 1.21.11 y los mods (voz de proximidad y minimapa).
# No redistribuye nada: descarga los mods desde Modrinth y los instalador desde Fabric, y comprueba su huella (SHA-512).
# El paquete de texturas (Biblia, mapa, armas, alas...) NO hay que instalarlo: el servidor lo envía solo al entrar.
param([string]$Minecraft = (Join-Path $env:APPDATA ".minecraft"), [switch]$SinPerfil)
$ErrorActionPreference = "Stop"

$Loader = "0.19.5"
$Version = "1.21.11"
$Instalador = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.1.2/fabric-installer-1.1.2.jar"
$Mods = @(
    @{ Nombre = "Fabric API";               Archivo = "fabric-api-0.141.6+1.21.11.jar";            Url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/6qAuTtLR/fabric-api-0.141.6%2B1.21.11.jar";                        Sha512 = "852d3682c4f353fd0ca86546af8578513e8bcf628377fa9d49c556bc59c5024c69ab56c92fc6dfba11fed19e4316a3f5636e7e07fd3d96f7043b531aef59b637" },
    @{ Nombre = "Voz de proximidad";        Archivo = "voicechat-fabric-1.21.11-2.6.24.jar";       Url = "https://cdn.modrinth.com/data/9eGKb6K1/versions/MLNG868g/voicechat-fabric-1.21.11-2.6.24.jar";                       Sha512 = "ffe87edb4655a287175dbd4286281a4b83e30e47649c40940059e43f75d234ee9539a4e665468f39556761f9959096fa28da57682bca613b7875492404a18467" },
    @{ Nombre = "Minimapa (Xaero)";         Archivo = "xaerominimap-fabric-1.21.11-26.6.0.jar";    Url = "https://cdn.modrinth.com/data/1bokaNcj/versions/e0EvhWco/xaerominimap-fabric-1.21.11-26.6.0.jar";                    Sha512 = "ec106f298e7bb568bf27841eec1863f3226a8b1407f93a3d8e0ead68adc192e18f3cc604060cb3580cc1dfdc3b44fef255f2b401e955a64ae87e68729c7e9077" }
)

function Paso($n, $texto) { Write-Host "[$n/4] $texto" -ForegroundColor Cyan }

function Buscar-Java {
    $enRuta = Get-Command java -ErrorAction SilentlyContinue
    if ($enRuta) { return $enRuta.Source }
    $sitios = @(
        (Join-Path $env:APPDATA ".minecraft\runtime"),
        (Join-Path $env:LOCALAPPDATA "Packages"),
        "C:\Program Files\Eclipse Adoptium", "C:\Program Files\Java", "C:\Program Files\Microsoft"
    )
    foreach ($s in $sitios) {
        if (Test-Path $s) {
            $j = Get-ChildItem -Path $s -Recurse -Filter java.exe -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($j) { return $j.FullName }
        }
    }
    throw "No encuentro Java. Abre el Launcher de Minecraft una vez (descarga su propio Java) y vuelve a ejecutar este instalador."
}

function Bajar($url, $destino, $sha512) {
    Invoke-WebRequest -Uri $url -OutFile $destino -UseBasicParsing
    if ($sha512) {
        $h = (Get-FileHash -Algorithm SHA512 -Path $destino).Hash.ToLower()
        if ($h -ne $sha512.ToLower()) { Remove-Item $destino -Force; throw "La descarga de $(Split-Path $destino -Leaf) no coincide con su huella. Inténtalo de nuevo." }
    }
}

if (-not (Test-Path $Minecraft)) { throw "No encuentro la carpeta de Minecraft: $Minecraft. Abre el Launcher una vez y vuelve a intentarlo." }
Write-Host "Instalando el cliente de El Despertar en $Minecraft" -ForegroundColor Green

Paso 1 "Buscando Java"
$java = Buscar-Java
Write-Host "      $java"

Paso 2 "Instalando Fabric $Loader para Minecraft $Version"
$tmp = Join-Path $env:TEMP "el-despertar-instalador"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$jar = Join-Path $tmp "fabric-installer.jar"
Bajar $Instalador $jar $null
$args = @("-jar", $jar, "client", "-dir", $Minecraft, "-mcversion", $Version, "-loader", $Loader)
if ($SinPerfil) { $args += "-noprofile" }
& $java @args
if ($LASTEXITCODE -ne 0) { throw "Falló la instalación de Fabric (código $LASTEXITCODE)." }

Paso 3 "Instalando los mods"
$carpetaMods = Join-Path $Minecraft "mods"
New-Item -ItemType Directory -Force -Path $carpetaMods | Out-Null
foreach ($m in $Mods) {
    $destino = Join-Path $carpetaMods $m.Archivo
    if (Test-Path $destino) {
        Write-Host "      $($m.Nombre): ya está"
    } else {
        Write-Host "      $($m.Nombre): descargando..."
        Bajar $m.Url $destino $m.Sha512
    }
}

Paso 4 "Listo"
Write-Host ""
Write-Host "Todo instalado. Abre el Launcher de Minecraft, elige el perfil 'fabric-loader-$Version' y entra al servidor." -ForegroundColor Green
Write-Host "Al entrar, el servidor te enviará su paquete de texturas: acéptalo (es obligatorio) y ya está." -ForegroundColor Green
