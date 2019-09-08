# Remove old items
if (Test-Path "public"){
	Remove-Item -Recurse "build/public"
}
if (Test-Path "public_mini"){
	Remove-Item -Recurse "build/public_mini"
}

# Re-compile site
hugo -s source/hugo -d ../../build/public

# Minify
minify -r -o build/public_mini build/public

# Copy over files that are different
$folder1 = "build/public" | Resolve-Path
$folder2 = "build/public_mini" | Resolve-Path

# Get all files under $folder1, filter out directories
$firstFolders = Get-ChildItem -Recurse $folder1 | Where-Object { -not $_.PsIsContainer }

foreach($file in $firstFolders) {
	$folder2File = $file.FullName.Replace($folder1, $folder2)
	
    #Check if the file, from $folder1, exists with the same path under $folder2
    if (-Not (Test-Path $folder2File)) {
		New-Item -ItemType File -Path $folder2File -Force | Out-Null
		Copy-Item $file.FullName $folder2File
    }
}
