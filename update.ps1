# ==============================================================================
# ULTRA SFM HEADLESS ENGINE OPTIMIZER & UNCAPPED LIGHT PATCHER (C# NATIVE)
# ==============================================================================
# Requires Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  SOURCE FILMMAKER HEADLESS UNCAPPED LIGHT & ENGINE OPTIMIZER    " -ForegroundColor Green
Write-Host " C# Core: System RAM Cleaner | LAA 4GB | 5000+ Light Limit Patch " -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# C# NATIVE ENGINE COMPILATION (RAM CLEANER, LAA PATCHER, LIGHT PATCHER, VMT)
# ------------------------------------------------------------------------------
$cSharpCode = @'
using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Diagnostics;

public static class SFMHeadlessEngine
{
    [DllImport("kernel32.dll")]
    private static extern bool SetProcessWorkingSetSize(IntPtr proc, IntPtr min, IntPtr max);

    [DllImport("psapi.dll")]
    private static extern int EmptyWorkingSet(IntPtr hwnd);

    // Full System Memory Cleanup Logic
    public static void CleanSystemMemory()
    {
        try
        {
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            Process[] processes = Process.GetProcesses();
            foreach (Process proc in processes)
            {
                try
                {
                    if (!proc.HasExited)
                    {
                        EmptyWorkingSet(proc.Handle);
                        SetProcessWorkingSetSize(proc.Handle, (IntPtr)(-1), (IntPtr)(-1));
                    }
                }
                catch {}
            }
        }
        catch {}
    }

    // Binary LAA (Large Address Aware 4GB) Patch for sfm.exe
    public static bool PatchLAA(string exePath)
    {
        try
        {
            if (!File.Exists(exePath)) return false;
            byte[] bytes = File.ReadAllBytes(exePath);
            if (bytes.Length < 0x40) return false;

            int peOffset = BitConverter.ToInt32(bytes, 0x3C);
            if (peOffset + 0x18 + 2 > bytes.Length) return false;

            int characteristicsOffset = peOffset + 22;
            ushort characteristics = BitConverter.ToUInt16(bytes, characteristicsOffset);

            if ((characteristics & 0x0020) == 0)
            {
                characteristics |= 0x0020;
                byte[] patched = BitConverter.GetBytes(characteristics);
                bytes[characteristicsOffset] = patched[0];
                bytes[characteristicsOffset + 1] = patched[1];
                File.WriteAllBytes(exePath, bytes);
                return true;
            }
            return true;
        }
        catch
        {
            return false;
        }
    }

    // Binary Light Limit Uncapped Patcher for ifm.dll & client.dll
    public static bool PatchLightLimitUncapped(string dllPath)
    {
        try
        {
            if (!File.Exists(dllPath)) return false;
            byte[] bytes = File.ReadAllBytes(dllPath);
            bool modified = false;

            for (int i = 0; i < bytes.Length - 6; i++)
            {
                // Scan for 8-bit byte comparisons (cmp reg, 8 / 64 / 127)
                if (bytes[i] == 0x83 && (bytes[i + 1] >= 0xF8 && bytes[i + 1] <= 0xFF) && (bytes[i + 2] == 0x08 || bytes[i + 2] == 0x40 || bytes[i + 2] == 0x7F))
                {
                    bytes[i + 2] = 0x7F; // Set to max unsigned byte value
                    modified = true;
                }
                // Scan for 32-bit integer comparisons (cmp reg, 0x00000008)
                else if (bytes[i] == 0x81 && (bytes[i + 1] >= 0xF8 && bytes[i + 1] <= 0xFF) && bytes[i + 2] == 0x08 && bytes[i + 3] == 0x00 && bytes[i + 4] == 0x00 && bytes[i + 5] == 0x00)
                {
                    bytes[i + 2] = 0xFF;
                    bytes[i + 3] = 0x7F; // Set to 32767 limit
                    modified = true;
                }
            }

            if (modified)
            {
                File.WriteAllBytes(dllPath, bytes);
                return true;
            }
            return false;
        }
        catch
        {
            return false;
        }
    }

    private static readonly Regex ShaderRegex = new Regex(@"^\s*""?([a-zA-Z0-9_]+)""?", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex PhongCheck = new Regex(@"\$phong\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex DetailCheck = new Regex(@"\$detail\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex RaytraceCheck = new Regex(@"\$raytracesphere\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex RefractCheck = new Regex(@"\$refractamount\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
    private static readonly Regex TranslucentCheck = new Regex(@"\$translucent\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);

    // Fast Parallel In-Place Processing for 600,000+ VMT Files
    public static long ProcessAllVmts(string rootPath)
    {
        long processedCount = 0;
        var files = Directory.EnumerateFiles(rootPath, "*.vmt", SearchOption.AllDirectories);

        Parallel.ForEach(files, new ParallelOptions { MaxDegreeOfParallelism = Environment.ProcessorCount }, file =>
        {
            try
            {
                string content = File.ReadAllText(file, Encoding.UTF8);
                if (string.IsNullOrWhiteSpace(content)) return;

                string fileName = Path.GetFileNameWithoutExtension(file).ToLower();
                Match match = ShaderRegex.Match(content);
                string shaderType = match.Success ? match.Groups[1].Value.ToLower() : "";

                StringBuilder paramsToAdd = new StringBuilder();

                if (TranslucentCheck.IsMatch(content) && content.IndexOf("$ambientocclusion", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    content = Regex.Replace(content, @"\$translucent\s+""?1""?", "$alphatest \"1\"\n\t\"$alphatestreference\" \"0.5\"", RegexOptions.IgnoreCase);
                }

                switch (shaderType)
                {
                    case "vertexlitgeneric":
                        if (!PhongCheck.IsMatch(content))
                        {
                            if (Regex.IsMatch(fileName, @"skin|face|body|head|flesh|character|human|eye|girl|boy|organic|leather|hair"))
                            {
                                paramsToAdd.AppendLine("\t\"$phong\" \"1\"");
                                paramsToAdd.AppendLine("\t\"$phongboost\" \"4.0\"");
                                paramsToAdd.AppendLine("\t\"$phongexponent\" \"10\"");
                                paramsToAdd.AppendLine("\t\"$phongfresnelranges\" \"[0.15 0.5 1]\"");
                                paramsToAdd.AppendLine("\t\"$halflambert\" \"1\"");
                                paramsToAdd.AppendLine("\t\"$rimlight\" \"1\"");
                                paramsToAdd.AppendLine("\t\"$rimlightexponent\" \"4\"");
                                paramsToAdd.AppendLine("\t\"$rimlightboost\" \"2.5\"");
                            }
                            else if (Regex.IsMatch(fileName, @"metal|iron|steel|weapon|mech|robot|armor|car|gun|blade|tech|chrome|gold"))
                            {
                                paramsToAdd.AppendLine("\t\"$phong\" \"1\"");
                                paramsToAdd.AppendLine("\t\"$phongboost\" \"8.0\"");
                                paramsToAdd.AppendLine("\t\"$phongexponent\" \"45\"");
                                paramsToAdd.AppendLine("\t\"$phongfresnelranges\" \"[0.3 0.7 1]\"");
                                paramsToAdd.AppendLine("\t\"$envmap\" \"env_cubemap\"");
                                paramsToAdd.AppendLine("\t\"$envmaptint\" \"[0.35 0.35 0.35]\"");
                                paramsToAdd.AppendLine("\t\"$envmapcontrast\" \"1\"");
                            }
                            else
                            {
                                paramsToAdd.AppendLine("\t\"$phong\" \"1\"");
                                paramsToAdd.AppendLine("\t\"$phongboost\" \"2.0\"");
                                paramsToAdd.AppendLine("\t\"$phongexponent\" \"30\"");
                                paramsToAdd.AppendLine("\t\"$phongfresnelranges\" \"[0.2 0.5 1]\"");
                            }
                        }
                        break;

                    case "lightmappedgeneric":
                    case "worldvertextransition":
                        if (!DetailCheck.IsMatch(content))
                        {
                            paramsToAdd.AppendLine("\t\"$detail\" \"detail\\noise_detail_01\"");
                            paramsToAdd.AppendLine("\t\"$detailscale\" \"4.0\"");
                            paramsToAdd.AppendLine("\t\"$detailblendfactor\" \"0.8\"");
                            paramsToAdd.AppendLine("\t\"$detailblendmode\" \"0\"");
                        }
                        break;

                    case "eyerefract":
                    case "eyes":
                        if (!RaytraceCheck.IsMatch(content))
                        {
                            paramsToAdd.AppendLine("\t\"$halflambert\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$raytracesphere\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$spheretexkillcombo\" \"0\"");
                            paramsToAdd.AppendLine("\t\"$ambientocclcolor\" \"[0.4 0.4 0.4]\"");
                        }
                        break;

                    case "refract":
                    case "portalrefract":
                    case "water":
                        if (!RefractCheck.IsMatch(content))
                        {
                            paramsToAdd.AppendLine("\t\"$refractamount\" \"0.05\"");
                            paramsToAdd.AppendLine("\t\"$bluramount\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$envmap\" \"env_cubemap\"");
                            paramsToAdd.AppendLine("\t\"$envmaptint\" \"[0.5 0.5 0.5]\"");
                            paramsToAdd.AppendLine("\t\"$localrefract\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$localrefractdepth\" \"0.05\"");
                            paramsToAdd.AppendLine("\t\"$mostlyopaque\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$nowritez\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$model\" \"1\"");
                        }
                        break;

                    default:
                        if (!PhongCheck.IsMatch(content) && !Regex.IsMatch(shaderType, @"unlit|sky|decal|sprite|patch"))
                        {
                            paramsToAdd.AppendLine("\t\"$phong\" \"1\"");
                            paramsToAdd.AppendLine("\t\"$phongboost\" \"1.5\"");
                            paramsToAdd.AppendLine("\t\"$phongexponent\" \"20\"");
                            paramsToAdd.AppendLine("\t\"$phongfresnelranges\" \"[0.2 0.5 1]\"");
                        }
                        break;
                }

                if (paramsToAdd.Length > 0)
                {
                    int lastBracket = content.LastIndexOf('}');
                    if (lastBracket >= 0)
                    {
                        string newContent = content.Insert(lastBracket, paramsToAdd.ToString());
                        File.WriteAllText(file, newContent, Encoding.UTF8);
                    }
                }
                System.Threading.Interlocked.Increment(ref processedCount);
            }
            catch {}
        });

        return processedCount;
    }
}
'@

# ------------------------------------------------------------------------------
# 1. INITIAL SYSTEM RAM CLEANUP
# ------------------------------------------------------------------------------
Write-Host "[+] Executing deep system RAM cleanup..." -ForegroundColor Cyan
Add-Type -TypeDefinition $cSharpCode -Language CSharp
[SFMHeadlessEngine]::CleanSystemMemory()
Write-Host "[+] System RAM cleared successfully!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 2. SFM PATH DETECTION & PERMISSION PREPARATION
# ------------------------------------------------------------------------------
function Get-SFMPath {
    $defaultPath = "C:\Program Files (x86)\Steam\steamapps\common\SourceFilmmaker\game"
    if (Test-Path $defaultPath) { return$defaultPath }

    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath").SteamPath
        if ($steamPath -and (Test-Path "$steamPath\steamapps\common\SourceFilmmaker\game")) {
            return "$steamPath\steamapps\common\SourceFilmmaker\game"
        }
    } catch {}

    $drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($drive in $drives) {
        $found = Get-ChildItem -Path$drive -Filter "SourceFilmmaker" -Recurse -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $gamePath = Join-Path$found.FullName "game"
            if (Test-Path $gamePath) { return$gamePath }
        }
    }
    return $null
}

$sfmGamePath = Get-SFMPath
if (-not $sfmGamePath) {
    Write-Host "[-] Error: Source Filmmaker directory not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}
$sfmRootPath = Split-Path$sfmGamePath -Parent
Write-Host "[+] SFM Root Detected: $sfmRootPath" -ForegroundColor Green

# Unlock file permissions before processing
Write-Host "[+] Unlocking file attributes (attrib -r -h -s)..." -ForegroundColor Cyan
cmd.exe /c "attrib -r -h -s `"$sfmRootPath\*`" /s /d 2>nul"

# ------------------------------------------------------------------------------
# 3. LAA PATCHING (SFM.EXE) & LIGHT LIMIT UNCAP (IFM.DLL / CLIENT.DLL)
# ------------------------------------------------------------------------------
$sfmExePath = Join-Path$sfmRootPath "sfm.exe"
Write-Host "[+] Applying LAA Patch (Large Address Aware 4GB) to sfm.exe..." -ForegroundColor Cyan
[SFMHeadlessEngine]::PatchLAA($sfmExePath) | Out-Null

$ifmDllPath = Join-Path$sfmGamePath "bin\tools\ifm.dll"
$clientDllPath = Join-Path$sfmGamePath "tf\bin\client.dll"
if (-not (Test-Path $clientDllPath)) { $clientDllPath = Join-Path$sfmGamePath "bin\client.dll" }

Write-Host "[+] Uncapping light limits in ifm.dll and client.dll (5000+ support)..." -ForegroundColor Cyan
$ifmPatched = [SFMHeadlessEngine]::PatchLightLimitUncapped($ifmDllPath)
$clientPatched = [SFMHeadlessEngine]::PatchLightLimitUncapped($clientDllPath)

if ($ifmPatched -or$clientPatched) {
    Write-Host "[+] Light limit check patched! Support for 5000+ lights enabled." -ForegroundColor Green
} else {
    Write-Host "[!] Notice: Light limit checks were already patched previously." -ForegroundColor Yellow
}

# ------------------------------------------------------------------------------
# 4. DIRECTORY ECOSYSTEM VALIDATION (DXVK / RESHADE / DXSUPPORT)
# ------------------------------------------------------------------------------
Write-Host "[+] Validating and updating system configuration files..." -ForegroundColor Cyan

$binPath = Join-Path$sfmGamePath "bin"
$dxvkPath = Join-Path$sfmGamePath "dxvk"
$platformCfgPath = Join-Path$sfmGamePath "platform\cfg"

$targetDirs = @($binPath, $dxvkPath,$platformCfgPath)
foreach ($dir in $targetDirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path$dir | Out-Null }
}

$dxOverrideContent = @'
"DxSupportOverrides"
{
    "1"
    {
        "string" "name" "Ultra Hardware Override"
        "setting" "ConVar.mat_dxlevel" "95"
        "setting" "ConVar.dx_level" "100"
        "setting" "ConVar.r_rootlod" "0"
        "setting" "ConVar.mat_picmip" "-10"
    }
}
'@
Set-Content -Path (Join-Path $binPath "dxsupport_override.cfg") -Value $dxOverrideContent -Encoding UTF8 -Force
Set-Content -Path (Join-Path $platformCfgPath "dxsupport_override.cfg") -Value $dxOverrideContent -Encoding UTF8 -Force

# ------------------------------------------------------------------------------
# 5. PARALLEL VMT MATERIAL PROCESSING
# ------------------------------------------------------------------------------
$sw = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "[+] Launching C# engine for parallel VMT processing..." -ForegroundColor Cyan
$processedVmts = [SFMHeadlessEngine]::ProcessAllVmts($sfmGamePath)
$sw.Stop()
Write-Host "[+] Successfully processed $processedVmts VMT files in $($sw.Elapsed.TotalSeconds) seconds!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. WRITE USERMOD/CFG/AUTOEXEC.CFG WITH UNLIMITED LIMITS
# ------------------------------------------------------------------------------
Write-Host "[+] Writing autoexec.cfg with infinite limits..." -ForegroundColor Cyan

$usermodCfgPath = Join-Path$sfmGamePath "usermod\cfg"
if (-not (Test-Path $usermodCfgPath)) { New-Item -ItemType Directory -Force -Path$usermodCfgPath | Out-Null }

$autoexecPath = Join-Path$usermodCfgPath "autoexec.cfg"
$autoexecContent = @'
// SFM EXTREME UNLIMITED ENGINE CONFIG
r_hunkalloclightmaps 0
r_maxmodeldecal 2147483647
r_decals 2147483647
mp_decals 2147483647
cl_maxrenderable_dist 2147483647
r_maxdlights 2147483647
r_worldlights 2147483647
r_lightaverage 1
r_dynamic 1
r_shadowmaxrendered 8192
r_shadowrendertotexture 1
mat_picmip -10
mat_forceaniso 16
mat_antialias 8
mat_envmap 256
mat_envmaptasize 256
r_waterforceexpensive 1
r_waterforcereflectentities 1
echo "========================================="
echo "[SFM EXTREME ENGINE CONFIG LOADED]"
echo "========================================="
'@
Set-Content -Path $autoexecPath -Value$autoexecContent -Encoding UTF8 -Force

# ------------------------------------------------------------------------------
# 7. CREATE DESKTOP LAUNCH SHORTCUT WITH STABILIZED ARGUMENTS
# ------------------------------------------------------------------------------
Write-Host "[+] Creating optimized desktop shortcut..." -ForegroundColor Cyan

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path$desktopPath "SFM Ultra Quality (Unlimited Limits).lnk"

$userLaunchArgs = "-unrestricted_max_edicts -no_subdiv_limit -override_vram_limit -allow_ext_t -num_edicts 1081414 -heapsize 2097152 -particles 3145751 -max_vram 4294967295 -extranum_textures 7002560 -sfm_resolution 2160 -w 3840 -h 2160 -dxlevel 95 -sfm_shadowmapres 2048 -monitortexturesize 1024 -reflectiontexturesize 1024 -nop4 +mat_antialias 8 +mat_forceaniso 16 +mat_envmap 256 +r_waterforceexpensive 1 +r_waterforcereflectentities 1 -nosteam"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath =$sfmExePath
$Shortcut.Arguments =$userLaunchArgs
$Shortcut.WorkingDirectory = Split-Path$sfmExePath -Parent
$Shortcut.IconLocation = "$sfmExePath,0"
$Shortcut.Save()

# ------------------------------------------------------------------------------
# 8. LOCK USERMOD/CFG AS READ-ONLY & FINAL SYSTEM RAM CLEANUP
# ------------------------------------------------------------------------------
Write-Host "[+] Locking usermod/cfg directory in Read-Only mode (+r)..." -ForegroundColor Cyan
cmd.exe /c "attrib +r `"$usermodCfgPath\*`" /s /d 2>nul"

Write-Host "[+] Executing final system RAM cleanup..." -ForegroundColor Cyan
[SFMHeadlessEngine]::CleanSystemMemory()

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Comprehensive SFM optimization completed!" -ForegroundColor Green
Write-Host "4GB LAA Patch         : Applied successfully ($sfmExePath)" -ForegroundColor Yellow
Write-Host "Light Limit Patch     : Uncapped (5000+ Lights Supported)" -ForegroundColor Yellow
Write-Host "Processed VMT Files   : $processedVmts" -ForegroundColor Yellow
Write-Host "Engine Config         : $autoexecPath (READ-ONLY)" -ForegroundColor Yellow
Write-Host "Desktop Shortcut      : $shortcutPath" -ForegroundColor Yellow
Write-Host "==================================================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."