# Paprastas vietinis serveris peržiūrai: http://localhost:8099
$saknis = Split-Path -Parent $PSScriptRoot
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:8099/")
try { $l.Start() } catch { Write-Host "NEPAVYKO: $($_.Exception.Message)"; exit 1 }
Write-Host "Serveris veikia: http://localhost:8099  (Ctrl+C sustabdyti)"
$tipai = @{ ".html"="text/html; charset=utf-8"; ".css"="text/css; charset=utf-8";
            ".js"="application/javascript; charset=utf-8"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg";
            ".png"="image/png"; ".svg"="image/svg+xml"; ".ico"="image/x-icon" }
while ($l.IsListening) {
  try {
    $ctx = $l.GetContext()
    $kelias = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/')
    if ([string]::IsNullOrWhiteSpace($kelias)) { $kelias = "index.html" }
    $f = Join-Path $saknis ($kelias -replace '/', [string][char]92)
    if (Test-Path $f -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($f).ToLower()
      if ($tipai.ContainsKey($ext)) { $ctx.Response.ContentType = $tipai[$ext] }
      $b = [System.IO.File]::ReadAllBytes($f)
      $ctx.Response.ContentLength64 = $b.Length
      $ctx.Response.OutputStream.Write($b, 0, $b.Length)
    } else { $ctx.Response.StatusCode = 404 }
    $ctx.Response.Close()
  } catch { }
}
