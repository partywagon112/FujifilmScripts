# Script for automatically shifting files from the Fujifilm X-T3, starting a raw conversion through
# Iridient, and then starting the Lightroom import process.
# 
# Definitely not the most advanced script in the world, but definitely easier than pressing lots of
# buttons, and a lot more consistent. Ensure that adequate space is available on the hard-drive prior
# to starting.
# 
# Much of this has been sourced from the MTP powershell commands available here:
# https://github.com/nosalan/powershell-mtp-file-transfer/blob/master/phone_backup.ps1
# 
# PROCESS
#   1. Move the files on the camera into a mounted directory. MTP is too difficult to work with.
#   2. Parse the files to find photos, move them to a second directory with no folder structure.
#   3. Boot up Iridient, and start the conversion process. Wait for close.
#   4. Remove all the old RAF files.
#   5. Boot up Lightroom, start the folder import process.
# 
# Remember to delete this folder every so often. 

# PARAMETERS

# Address to push all files from the camera.
$DestDirForMediaDump = "C:\fuji_raw-conversion\pulled_from_mtp"
# Subdirectory to store the RAF files while they are waiting to be converted.
$DestDirForPhotoConversion = "C:\fuji_raw-conversion\raf_conversion"
$cameraName = "X-T3"    #Name of camera
$cameraSubDirectory = "External Memory\Slot 1"

# FUNCTIONS

# MTP function used to return an object to represent the cameras main directory.
# throws if not available.
function Get-CameraMainDir($cameraName)
{
  $o = New-Object -com Shell.Application
  $rootComputerDirectory = $o.NameSpace(0x11)
  $cameraDirectory = $rootComputerDirectory.Items() | Where-Object {$_.Name -eq $cameraName} | select -First 1
    
  if($cameraDirectory -eq $null)
  {
    throw "Not found '$cameraName' folder in This computer. Connect camera."
  }
  
  return $cameraDirectory;
}

# Returns object for a given MTP subdirectory.
function Get-SubFolder($parentDir, $subPath)
{
  $result = $parentDir
  foreach($pathSegment in ($subPath -split "\\"))
  {
    $result = $result.GetFolder.Items() | Where-Object {$_.Name -eq $pathSegment} | select -First 1
    if($result -eq $null)
    {
      throw "Not found $subPath folder"
    }
  }
  return $result;
}

# Returns the full MTP directory with a single function.
function Get-FullPathOfMtpDir($mtpDir)
{
 $fullDirPath = ""
 $directory = $mtpDir.GetFolder
 while($directory -ne $null)
 {
   $fullDirPath =  -join($directory.Title, '\', $fullDirPath)
   $directory = $directory.ParentFolder;
 }
 return $fullDirPath
}

# Copies from the camera to the specified destination address.
# Definitely much more complex than it should be.
function Copy-FromCamera-ToDestDir($sourceMtpDir, $destDirPath)
{
#  Create-Dir $destDirPath
    mkdir $destDirPath -Force

    $destDirShell = (new-object -com Shell.Application).NameSpace($destDirPath)
    $fullSourceDirPath = Get-FullPathOfMtpDir $sourceMtpDir
 
    Write-Host "Copying from: '" $fullSourceDirPath "' to '" $destDirPath "'"
 
    $copiedCount = 0;
 
    foreach ($item in $sourceMtpDir.GetFolder.Items())
    {
        $itemName = ($item.Name)
        $fullFilePath = Join-Path -Path $destDirPath -ChildPath $itemName
   
        if(Test-Path $fullFilePath)
        {
            Write-Host "Element '$itemName' already exists"
        }
        else
        {
            $copiedCount++;
            Write-Host ("Copying #{0}: {1}{2}" -f $copiedCount, $fullSourceDirPath, $item.Name)
            $destDirShell.CopyHere($item)
        }
    }
    Write-Host "Copied '$copiedCount' elements from '$fullSourceDirPath'"
}


# SCRIPT


# Remove the old directory
Remove-Item -Recurse "C:\fuji_raw-conversion"

# Set the root directory of MTP device.
$cameraRootDir = Get-CameraMainDir $cameraName

# Find the relevant folder of the camera. Only include Slot 1 since the camera should be left 
# in a mode where it saves a JPEG backup.
$cameraCardPhotosSourceDir = Get-SubFolder $cameraRootDir $cameraSubDirectory
Copy-FromCamera-ToDestDir $cameraCardPhotosSourceDir $DestDirForMediaDump


Write-Host "Moving out all RAF files."

# Create a new directory for the conversion files.
mkdir $DestDirForPhotoConversion -Force

# Hunt out all *.RAF files and move them into the second folder.
Get-ChildItem $DestDirForMediaDump -recurse -Filter "*.raf" | %{
    Move-Item -Path $_.FullName -Destination $DestDirForPhotoConversion -Force
}

Write-Host "Starting Iridient, close on completion to start Lightroom"

# Start Iridient X-Transformer and start batch processing sequence. Settings must be set PRIOR
# to this part of the process.
&'C:\Program Files\Iridient Digital\Iridient X-Transformer\Iridient X-Transformer.exe'  $DestDirForPhotoConversion | Out-Null

# Upon Iridient finishing up, remove everything in that folder that is a raf file.
Get-ChildItem -Path $DestDirForPhotoConversion *.raf | foreach { Remove-Item -Path $_.FullName }





# Modify the path to include the value. NOT NECCESSARY!
# $lrPath = $DestDirForPhotoConversion + '\IridientExports'
# &'C:\Program Files\Adobe\Adobe Lightroom CC\lightroom.exe' $lrPath | Out-Null
&'C:\Program Files\Adobe\Adobe Lightroom CC\lightroom.exe' $DestDirForPhotoConversion



echo Finished!