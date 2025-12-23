param($p1)
$env_list = Get-ChildItem Env:

# Builds a ruby hash compatible string
$hash_string = "{"

foreach ($item in $env_list)
{
  $hash_string  += "`"" + $item.Name + "`" => `"" + $item.value.replace('\','\\').replace('"','\"') + "`","
}
$hash_string += "}"

$hash_string | out-File -Encoding "UTF8" $p1
