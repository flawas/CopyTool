Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'

[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

<# 
.NAME
    CopyTool
#>

Function Get-Folder() {
    process{
        [void] [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowserDialog.RootFolder = 'MyComputer'
        [void] $FolderBrowserDialog.ShowDialog()
        return $FolderBrowserDialog.SelectedPath
    }
}


function logmsg () {

    param(
        [string] $logtext
    )

    # Timestamp
    $timestamp = Get-Date -Format 'HH:mm:ss'

    # Check if log is already in message field
    if ( $TextBoxLog.Text -eq '' ) {
        $TextBoxLog.Text = $timestamp + ">    " + $logtext
    }
    else {
        $log = $TextBoxLog.Text
        $log = "$log`r`n"
        $TextBoxLog.Text = $log + $timestamp + ">    " + $logtext

    }

    # In der Textbox wird immer der unterste Eintrag angezeigt
    $TextBoxLog.SelectionStart = $TextBoxLog.TextLength;
    $TextBoxLog.ScrollToCaret()

}

function Copy-Files() {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Source,
        [string] $Destination
    )
    
    process{
        $FolderName = $Source.Split("\")[-1]
        $DestinationFolderName = $Destination + $FolderName
        if(Test-Path -Path $DestinationFolderName) {
            logmsg -logtext "Ordner existiert bereits! Es wurde NICHTS kopiert."
            return $false
        } else {
            logmsg -logtext "Starte Kopiervorgang..."
            $scriptblock = {
                $BasePath = $args[0]
                $TargetPath = $args[1]
                Copy-Item -Path $BasePath -Destination $TargetPath -Recurse -force -Verbose
            }
            
            $arguments = @($Source,$Destination)
            Start-Job -scriptblock $scriptblock -ArgumentList $arguments -Name "CopyJob"
            logmsg -logtext "CopyJob wurde erstellt und startet"
        }
    }
}

function Get-JobExists() {
    param(
        [string]$jobName
    )
    process{
        if ((get-job -Name $jobName -ea silentlycontinue)){
            return $true
            }
            else{
                return $false
            }
    }
}

function Get-CopyStatus() {
    param(
        [string]$jobname
    )
    process{
        if(Get-JobExists -jobName $jobname){
            if((Get-Job -Name $jobname).State -eq "Completed") {
                logmsg -logtext "CopyJob wurde beendet"
                Remove-Job -Name "CopyJob"
                $DestinationFolderSelect.Enabled = $true
                $sourceFolderSelect.Enabled = $true
                $SourceFolderName = Get-FolderName -Source $SourceFolder.Text
                $TestFolder = $DestinationFolder.text + $SourceFolderName
                $TargetDirecotryFileCountDirectory = Get-FolderInfoDirectoryCount -folderPath $TestFolder
                $TargetDirectoryFileCountFile = Get-FolderInfoFilesCount -folderPath $TestFolder
                $TargetDirectoryFileCount.text = "Zielverzeichnis Dateien: $TargetDirectoryFileCountFile Ordner: $TargetDirecotryFileCountDirectory"
                $ResetTool.Enabled = $true
                $verify.enabled = $true
                $Compare.enabled = $true
                
            } else{
                $Status = (Get-Job -Name "CopyJob").State
                logmsg -logtext "CopyJob laeuft noch... Status: $Status"
            }
        } else {
            logmsg -logtext "CopyJob wurde noch nicht gestartet"
        }
    }
}

function Test-PathExists(){
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Source,
        [string] $Destination
    )
    process{
        $FolderName = $Source.Split("\")[-1]
        $DestinationFolderName = $Destination + $FolderName
        if(Test-Path -Path $DestinationFolderName) {
            # Do nothing
            return $true
        } else {
            return $false
        }
    }
}

function Get-FolderName() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Source
    )
    process{
        if(Test-Path -Path $Source) {
            # Do nothing
            return $Source.Split("\")[-1]
        } else {
            logmsg -logtext "Fehler im Pfad"
        }
    }
}

function Test-VariablePath() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    if(Test-Path -Path $Path) {
        return $true
    } else {
        return $false
    }
}

function Get-FolderInfoFilesCount() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$folderPath
    )
    process{
        if(Test-Path -path $folderPath) {
            return (Get-ChildItem -Path $folderPath -recurse -File -force | Measure-Object ).Count
        }
    }
}

function Get-FolderInfoFiles() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$folderPath
    )
    process{
        if(Test-Path -path $folderPath){
            return @((Get-ChildItem -Path $folderPath -Recurse -File).FullName | % { $_.Substring(2) })
        }
    }
}

function Test-DirectoryFiles() {
    param(
        [Parameter(Mandatory=$true)]
        [array]$referenceObject,
        [array]$differenceObject
    )
    process{
        return Compare-Object -ReferenceObject $referenceObject -DifferenceObject $differenceObject -PassThru
    }
}

function Get-FolderInfoDirectoryCount() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$folderPath
    )
    process{
        if(Test-Path -path $folderPath) {
            return (Get-ChildItem -Path $folderPath -recurse -Directory -force | Measure-Object ).Count
        }
    }
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$CopyTool                        = New-Object system.Windows.Forms.Form
$CopyTool.ClientSize             = New-Object System.Drawing.Point(500,500)
$CopyTool.text                   = "CopyTool"
$CopyTool.TopMost                = $false

$DestinationFolder               = New-Object system.Windows.Forms.TextBox
$DestinationFolder.multiline     = $false
$DestinationFolder.text          = "Zielverzeichnis"
$DestinationFolder.width         = 450
$DestinationFolder.height        = 30
$DestinationFolder.enabled       = $false
$DestinationFolder.location      = New-Object System.Drawing.Point(10,165)
$DestinationFolder.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$DestinationFolder.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("")

$SourceFolder                    = New-Object system.Windows.Forms.TextBox
$SourceFolder.multiline          = $false
$SourceFolder.text               = "Quellverzeichnis"
$SourceFolder.width              = 450
$SourceFolder.height             = 30
$SourceFolder.enabled            = $false
$SourceFolder.location           = New-Object System.Drawing.Point(10,75)
$SourceFolder.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$SourceFolder.ForeColor          = [System.Drawing.ColorTranslator]::FromHtml("")

$SourceFolderSelect              = New-Object system.Windows.Forms.Button
$SourceFolderSelect.text         = "Quellverzeichnis waehlen"
$SourceFolderSelect.width        = 450
$SourceFolderSelect.height       = 30
$SourceFolderSelect.enabled      = $true
$SourceFolderSelect.location     = New-Object System.Drawing.Point(10,30)
$SourceFolderSelect.Font         = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$DestinationFolderSelect         = New-Object system.Windows.Forms.Button
$DestinationFolderSelect.text    = "Zielverzeichnis waehlen"
$DestinationFolderSelect.width   = 450
$DestinationFolderSelect.height  = 30
$DestinationFolderSelect.location  = New-Object System.Drawing.Point(10,120)
$DestinationFolderSelect.Font    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$StartCopy                       = New-Object system.Windows.Forms.Button
$StartCopy.text                  = "Kopieren starten"
$StartCopy.width                 = 150
$StartCopy.height                = 30
$StartCopy.enabled               = $false
$StartCopy.location              = New-Object System.Drawing.Point(156,195)
$StartCopy.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ResetTool                       = New-Object system.Windows.Forms.Button
$ResetTool.text                  = "Reset"
$ResetTool.width                 = 100
$ResetTool.height                = 30
$ResetTool.enabled               = $true
$ResetTool.location              = New-Object System.Drawing.Point(363,460)
$ResetTool.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TextBoxLog                        = New-Object system.Windows.Forms.TextBox
$TextBoxLog.multiline              = $true
$TextBoxLog.width                  = 450
$TextBoxLog.height                 = 100
$TextBoxLog.location               = New-Object System.Drawing.Point(9,294)
$TextBoxLog.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$verify                          = New-Object system.Windows.Forms.Button
$verify.text                     = "Verifizieren"
$verify.width                    = 100
$verify.height                   = 30
$verify.enabled                  = $true
$verify.location                 = New-Object System.Drawing.Point(10,195)
$verify.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SourceDirectoryFileCount        = New-Object system.Windows.Forms.TextBox
$SourceDirectoryFileCount.multiline  = $false
$SourceDirectoryFileCount.text   = "Quellverzeichnis"
$SourceDirectoryFileCount.width  = 450
$SourceDirectoryFileCount.height  = 30
$SourceDirectoryFileCount.enabled  = $false
$SourceDirectoryFileCount.location  = New-Object System.Drawing.Point(10,405)
$SourceDirectoryFileCount.Font   = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$SourceDirectoryFileCount.ForeColor  = [System.Drawing.ColorTranslator]::FromHtml("")

$TargetDirectoryFileCount        = New-Object system.Windows.Forms.TextBox
$TargetDirectoryFileCount.multiline  = $false
$TargetDirectoryFileCount.text   = "Zielverzeichnis"
$TargetDirectoryFileCount.width  = 450
$TargetDirectoryFileCount.height  = 30
$TargetDirectoryFileCount.enabled  = $false
$TargetDirectoryFileCount.location  = New-Object System.Drawing.Point(10,430)
$TargetDirectoryFileCount.Font   = New-Object System.Drawing.Font('Microsoft Sans Serif',10,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$TargetDirectoryFileCount.ForeColor  = [System.Drawing.ColorTranslator]::FromHtml("")

$JobStatus                       = New-Object system.Windows.Forms.Button
$JobStatus.text                  = "JobStatus"
$JobStatus.width                 = 100
$JobStatus.height                = 30
$JobStatus.enabled               = $true
$JobStatus.location              = New-Object System.Drawing.Point(359,195)
$JobStatus.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$objForm = New-Object System.Windows.Forms.Form
$objForm.Text = "Test"
$objForm.Size = New-Object System.Drawing.Size(400,200)
$objForm.FormBorderStyle = 'Fixed3D'
$objForm.MaximizeBox = $false
$objForm.MinimizeBox = $false
$objForm.StartPosition = "CenterScreen"

$Compare                         = New-Object system.Windows.Forms.Button
$Compare.text                    = "Vergleichen"
$Compare.width                   = 100
$Compare.height                  = 30
$Compare.enabled                 = $true
$Compare.location                = New-Object System.Drawing.Point(10,238)
$Compare.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CopyTool.controls.AddRange(@($DestinationFolder,$SourceFolder,$SourceFolderSelect,$DestinationFolderSelect,$StartCopy,$ResetTool,$TextBoxLog,$verify,$SourceDirectoryFileCount,$TargetDirectoryFileCount,$JobStatus,$Compare))

#region Logic 
$SourceFolderSelect.Add_Click({  
    $sourceFolderURL = Get-Folder
    $SourceFolder.text = $sourceFolderURL
    if($sourceFolderURL -ne ""){
        $SourceDirecotryFileCountDirectory = Get-FolderInfoDirectoryCount -folderPath $SourceFolder.Text
        $SourceDirectoryFileCountFile = Get-FolderInfoFilesCount -folderPath $SourceFolder.Text
        $SourceDirectoryFileCount.text = "Quellverzeichnis Dateien: $SourceDirectoryFileCountFile Ordner: $SourceDirecotryFileCountDirectory"
    }
  })

$DestinationFolderSelect.Add_Click({ 
    $targetFolderURL = Get-Folder
    $DestinationFolder.text = $targetFolderURL
 })

$StartCopy.Add_Click({ 
    $ResetTool.Enabled = $false
    $StartCopy.Enabled = $false
    Copy-Files -Source $SourceFolder.Text -Destination $DestinationFolder.Text
 }) 

 $ResetTool.Add_Click({  
    $SourceFolder.Text = "Quellverzeichnis"
    $DestinationFolder.Text = "Zielverzeichnis"
    $StartCopy.Enabled = $false
    $DestinationFolderSelect.Enabled = $true
    $sourceFolderSelect.Enabled = $true
    $SourceDirectoryFileCount.text = "Quellverzeichnis"
    $TargetDirectoryFileCount.text = "Zielverzeichnis"
    $verify.enabled = $true
    $TextBoxLog.Text = ""
    $Compare.enabled = $false
 })


 $verify.Add_Click({ 

    if(Test-VariablePath -Path $SourceFolder.Text){
        if(Test-VariablePath -Path $DestinationFolder.Text){
            logmsg -logtext "Pfade korrekt."
            if(Test-PathExists -Source $SourceFolder.Text -Destination $DestinationFolder.Text) {
                logmsg -logtext "Ordner existiert bereits! Es wurde NICHTS kopiert."
                $StartCopy.Enabled = $false
            } else {
                logmsg -logtext "Tool freigegeben, Zielpfad wird erstellt"
                $Verify.Enabled = $false
                $StartCopy.Enabled = $true
                $DestinationFolderSelect.enabled = $false
                $SourceFolderSelect.enabled  = $false
            }   
        }
    }

  })

  $JobStatus.Add_Click({
    Get-CopyStatus -jobname "CopyJob"
  })

  $Compare.Add_Click({ 
    if(Test-VariablePath -Path $SourceFolder.Text){
        $SourceFolderName = Get-FolderName -Source $SourceFolder.Text
        $TestFolder = $DestinationFolder.text + $SourceFolderName
        if(Test-VariablePath -Path $TestFolder){
            $reference = Get-FolderInfoFiles -folderPath $SourceFolder.Text
            $difference = Get-FolderInfoFiles -folderPath $DestinationFolder.Text
            if($reference.Count -ne $difference.Count) {
                Test-DirectoryFiles -referenceObject $reference -differenceObject $difference | Out-GridView
            } else {
                logmsg -logtext "Anzahl der Files ist korrekt."
            }
        } else {
            logmsg -logtext "Verzeichnis wurde noch nicht kopiert."
        }
    } else {
        logmsg -logtext "Die Verzeichnisse sind nicht gesetzt."
    } 
   })

#endregion

[void]$CopyTool.ShowDialog()