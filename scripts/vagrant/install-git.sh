echo "- - - Installing Git - - -"
GIT_VERSION="2.21.0"
yum install -y -q openssl-devel autoconf libcurl-devel expat-devel gcc gettext-devel kernel-headers openssl-devel perl-devel zlib-devel
curl -O -L https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz
tar -zxvf v${GIT_VERSION}.tar.gz
cd git-${GIT_VERSION}/
make clean
make configure
./configure --prefix=/usr/local/git
make
make install
cd ..
rm -rf git-${GIT_VERSION} v${GIT_VERSION}.tar.gz