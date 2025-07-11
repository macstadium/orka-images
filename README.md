# Orka Images

## Repository with Orka 3.2 OCI-compatible images.

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

### Tahoe Beta 3 (25A5306g)

> [!NOTE]
> MacOS 26 is currently in beta. This image is available for OS testing purposes only, using Orka Desktop 3.0, and is not currently officially supported by MacStadium.

To deploy a Tahoe Beta VM with Orka Desktop:

1. Click + Create New VM button
1. Select 'Pull from OCI registry'
1. Name VM and set parameters (CPUs, Memory, HD size)
1. In the 'OCI Image Name' field enter: `ghcr.io/macstadium/orka-images/tahoe:latest`
```sh  
 ghcr.io/macstadium/orka-images/tahoe:latest
```

### SIP Disabled Tahoe Beta 3 (25A5306g)

> [!NOTE]
> MacOS 26 is currently in beta. This image is available for OS testing purposes only, using Orka Desktop 3.0, and is not currently officially supported by MacStadium.

To deploy a Tahoe beta VM with SIP (system integrity protection) disabled, deploy with the following image label:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:latest-no-sip
```
