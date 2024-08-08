Param(
    [switch]$E
)

cd \dev

if ($E -or $Explorer) {
    explorer .
}
