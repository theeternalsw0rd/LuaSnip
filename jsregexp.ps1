param([string] $command = "install")

if($command -eq "install") {
  Write-Host "Loading MSVC environment..."
  if (!(Get-Command -Name loadMSVC -ErrorAction SilentlyContinue)) {
    function LoadMSVC {
      # load x64 by default but allow specifying an architecture
      [CmdletBinding()]
      Param([string] $arch = "x64")
      if ($arch -notin @("x64", "x86", "arm64")) {
        Write-Host "Invalid architecture: $arch. Supported architectures are x64, x86, arm64."
        return
      }
      $vcvarsall = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
      if (Test-Path $vcvarsall) {
        Invoke-CmdScript "$vcvarsall" $arch
        Write-Host "Visual Studio Community environment variables loaded for $arch."
      }
      else {
        Write-Host "Visual Studio Community not found."
      }
    }
  }
  if (Test-Path -Path "C:\luajit\lua51.lib") {
    Write-Host "Lua library located."
    return
  }
  else {
    Write-Host "Neovim does not include the library necessary to build the lua plugin with MSVC."
    Write-Host "Lua library not found. Please install LuaJIT to continue."
    Write-Host "You should build LuaJIT with MSVC, following the instructions at https://luajit.org/install.html" 
    Write-Host "Copy .lib .dll and .exe files from src to C:\luajit"
    Write-Host "Copy .h files to C:\luajit\include"
    Write-Host "You can download LuaJIT from https://luajit.org/download.html"
    return
  }
  if (!(Get-Command -Name nmake -ErrorAction SilentlyContinue)) {
    Write-Host "NMake not found. Please install Visual Studio Community with C++ components to continue."
    Write-Host "You can download Visual Studio Community from https://visualstudio.microsoft.com/vs/community/"
    return
  }
  if (!(Get-Command -Name cmake -ErrorAction SilentlyContinue)) {
    Write-Host "CMake not found. Please install CMake to continue."
    Write-Host "You can download CMake from https://cmake.org/download/"
    return
  }
  if (!(Get-Command -Name git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Please install Git to continue."
    Write-Host "You can download Git from https://git-scm.com/downloads"
    return
  }
  loadMSVC

  $projectRoot = Get-Location
  $jsRegexpRoot = Join-Path $projectRoot "deps\jsregexp"

  git submodule update --init --recursive

  Set-Location $jsRegexpRoot
  if (Test-Path -Path "build") {
    Remove-Item -Recurse -Force "build"
  }
  New-Item -ItemType Directory -Path "build"
  Set-Location "build"
  if (!$(cmake .. -G NMake Makefiles)) {
    Write-Host "CMake configuration failed. Please check the output for errors."
    return
  }
  if (!$(nmake)) {
    Write-Host "NMake build failed. Please check the output for errors."
    return
  }
  Write-Host "JS RegExp plugin built successfully."

  if(Test-Path -Path "$projectRoot\lua\luasnip-jsregexp.dll") {
    Remove-Item -Force "$projectRoot\lua\luasnip-jsregexp.dll"
  }
  Copy-Item -Path "jsregexp.dll" -Destination "$projectRoot\lua\luasnip-jsregexp.dll" -Force
  Write-Host "JS RegExp plugin copied to lua directory."

  Copy-Item -Path "$jsRegexRoot\jsregexp.lua" -Destination "$projectRoot\lua\luasnip-jsregexp.lua" -Force
  Write-Host "JS RegExp Lua module copied to lua directory."
  return
}
elseif($command -eq "uninstall") {
  Write-Host "Uninstalling JS RegExp plugin..."
  $projectRoot = Get-Location
  $jsRegexpRoot = Join-Path $projectRoot "deps\jsregexp"

  if (Test-Path -Path "$projectRoot\lua\luasnip-jsregexp.dll") {
    Remove-Item -Force "$projectRoot\lua\luasnip-jsregexp.dll"
    Write-Host "JS RegExp plugin DLL removed."
  }
  if (Test-Path -Path "$projectRoot\lua\luasnip-jsregexp.lua") {
    Remove-Item -Force "$projectRoot\lua\luasnip-jsregexp.lua"
    Write-Host "JS RegExp Lua module removed."
  }
  if (Test-Path -Path $jsRegexpRoot) {
    Remove-Item -Recurse -Force $jsRegexpRoot
    Write-Host "JS RegExp directory removed."
  }
  return
}
elseif($command -eq "test") {
  Get-Location
}
else {
  Write-Host "Invalid command. Use 'install' or 'uninstall'."
}