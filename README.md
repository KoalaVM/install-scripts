![KoalaVM](http://dpr.clayfreeman.com/1kRYJ+ "KoalaVM")

Install Scripts
===============

This repository serves as a version controlled environment for install script
development and collaboration.  These scripts should be referenced directly by
any and all software developed under the KoalaVM organization.

`install-node.sh`
=================

This script installs the requirements for `koalad` and clones `koalad` to
`/usr/local/koalad` with submodules initialized.  Apart from `koalad`, the only
other thing that needs to be configured is a bridge interface on the hypervisor.
[This link](https://help.ubuntu.com/community/KVM/Networking#Bridged_Networking)
is a good tutorial to follow when setting up a bridge.

If a hypervisor is not installed, you will be prompted to install one after
running `install-node.sh`.

Licensing
=========

This work is licensed under the Creative Commons Attribution-ShareAlike 4.0
International License. To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/ or send a letter to Creative
Commons, PO Box 1866, Mountain View, CA 94042, USA.
