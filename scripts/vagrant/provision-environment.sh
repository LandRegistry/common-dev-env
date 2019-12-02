HOME='/home/vagrant'

# Customise the shell prompt you see when SSHing into the box.
# First, remove any existing setting of PS1 from bash profile (prevents duplicates)
sed -i -e 's/.*PS1.*//' ${HOME}/.bash_profile
# Now add our own customisation:
# \033[X;XXm sets a colour
# \w prints the current path
# \$ shows the appropriate cursor depending on what type of user is logged in.
BLUEISH="\[\033[1;34m\]"
PINKISH="\[\033[0;35m\]"
ORANGEISH="\[\033[1;31m\]"
PLAIN="\[\033[0m\]"
echo "export PS1='${BLUEISH}DEVENV ${PINKISH}\w ${ORANGEISH}\$ ${PLAIN}'" >> ${HOME}/.bash_profile

# Just for ease of use, let's autoswap to the shared workspace folder when the shell launches
# First, remove any existing setting of it from bash profile (prevents duplicates)
sed -i -e 's/.*switch to workspace//' ${HOME}/.bash_profile
echo 'cd /vagrant; # switch to workspace' >> ${HOME}/.bash_profile

sed -i -e 's/.*set git into path//' ${HOME}/.bash_profile
echo 'export PATH=/usr/local/git/bin:$PATH ; # set git into path' >> ${HOME}/.bash_profile

# Get the aliases working by reparsing the config and setting up Compose
sed -i -e 's/.*repair env//' ${HOME}/.bash_profile
echo 'source run.sh repair ; # repair env' >> ${HOME}/.bash_profile

yum -q -y clean metadata
yum -q -y clean expire-cache

# Update all packages (except kernel files - prevents guest additions breakage)
echo 'Updating all currently installed non-kernel packages'
yum -y --exclude=kernel\* update
