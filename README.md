## Overview

Deploy new Windows Server 2022 virtual machines on demand while you drink a beer. A follow up to [HVA-WindowsServer2019](https://github.com/casbitton/HVA-WindowsServer2019).

This is a highly opinionated base install specific to my Intel NUC [lab](#Further-Notes). You might find it useful.

Cheers! 🍻

---

### Prerequisites:
- A host Server running - Windows Server 2022 Datacenter Edition with [Hyper-V Role](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-the-hyper-v-role-on-windows-server)
- Adequate storage and memory for builds
- 3 Virtual Switches configured via [Hyper-V Manager](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines). Each Virtual Switch will be named:
  - External Switch
  - Internal Switch
  - Private Switch
- Windows Server 2022 ISO from [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)

#### Optional Cloud Enhancement ☁️🚀
- This can be paired with [GitLab](https://about.gitlab.com/) or [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/) to yield some fantastic results
- Install a runner from your favorite CI/CD platform of choice, and the deployment process can be performed entirely from any browser 👌

---

### Supported Operating Systems:
- Windows Server 2022 Datacenter Evaluation - ServerDatacenterCor
- Windows Server 2022 Datacenter Evaluation (Desktop Experience) - ServerDatacenter

### Each new build includes:
- Fresh built from source ISO each run
- Automatic Virtual Machine Activation
- Pre-Configured for use with
  - [Ansible](https://github.com/ansible/ansible)
- Lightning fast deploy on modern hardware
  - Desktop Experience , ~10 Minutes
  - Core , ~5 Minutes

---

### Getting Started

`Create-NewVM.ps1` has minimal options, this may be expanded upon in the future. 

- Name
- CPU
- Memory
- Storage
- SwitchName
- WindowsISO
- WindowsEdition
- AdminPassword (Optional)

**Security Note:** _The administrator password will be generated for you if not selected. This will be output to you in plaintext upon build completion in either scenario._

### Example Build

```
.\Create-NewVM.ps1 -Name TestServer -CPU 4 -Memory 8GB -Storage 60GB -SwitchName 'External Switch' -WindowsISO C:\Temp\SERVER_EVAL_x64FRE_en-us.iso -WindowsEdition 'Windows Server 2022 Datacenter Evaluation'
```

_A few moments later_

```
[921043386] - 07/07/2022 22:02:24 - Build Start
[921043386] - 07/07/2022 22:02:24 - Brewing Server01 with Windows Server 2022 Datacenter Evaluation
[921043386] - 07/07/2022 22:04:21 - Setting up Server01
[921043386] - 07/07/2022 22:04:24 - Enabling Ansible Management on Server01
[921043386] - 07/07/2022 22:04:33 - Converting Windows Server Evaluation to Full
[921043386] - 07/07/2022 22:04:58 - Setting AVMA Key on Server01
[921043386] - 07/07/2022 22:05:07 - Credentials: Administrator\C^_4aH$qr%J[S0`}\jNO.ox"
[921043386] - 07/07/2022 22:05:07 - Server01 is now ready
```

---

### Further Notes

* [1] Tested on NUC7i7BNH with NVMe Storage
* Microsoft [Virtualization-Documentation](https://docs.microsoft.com/en-us/virtualization/)