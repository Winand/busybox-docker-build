
$appletsArg = $args | Where-Object { $_ -like "APPLETS=*" }
if (!$appletsArg) { throw "APPLETS build argument not found" }
$applet = $appletsArg.Split('=')[1].Split(' ')[0]
$dockerFile = (Get-Content ./Dockerfile -Raw) -replace "(?m)^ENTRYPOINT\s+.*$", "ENTRYPOINT [`"/bin/$applet`"]`n"
$dockerFile | docker build @args -
