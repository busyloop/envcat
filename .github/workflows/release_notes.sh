#!/bin/bash

set -e

VERSION=$(git describe --tags | cut -c 2-)

cat <<EOF
# Installation

## OSX

\`\`\`bash
wget https://github.com/busyloop/envcat/releases/download/v${VERSION}/envcat-${VERSION}.darwin-x86_64
sudo chmod +x envcat-${VERSION}.darwin-x86_64
sudo mv envcat-${VERSION}.darwin-x86_64 /usr/bin
sudo ln -sf /usr/bin/envcat-${VERSION}.darwin-x86_64 /usr/bin/envcat
\`\`\`

## Linux

\`\`\`bash
wget https://github.com/busyloop/envcat/releases/download/v${VERSION}/envcat-${VERSION}.linux-x86_64
sudo chmod +x envcat-${VERSION}.linux-x86_64
sudo mv envcat-${VERSION}.linux-x86_64 /usr/bin
sudo ln -sf /usr/bin/envcat-${VERSION}.linux-x86_64 /usr/bin/envcat
\`\`\`


## Dockerfile :whale:

EOF

for ARCH in linux-x86_64 linux-aarch64; do
CHECKSUM=$(grep -hrE "build/envcat-${VERSION}.${ARCH}$" sha256-*/checksums.txt | cut -d ' ' -f 1)

if [ -z "$CHECKSUM" ]; then
  ls -R
  cat sha256-*/checksums.txt
  echo "*** CHECKSUM ERROR OR BUILD VERSION MISMATCH ***"
  exit 1
fi

cat <<EOF
#### ${ARCH}

\`\`\`Dockerfile
# Install envcat (${ARCH})
ARG envcat_version=${VERSION}
ARG envcat_sha256=${CHECKSUM}
ADD --checksum=sha256:\${envcat_sha256} https://github.com/busyloop/envcat/releases/download/v\${envcat_version}/envcat-\${envcat_version}.${ARCH} /envcat
RUN chmod +x /envcat
\`\`\`

EOF
done
