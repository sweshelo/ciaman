function test-exe($test){
  try {
    . $test > $null
    return 1
  }catch{
    return -1
  }
}

function install($app){
  switch($app){
    "3dstool"{
      iwr "https://github.com/dnasdw/3dstool/releases/download/v1.2.6/3dstool.zip" -OutFile 3dstool.zip
      Expand-Archive ./3dstool.zip
    }
    "ctrtool"{
      iwr "https://github.com/3DSGuy/Project_CTR/releases/download/ctrtool-v1.1.1-r2/ctrtool-v1.1.1-win_x64.zip" -OutFile citratool.zip
      Expand-Archive ./citratool.zip
    }
  }
}

function extract-cia($path){
  if ( (test-exe("3dstool")) -eq -1 ){
    install("3dstool")
    $3DSTOOL = "./3dstool/3dstool.exe"
  }else{
    $3DSTOOL = "3dstool"
  }

  if ( (test-exe("ctrtool")) -eq -1 ){
    install("ctrtool")
    $CTRTOOL = "./citratool/ctrtool.exe"
  }else{
    $CTRTOOL = "ctrtool"
  }

  $CIA=$path
  $CIANAME=Split-Path -Leaf $CIA
  $BASE_PATH="extract_$CIANAME"
  $PART_PATH="$BASE_PATH/_tmp/partitions"
  $BINS_PATH="$BASE_PATH/_tmp/binaries"

  mkdir -p extract_$CIANAME/_tmp/partitions
  mkdir -p extract_$CIANAME/_tmp/binaries

  # Extract to Partition
  . $CTRTOOL --contents="$PART_PATH/_" $CIA

  # Extract each partitions
  ls $PART_PATH | %{
    $FILE = $_.Name
    switch($FILE){
      "_.0000.00000000"{
        . $3DSTOOL -xtf cxi $PART_PATH/_.0000.00000000 --header $BINS_PATH/HeaderNCCH0.bin --exh $BINS_PATH/ExHeader.bin --exefs $BINS_PATH/ExeFS.bin --romfs $BINS_PATH/RomFS.bin --logo $BINS_PATH/LogoLZ.bin --plain $BINS_PATH/PlainRGN.bin
      }
      "_.0001.00000001"{
        . $3DSTOOL -xvtf cfa $PART_PATH/_.0001.00000001 --header $BINS_PATH/HeaderNCCH1.bin --romfs $BINS_PATH/Manual.bin --romfs-auto-key
      }
      "_.0002.00000002"{
        . $3DSTOOL -xvtf cfa $PART_PATH/_.0002.00000002 --header $BINS_PATH/HeaderNCCH2.bin --romfs $BINS_PATH/DownloadPlay.bin --romfs-auto-key
      }
      "_.0006.00000006"{
        . $3DSTOOL -xvtf cfa $PART_PATH/_.0006.00000006 --header $BINS_PATH/HeaderNCCH6.bin --romfs $BINS_PATH/N3DSUpdate.bin --romfs-auto-key
      }
      "_.0007.00000007"{
        . $3DSTOOL -xvtf cfa $PART_PATH/_.0007.00000007 --header $BINS_PATH/HeaderNCCH7.bin --romfs $BINS_PATH/O3DSUpdate.bin --romfs-auto-key
      }
      default{
        . $3DSTOOL -xtf cfa $PART_PATH/$FILE --header $BINS_PATH/HeaderNCCH_$FILE.bin --exh $BINS_PATH/ExHeader_$FILE.bin --exefs $BINS_PATH/ExeFS_$FILE.bin --romfs $BINS_PATH/RomFS_$FILE.bin --logo $BINS_PATH/LogoLZ_$FILE.bin --plain $BINS_PATH/PlainRGN_$FILE.bin
      }
    }
  }

  ls $BINS_PATH | %{
    $FILE = $_.Name
    if( $FILE -like "*RomFS*" ){
      . $3DSTOOL -xvtf romfs $BINS_PATH/$FILE --romfs-dir $BASE_PATH/$FILE
    }
    if( $FILE -like "*ExeFS*" ){
      . $3DSTOOL -xvtfu exefs $BINS_PATH/$FILE --header $BINS_PATH/HeaderExeFS.bin --exefs-dir $BASE_PATH/$FILE
    }
    if( $FILE -like "*DownloadPlay*" -or $FILE -like "*3DSUpdate*"){
      . $3DSTOOL -xvtf romfs $BINS_PATH/$FILE --romfs-dir $BASE_PATH/$FILE
    }
  }
}

extract-cia $args[0]
