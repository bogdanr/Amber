**Amber**Apps are tiny VMs that have the sole purpose to run a single application. They are **VMs lighter than Docker containers**.

Amber VMs are only one file which is esentially a lightweight kernel which executes the app inside it.

Since it's not possible to login inside the VM, or edit it's contents in anyway after it's booted, AmberApps are **by default secure**.

**Amber VMs boot in less than a second and they normally use less disk space than the app they run** ⛅

Currently we have the following AmberApps:

+ AmberRedis	- 3.7MB
+ AmberMemcached	- ? MB

# F.A.Q.

1. How is it possible to have a VM smaller than the app it runs?

  Compression! The kernel is stripped to the bare minimum functions, the apps are stripped of useless symbols, and after the kernel embedds the app, it's compressed with xz, which provides one of the best compression.

2. How it is possible to boot in less than a second and already be connected to the network?

  We tell the kernel the IP address that it will have even before it boots and it will just start with that IP address configured. There is no userspace overhead for configuring the network. The kernel module doesn't need to load and there aren't tools that call the Kernel API in any way.
