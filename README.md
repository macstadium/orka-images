# Orka Images

## Repository with Orka 3.2 OCI-compatible images

These images can be used with Orka Desktop (via the GUI), or with Orka via the [orka3 CLI](https://orkadocs.macstadium.com/docs/cli-reference)

### Using with Orka Desktop

To get started with [Orka Desktop](https://github.com/macstadium/orka-desktop), click the 'Create New VM', choose 'Pull from Image', and use the following OCI image name:

```sh
ghcr.io/macstadium/orka-images/sonoma:latest
```

Currently, Orka Desktop doesn't support the new OCI image format, and Sequoia VM images may experience issues when deployed using Orka Desktop. Support for the new format will be available with the next release.

### Using with the Orka 3 CLI

To [get started with Orka](https://orkadocs.macstadium.com/docs/orka-cluster-32-introduction), run:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sonoma:latest
```

Alternatively, create a VM directly with `kubectl apply` or `kubectl create` using the following definition:

```yaml
apiVersion: orka.macstadium.com/v1
kind: VirtualMachineInstance
metadata:
  name: my-orka-vm
  namespace: orka-default
spec:
  image: ghcr.io/macstadium/orka-images/sonoma:latest
```

### VM setup from IPSW script

To get started with Orka using an IPSW and Orka Desktop, use the [setup.sh script](./setup/README.md).

### SIP Disabled Sonoma

To deploy a Sonoma VM with SIP (system integrity protection) disabled, deploy with the following image label:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sonoma:latest-no-sip
```

### SIP Diabled Ventura

To deploy a Ventura VM with SIP disabled, run:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/ventura:no-sip
```

### MacOS 26.0 Tahoe

> [!NOTE]
> macOS 26.0 is currently only supported for guest VMs running on Orka version 3.5.0 and above. 

macOS 26.1 includes [changes to the Virtualization framework](https://developer.apple.com/documentation/macos-release-notes/macos-26_1-release-notes#Virtualization) that impact certain functionality when running as a virtual machine. Users should be aware of this Apple-imposed limitation when planning their deployments. We strongly recommend reviewing the Apple release notes linked above to determine if this limitation affects your specific Orka workflows before deploying macOS 26.1 VMs in production environments.

Orka 3.5.0+ **does not** currently support macOS 26.2, and these images are provided for testing purposes only. 

To deploy a macOS Tahoe v26.0 VM with Orka Desktop:

1. Click + Create New VM button
1. Select 'Pull from OCI registry'
1. Name VM and set parameters (CPUs, Memory, HD size)
1. In the 'OCI Image Name' field enter: `ghcr.io/macstadium/orka-images/tahoe:latest`

```sh  
  ghcr.io/macstadium/orka-images/tahoe:latest
```

To deploy a SIP-disabled Tahoe VM with Orka Desktop:

1. Click + Create New VM button
1. Select 'Pull from OCI registry'
1. Name VM and set parameters (CPUs, Memory, HD size)
1. In the 'OCI Image Name' field enter: `ghcr.io/macstadium/orka-images/tahoe:no-sip`

```sh  
  ghcr.io/macstadium/orka-images/tahoe:no-sip
```
