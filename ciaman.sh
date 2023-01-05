#!/bin/bash

#Extract
function extract_cia(){

  CIA=$1
  BASE_PATH=extract/
  PART_PATH=$BASE_PATH/_tmp/partitions
  BINS_PATH=$BASE_PATH/_tmp/binaries

  echo $CIA

  mkdir -p extract/_tmp/{partitions,binaries}

  # Extract to partition
  ctrtool --contents=$PART_PATH/_ $CIA

  # Extract to bin
  3dstool -xtf cxi $PART_PATH/_.0000* --header $BINS_PATH/HeaderNCCH0.bin --exh $BINS_PATH/ExHeader.bin --exefs $BINS_PATH/ExeFS.bin --romfs $BINS_PATH/RomFS.bin --logo $BINS_PATH/LogoLZ.bin --plain $BINS_PATH/PlainRGN.bin
  3dstool -xvtf cfa $PART_PATH/_.0001* --header $BINS_PATH/HeaderNCCH1.bin --romfs $BINS_PATH/Manual.bin --romfs-auto-key

  # Extract to file
  3dstool -xvtfu exefs $BINS_PATH/ExeFS.bin --header $BINS_PATH/HeaderExeFS.bin --exefs-dir $BASE_PATH/ExeFS
  3dstool -xvtf romfs $BINS_PATH/RomFS.bin --romfs-dir $BASE_PATH/RomFS
  3dstool -xvtf romfs $BINS_PATH/Manual.bin --romfs-dir $BASE_PATH/Manual

  # Extract Download-Play
  if [ -e $PART_PATH/_.0002* ] ; then
    3dstool -xvtf cfa $PART_PATH/_.0002* --header $BINS_PATH/HeaderNCCH2.bin --romfs $BINS_PATH/DownloadPlay.bin --romfs-auto-key
    3dstool -xvtf romfs $BINS_PATH/DownloadPlay.bin --romfs-dir $BASE_PATH/DownloadPlay
  fi

  # Extract 3DS firmware update
  if [ -e $PART_PATH/_.0006* ] ; then
    3dstool -xvtf cfa $PART_PATH/_.0006* --header $BINS_PATH/HeaderNCCH6.bin --romfs $BINS_PATH/N3DSUpdate.bin --romfs-auto-key
    3dstool -xvtf romfs $BINS_PATH/N3DSUpdate.bin --romfs-dir $BASE_PATH/N3DSUpdate
  fi

  if [ -e $PART_PATH/_.0007* ] ; then
    3dstool -xvtf cfa $PART_PATH/_.0007* --header $BINS_PATH/HeaderNCCH7.bin --romfs $BINS_PATH/O3DSUpdate.bin --romfs-auto-key
    3dstool -xvtf romfs $BINS_PATH/O3DSUpdate.bin --romfs-dir $BASE_PATH/O3DSUpdate
  fi

}

# Repack
function repack_to_cia(){

  CIANAME="Repacked.cia"
  BASE_PATH=$2
  PACK_PATH=$BASE_PATH/_tmp/repack
  BINS_PATH=$BASE_PATH/_tmp/binaries
  CIABUILDFLG=""

  mkdir -p $PACK_PATH

  # pack to bin
  3dstool -cvtf romfs $PACK_PATH/RomFS.bin --romfs-dir $BASE_PATH/RomFS
  3dstool -cvtf romfs $PACK_PATH/Manual.bin --romfs-dir $BASE_PATH/Manual
  [ -e $BASE_PATH/DownloadPlay ] && 3dstool -cvft romfs $PACK_PATH/DownloadPlay.bin --romfs-dir $BASE_PATH/DownloadPlay

  # pack to partition
  3dstool -cvtf cxi $PACK_PATH/Partition0.bin --header $BINS_PATH/HeaderNCCH0.bin --exh $BINS_PATH/ExHeader.bin --exh-auto-key --exefs $BINS_PATH/ExeFS.bin --exefs-auto-key --exefs-top-auto-key --romfs $PACK_PATH/RomFS.bin --romfs-auto-key --logo $BINS_PATH/LogoLZ.bin --plain $BINS_PATH/PlainRGN.bin && CIABUILDFLG+="-content ${PACK_PATH}/Partition0.bin:0:0x00 "
  3dstool -cvtf cfa $PACK_PATH/Partition1.bin --header $BINS_PATH/HeaderNCCH1.bin --romfs $BASE_PATH/Manual.bin --romfs-auto-key && CIABUILDFLG+="-content ${PACK_PATH}/Partition1.bin:1:0x01 "
  [ -e $PACK_PATH/DownloadPlay.bin ] && 3dstool -cvtf cfa $PACK_PATH/Partition2.bin --header $BINS_PATH/HeaderNCCH2.bin --romfs $PACK_PATH/DownloadPlay.bin --romfs-auto-key && CIABUILDFLG+="-content ${PACK_PATH}/Partition2.bin:2:0x02"

  # pack to cia
  makerom -target p -ignoresign -f cia $CIABUILDFLG -o $BASE_PATH/$CIANAME

}

[[ $1 == "x" ]] && extract_cia $2
[[ $1 == "p" ]] && repack_to_cia $2
