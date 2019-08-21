# Install support for overlayfs (the default in docker 1.13+)
# and yum config manager for installing docker
yum -y -q install yum-plugin-ovl yum-utils

# Install docker
echo "- - - Installing Docker - - -"
# Add the new yum repo for docker-ce
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum makecache fast
yum -y -q install docker-ce bash-completion wget
# Ensure it starts on startup
service docker start
chkconfig docker on
usermod -a -G docker vagrant

echo "- - - Installing Docker Compose - - -"
#Install Docker compose
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
rm get-pip.py
pip install docker-compose

# Bash autocompletion of container names
wget -q https://raw.githubusercontent.com/docker/compose/1.24.1/contrib/completion/bash/docker-compose
mv -f docker-compose /etc/bash_completion.d/docker-compose

echo "- - - Removing any orphaned docker images - - -"
images=$(docker images -f "dangling=true" -q)
if [ -n "$images" ]; then
  docker rmi $images
fi

# Fix weird DNS issues in windows that otherwise require container to container calls to include network prefix
sudo sed -i -e 's/.*search box.*//' /etc/resolv.conf
sudo service docker restart
