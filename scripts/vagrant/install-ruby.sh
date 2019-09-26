echo "- - - Installing Ruby - - -"
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L get.rvm.io | bash -s stable
source /home/vagrant/.rvm/scripts/rvm
rvm install 2.6.4 --default
