#!/usr/bin/env bash
set -ev

date

# R 4.1.1
if [ ! -f R-4.1.1-arm64.pkg ]; then
  curl -L -O https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-4.1.1-arm64.pkg
  sudo installer -pkg R-4.1.1-arm64.pkg -target /
  R --version
fi

# SRMIO
if [ -z "$(ls -A srmio)" ]; then
  git clone https://github.com/rclasen/srmio.git
  pushd srmio
  sh genautomake.sh
  ./configure --disable-shared --enable-static --prefix=/opt/homebrew
  make -j2 --silent
  popd
fi
pushd srmio
make install
popd

# D2XX - refresh cache if shared lib not found
# libftd2xx.a specifically gets cleaned by `git clean -fdX`
if [[ ! -f D2XX/libftd2xx.a ]]; then
  d2xx_ver=1.4.24
  d2xx_zip=D2XX"${d2xx_ver}".zip
  d2xx_dmg=D2XX"${d2xx_ver}".dmg

  rm -rf D2XX "${d2xx_zip}" "${d2xx_dmg}"
  mkdir -p D2XX

  curl -O https://ftdichip.com/wp-content/uploads/2021/05/"${d2xx_zip}"
  unzip "${d2xx_zip}"
  mpoint=$(
    hdiutil mount "${d2xx_dmg}" -plist |
      xmllint -xpath '//key[text()="mount-point"]/following-sibling::string[1]/text()' -
  )
  cp \
    /Volumes/dmg/release/build/libftd2xx."${d2xx_ver}".dylib \
    /Volumes/dmg/release/build/libftd2xx.a \
    /Volumes/dmg/release/*.h \
    D2XX
  hdiutil eject "${mpoint}"
fi
