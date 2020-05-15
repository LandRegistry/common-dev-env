echo "- - - Installing Docker - - -"
# Install support for installing docker
yum -y -q install yum-utils device-mapper-persistent-data lvm2
yum -q -y install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.13-3.2.el7.x86_64.rpm

# Install docker itself
# Add the new yum repo for docker-ce
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y -q install docker-ce bash-completion wget
# Ensure it starts on startup
systemctl enable --now docker
usermod -a -G docker vagrant

echo "- - - Installing Docker Compose - - -"
#Install Docker compose
yum install -y -q python36
pip3 -q install docker-compose

# Bash autocompletion of container names
wget -q https://raw.githubusercontent.com/docker/compose/1.25.5/contrib/completion/bash/docker-compose
mv -f docker-compose /etc/bash_completion.d/docker-compose

echo "- - - Removing any orphaned docker images - - -"
images=$(docker images -f "dangling=true" -q)
if [ -n "$images" ]; then
  docker rmi $images
fi

# Fix weird DNS issues in windows that otherwise require container to container calls to include network prefix
sudo sed -i -e 's/.*search box.*//' /etc/resolv.conf
sudo service docker restart
