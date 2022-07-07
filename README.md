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
- 
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
[175045713] - 07/07/2022 21:04:17 - Build Start
[175045713] - 07/07/2022 21:04:17 - Finding Answers
[175045713] - 07/07/2022 21:04:17 - Mixing TestServer with Windows Server 2022 Datacenter Evaluation
[175045713] - 07/07/2022 21:06:18 - Setting up TestServer
[175045713] - 07/07/2022 21:06:21 - Enabling Ansible Management on TestServer
[175045713] - 07/07/2022 21:06:30 - Converting Windows Server Evaluation to Full
[175045713] - 07/07/2022 21:06:55 - Setting AVMA Key on TestServer
[175045713] - 07/07/2022 21:07:03 - TestServer is now ready
[175045713] - 07/07/2022 21:07:03 - Credentials: Administrator\>C5kno'(*Q@MN|?j/4`VcUZF
[175045713] - 07/07/2022 21:07:03 - Build End
[175045713] - 07/07/2022 21:07:03 - Completed in 2 Minutes
```

---

### Further Notes

* [1] Tested on NUC7i7BNH with NVMe Storage
* Microsoft [Virtualization-Documentation](https://github.com/MicrosoftDocs/Virtualization-Documentation)