<#
部署前檢查：Windows/NTFS 不分大小寫，但 GitHub Pages 等靜態託管跑在 Linux 上會嚴格區分大小寫。
本機測試正常、上線後素材默默 404（fallback 回程式繪製）通常就是這裡出的問題。
用法：在專案根目錄執行 `powershell -File check-art-naming.ps1`
#>

$base = Join-Path $PSScriptRoot "Art_Sources"

$expected = @(
  "symbols/A_slime_yellow/idle","symbols/B_slime_green/idle","symbols/C_slime_red/idle","symbols/D_skeleton_axe/idle",
  "symbols/E_skeleton_bow/idle","symbols/SW_small_wild/idle","symbols/BW_big_wild/idle","symbols/CAT_charm/idle",
  "boss/idle","boss/hit","boss/roar","boss/fg_mode",
  "mage/idle","mage/cast","mage/cast_strong",
  "background/ng","background/fg",
  "hit_numbers/plus","hit_numbers/0","hit_numbers/1","hit_numbers/2","hit_numbers/3","hit_numbers/4",
  "hit_numbers/5","hit_numbers/6","hit_numbers/7","hit_numbers/8","hit_numbers/9"
)

$problems = @()

foreach ($rel in $expected) {
  $parts = $rel -split '/'
  $cur = $base
  foreach ($part in $parts) {
    if (-not (Test-Path $cur)) { $problems += "找不到上層資料夾: $cur"; $cur = $null; break }
    $siblings = Get-ChildItem $cur -Directory
    $exactMatch = $siblings | Where-Object { [string]::Equals($_.Name, $part, [System.StringComparison]::Ordinal) }
    if (-not $exactMatch) {
      $looseMatch = $siblings | Where-Object { $_.Name -ieq $part }
      if ($looseMatch) {
        $problems += "大小寫不符: 預期 '$part'，實際是 '$($looseMatch.Name)' (在 $cur 底下)"
      } else {
        $problems += "資料夾不存在: $cur\$part（尚未放素材，這是正常的，可忽略）"
      }
      $cur = $null; break
    }
    $cur = Join-Path $cur $part
  }
  if ($cur) {
    $pngs = Get-ChildItem $cur -File -Filter "*.png" -ErrorAction SilentlyContinue
    $badExt = Get-ChildItem $cur -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -cne ".png" -and $_.Name -ne "" }
    foreach ($b in $badExt) { $problems += "非 .png 或副檔名大小寫錯誤，程式讀不到: $($b.FullName)" }
    foreach ($p in $pngs) {
      if ($p.BaseName -notmatch '^\d+$') { $problems += "檔名應為連號數字 (0.png,1.png...): $($p.FullName)" }
    }
  }
}

$realProblems = $problems | Where-Object { $_ -notmatch '尚未放素材' }
if ($realProblems.Count -eq 0) {
  Write-Host "沒有發現大小寫或命名問題，可以部署。" -ForegroundColor Green
} else {
  Write-Host "發現以下問題，部署前請修正：" -ForegroundColor Yellow
  $realProblems | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
