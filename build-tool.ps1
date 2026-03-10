
$toolsArg = $args | Where-Object { $_ -like "UTILS=*" }
if (!$toolsArg) { throw "UTILS build argument not found" }
$tool = $toolsArg.Split('=')[1].Split(' ')[0]
$dockerFile = $(Get-Content ./Dockerfile -Raw) + "ENTRYPOINT [`"/bin/$tool`"]`n"
$dockerFile | docker build @args -
