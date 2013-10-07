﻿function New-ZipCompression{

    [CmdletBinding()]
    param(
        [parameter(
            mandatory,
            position = 0,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $source,

        [parameter(
            mandatory = 0,
            position = 1,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $destination,

        [parameter(
            mandatory = 0,
            position = 2)]
        [switch]
        $quiet,

        [parameter(
            mandatory = 0,
            position = 3)]
        [switch]
        $force
    )

    try
    {
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
    catch
    {
    }

    # check file is directory
    $file = Get-Item -Path $source

    # set zip extension
    $zipExtension = ".zip"

    # set desktop as destination path if it null
    if ([string]::IsNullOrWhiteSpace($destination))
    {
        if ($file.Mode -like "d*")
        {
            $destination = (Join-Path ([System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)) (([System.IO.Path]::GetFileNameWithoutExtension($source)) + $zipExtension))
        }
        else
        {
            $destination = (Join-Path ([System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)) (([System.IO.Path]::GetFileNameWithoutExtension(($file | select -First 1 -ExpandProperty fullname))) + $zipExtension))
        }
        
    }

    # check destination is input as .zip
    if (-not($destination.EndsWith($zipExtension)))
    {
        throw ("destination parameter value [{0}] not end with extension {1}" -f $destination, $zipExtension)
    }

    # check destination is already exist or not
    if (Test-Path $destination)
    {
        Remove-Item -Path $destination -Confirm
    }


    # compressionLevel
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal

    # check file mode for source
    Write-Verbose ("file.mode = {0}" -f $file.Mode)

    if ($file.Mode -like "d*") # Directory should be d---
    {
        try # create zip from directory
        {
            # force output zip file to new destination path, avoiding destination zip name conflict.
            if ($force)
            {
                # check destination is already exist, CreateFromDirectory will fail with same name of destination file.
                if (Test-Path $destination)
                {
                    # show warning for same destination exist.
                    Write-Verbose ("Detected destination name {0} is already exist. Force trying output to new destination zip name." -f $destination)

                    # get current destination information
                    $destinationRoot = [System.IO.Path]::GetDirectoryName($destination)
                    $destinationfile = [System.IO.Path]::GetFileNameWithoutExtension($destination)
                    $destinationExtension = [System.IO.Path]::GetExtension($destination)

                    # renew destination name with (2)...(x) until no more same name catch.
                    $count = 2
                    $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")" + $destinationExtension)
                    while (Test-Path $destination)
                    {
                        ++$count
                        $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")" + $destinationExtension)
                    }

                    # show warning as destination name had been changed due to escape error.
                    Write-Verbose ("Deistination name change to new name {0}" -f $destination)
                }
            }

            # include BaseDirectory
            $includeBaseDirectory = $true

            Write-Verbose ("destination = {0}" -f $destination)

            Write-Verbose ("file.fullname = {0}" -f $file.FullName)
            Write-Verbose ("compressionLevel = {0}" -f $compressionLevel)
            Write-Verbose ("includeBaseDirectory = {0}" -f $includeBaseDirectory)

            if ($quiet)
            {
                Write-Verbose ("zipping up folder {0} to {1}" -f $file.FullName,$destination)
                [System.IO.Compression.ZipFile]::CreateFromDirectory($file.fullname,$destination,$compressionLevel,$includeBaseDirectory) > $null
                $?
            }
            else
            {
                Write-Verbose ("zipping up folder {0} to {1}" -f $file.FullName,$destination)
                [System.IO.Compression.ZipFile]::CreateFromDirectory($file.fullname,$destination,$compressionLevel,$includeBaseDirectory)
                Get-Item $destination
            }
        }
        catch
        {
            Write-Error $_
            $?
        }
    }
    else
    {
        try # create zip from files
        {
            # create zip to add
            $destzip = [System.IO.Compression.Zipfile]::Open($destination,"Update")

            # get items
            $files = Get-ChildItem -Path $source

            foreach ($file in $files)
            {
                $file2 = $file.name

                Write-Verbose ("destzip = {0}" -f $destzip)
                Write-Verbose ("file.fullname = {0}" -f $file.FullName)
                Write-Verbose ("file2 = {0}" -f $file2)
                Write-Verbose ("compressionLevel = {0}" -f $compressionLevel)

                if ($quiet)
                {
                    Write-Verbose ("zipping up files {0} to {1}" -f $file.FullName,$destzip)
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($destzip,$file.fullname,$file2,$compressionLevel) > $null
                    $?
                }
                else
                {
                    Write-Verbose ("zipping up files {0} to {1}" -f $file.FullName,$destzip)
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($destzip,$file.fullname,$file2,$compressionLevel)
                }
            }
        }
        catch
        {
            Write-Error $_
            $?
        }
        finally
        {
            # dispose opened zip
            $destzip.Dispose()
        }
    }
}




function New-ZipExtract{

    [CmdletBinding()]
    param(
        [parameter(
            mandatory,
            position = 0,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $source,

        [parameter(
            mandatory = 0,
            position = 1,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $destination,

        [parameter(
            mandatory = 0,
            position = 2)]
        [switch]
        $quiet,

        [parameter(
            mandatory = 0,
            position = 3)]
        [switch]
        $force
    )

    try
    {
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
    catch
    {
    }

    $zipExtension = ".zip"

    # check source is input as .zip
    if (-not($source.EndsWith($zipExtension)))
    {
        throw ("source parameter value [{0}] not end with extension {1}" -f $source, $zipExtension)
    }

    # set desktop as destination path if it null
    if ([string]::IsNullOrWhiteSpace($destination))
    {
        $destination = (Join-Path ([System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)) (([System.IO.Path]::GetFileNameWithoutExtension($source))))
    }

    # check destination is already exist or not
    if (Test-Path $destination)
    {
        Remove-Item -Path $destination -Recurse -Confirm
    }
        
    try
    {
        # force output zip file to new destination path, avoiding destination zip name conflict.
        if ($force)
        {
            # check destination is already exist, CreateFromDirectory will fail with same name of destination file.
            if (Test-Path $destination)
            {
                # show warning for same destination exist.
                Write-Verbose ("Detected destination name {0} is already exist. Force trying output to new destination zip name." -f $destination)

                # get current destination information
                $destinationRoot = [System.IO.Path]::GetDirectoryName($destination)
                $destinationfile = [System.IO.Path]::GetFileName($destination)

                # renew destination name with (2)...(x) until no more same name catch.
                $count = 2
                $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")")
                while (Test-Path $destination)
                {
                    ++$count
                    $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")")
                }

                # show warning as destination name had been changed due to escape error.
                Write-Verbose ("Deistination name change to new name {0}" -f $destination)
            }
        }

        # create source zip and complression
        $sourcezip = [System.IO.Compression.Zipfile]::Open($source,"Update")
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal

        Write-Verbose ("sourcezip = {0}" -f $sourcezip)
        Write-Verbose ("destination = {0}" -f $destination)

        if ($quiet)
        {
            [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($sourcezip,$destination) > $null
            $?
        }
        else
        {
            [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($sourcezip,$destination)
        }

        $sourcezip.Dispose()
    }
    catch
    {
        Write-Error $_
    }
    finally
    {
        $sourcezip.Dispose()
    }
}



Export-ModuleMember `
    -Function * `
    -Cmdlet * `
    -Variable *


# Compres Sample
# New-ZipCompression -source D:\test -destination d:\hoge.zip
# New-ZipCompression -source D:\test -destination d:\hoge.zip -quiet

# Extract Sample
# New-ZipExtract -source d:\hoge.zip -destination d:\hogehoge
# New-ZipExtract -source d:\hoge.zip -destination d:\hogehoge -quiet