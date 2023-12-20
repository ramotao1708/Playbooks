# xwiki Installation guide 
## this instruction assumes that podman is already installed on the system 
## create a system user to for the application, the user is usually named after the application installed
``` 
useradd -d /opt/xwiki -rm xwiki 
usermod --add-subuids 600000-665535 --add-subgid 600000-665535 xwiki 
```
## set selinux permission 
```
sudo semanage fcontext -a -t user_home_dir_t "/opt/xwiki(/.+)?" 
sudo restorecon -Frv /opt/xwiki 
```
## Enable linger to allow app to run in the background 
```
loginctl neable-linger xwiki  

