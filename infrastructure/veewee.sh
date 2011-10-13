# edit definitions/vv16/*
vagrant basebox build vv16
vagrant basebox validate vv16
vagrant basebox export vv16
vagrant box add vv16 vv16.box
# edit Vagrantfile to base on vv16
vagrant up
# for some reason chef-solo doesn't run the first time
vagrant reload 
