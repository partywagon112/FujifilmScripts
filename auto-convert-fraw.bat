echo off

echo
echo
echo ---------------------------------------------------------------
echo Autoconvert RAF to DNG via Iridient X-Transformer
echo ---------------------------------------------------------------
echo
echo

echo Clearing old files from C:\fraw_temp
RMDIR /s /q "C:\fraw_temp"

if exist "D:\DCIM" (

    mkdir "C:\fraw_temp"

    pushd "D:\DCIM"
        for /r %%a in (*.RAF) do (
            COPY "%%a" "C:\fraw_temp\%%~nxa"
        )
    popd

    echo Starting Iridient, close when finished
    "C:\Program Files\Iridient Digital\Iridient X-Transformer\Iridient X-Transformer.exe" "C:\fraw_temp"

    echo Starting Lightroom, upon close, temp directory will be removed
    "C:\Program Files\Adobe\Adobe Lightroom CC\lightroom.exe" "C:\fraw_temp\IridientExports"

    echo Cleanup
    RMDIR "C:\fraw_temp"

    echo Finshed
) else (

    echo
    echo No DCIM directory found.
    echo
    pause
)
