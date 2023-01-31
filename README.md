# Kinoite for the MSI Stealth 15m

> **Warning**
> This image is still undergoing big changes, and is not guarenteed to be stable. Do not use on a production machine _yet_.

This is a build of kinoite specifically designed to support the MSI Stealth 15m.

Based off of the ublue project (https://github.com/ublue-os/).

After rebasing, set the kargs

```
rpm-ostree kargs \
    --append=rd.driver.blacklist=nouveau \
    --append=modprobe.blacklist=nouveau \
    --append=nvidia-drm.modeset=1 \
    --append=nvidia.NVreg_DynamicPowerManagement=0x02 \
    --append=nvidia.NVreg_PreserveVideoMemoryAllocations=0 \
    --append=nvidia.NVreg_DynamicPowerManagementVideoMemoryThreshold=200
```
