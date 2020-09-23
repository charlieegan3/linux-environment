# linux-environment

Project to configure a Linux environment based on Fedora for development and general use.

```bash
mkdir -p /home/charlieegan3/Code; cd /home/charlieegan3/Code

git config --global credential.helper store
git clone https://github.com/charlieegan3/linux-environment.git

cd linux-environment

sudo dnf install ansible make
sudo make playbook
```
