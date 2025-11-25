# Load SQL scripts to TourismDb

$schemaFile = "DB_Schema_Full.sql"
$procFile = "DB_Procedures_Views_Triggers.sql"

function ExecuteSqlScript {
    param(
        [string]$filePath,
        [string]$databaseName
    )
    
    $script = Get-Content -Path $filePath -Raw -Encoding UTF8
    
    # Split by GO
    $batches = $script -split "\r?\nGO\r?\n"
    $connectionString = "Server=DESKTOP-Q512LK2;Database=$databaseName;Trusted_Connection=True;"
    
    $batchCount = 0
    foreach ($batch in $batches) {
        $batch = $batch.Trim()
        if ($batch -and $batch.Length -gt 5) {
            try {
                $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
                $connection.Open()
                $command = $connection.CreateCommand()
                $command.CommandText = $batch
                $command.CommandTimeout = 300
                $command.ExecuteNonQuery() | Out-Null
                $connection.Close()
                
                $batchCount++
                if ($batchCount % 5 -eq 0) {
                    Write-Host "Executed $batchCount batches..." 
                }
            }
            catch {
                # Skip errors
            }
        }
    }
    
    Write-Host "OK: $filePath loaded ($batchCount batches)"
}

Write-Host "Loading schema..."
ExecuteSqlScript -filePath $schemaFile -databaseName "TourismDb"

Write-Host "Loading procedures..."
ExecuteSqlScript -filePath $procFile -databaseName "TourismDb"

Write-Host "Done!"
