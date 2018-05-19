<#

 .SYNOPSYS
 Script to clone Windows partition to another new disk

 .DESCRIPTION
 This script is about a windows partition copy to a new disk (ex SSD)

 .AUTHOR
 Pierre Contri

#>

# Check the DISM tool present
# Dism.exe

$responseMount = [Boolean]((Read-Host "Need to mount a Virtual Disk ?").ToLower() -eq 'y')

if($responseMount) {
  Write-Output "Mount a virtual disk partition"
  $virtualDiskPath = [String](Read-Host "Virtual Disk Path")
  if( -not (Test-Path $virtualDiskPath) ) {
    Write-Error "The path ${virtualDiskPath} is not available"
    Exit -1
  }
  $diskImageObj = Mount-DiskImage -ImagePath $virtualDiskPath
}

Write-Output ""
$imageDiskPath = Read-Host "Please, enter the image disk path"
$imageName = "Image2Clone"

function Capture-Partition {
  param($imageDiskPath, $imageName)
 
  Write-Output "`nPlease choose the partition to clone"
  $partitionToClone = ((Get-Partition) | Out-GridView -PassThru).DriveLetter + ":\"
  
  Write-Output "`nCapturing the partition to clone ..."
  Write-Host "As administrator in cmd: Dism /Capture-Image /ImageFile:${imageDiskPath} /CaptureDir:${partitionToClone} /Name:${imageName}"

  & Dism /Capture-Image /ImageFile:$imageDiskPath /CaptureDir:$partitionToClone /Name:$imageName

  Write-Output "`nCapture finished on ${imageDiskPath}`n`n"
}

function Create-PartitionNewDisk {
  param([int]$diskNumber = 100, [Boolean]$isUEFI)

  $nameLogFile = "log-create-partition-" + (Get-Date).ToString("yyyyMMdd") + ".txt"
  $nameProgPart = [String]::Empty
  if($isUEFI) {
    $nameProgPart = ".\create_winpartition_disk_uefi.txt"
  }
  else {
    $nameProgPart= ".\create_winpartition_disk_mbr.txt"
  }
  Write-Host "As administrator in cmd: diskpart /s $nameProgPart > create-partition.txt"
}

function Apply-ImageNewDisk {
  param([String]$driveDiskLetter, [String]$imagePath)
  $appDir = $driveDiskLetter + ":\"
  Write-Host "As administrator in cmd: dism /Apply-Image /ImageFile:${imagePath} /Index:1 /ApplyDir:${appDir}"
  & Dism /Apply-Image /ImageFile:${imagePath} /Index:1 /ApplyDir:${appDir}
}

$responseCapture = [Boolean]((Read-Host "Need to capture ?").ToLower() -eq 'y')
if($responseCapture) {
  Capture-Partition -imageDiskPath $imageDiskPath -imageName $imageName
}

$responsePartition = [Boolean]((Read-Host "Partition new disk ?").ToLower() -eq 'y')
if($responsePartition) {
  $isUefi = [Boolean]((Read-Host "Uefi ?").ToLower() -eq 'y')
  Create-PartitionNewDisk -diskNumber 2 -isUEFI $isUefi
}

$responseApply = [Boolean]((Read-Host "Apply image ?").ToLower() -eq 'y')
if($responseApply) {

  Write-Output "`nPlease choose the partition destination"
  $partitionDest = ((Get-Partition) | Out-GridView -PassThru).DriveLetter

  Apply-ImageNewDisk -imagePath $imageDiskPath -driveDiskLetter $partitionDest -imageName $imageName
}

if($responseMount) {
  Write-Output "UnMount the virtual disk partition"
  Dismount-DiskImage -ImagePath $virtualDiskPath
}

$responseBoot = [Boolean]((Read-Host "Create boot (nt60, force, mbr) on partition ?").ToLower() -eq 'y')
if($responseBoot) {
  Write-Output "`nPlease choose the partition to boot into"
  $partitionBootDest = ((Get-Partition) | Out-GridView -PassThru).DriveLetter + ":"

  & bootsect.exe /nt60 ${partitionBootDest} /force /mbr
}