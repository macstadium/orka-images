# Orka Images

Repository with Orka 3.0 OCI-compatible images. 

These images can be used with Orka Desktop (via the GUI), or Orka Cluster (via the orka3 CLI)

## Using with Orka Desktop
To get started with Orka Desktop, click the 'Create New VM', choose 'Pull from Image', and use the following OCI image name:

```sh
ghcr.io/macstadium/orka-images/sonoma:latest
```

## Using with Orka Cluster
To get started with Orka Cluster, run:

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

## Sequoia Beta (Orka Desktop only)

To deploy a Sequoia Beta VM with Orka Desktop:
1. Click + Create New VM button
1. Select Pull from OCI registry
1. Name VM and set parameters (CPUs, Memory, HD size)
1. In OCI Image Name field enter: `ghcr.io/macstadium/orka-images/sequoia:latest`
```sh  
  ghcr.io/macstadium/orka-images/sequoia:latest
```

## SIP Disabled Sonoma

To deploy a Sonoma VM with SIP (system integrity protection) disabled, deploy with the following image label:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sonoma:latest-no-sip
```

## SIP Diabled Ventura

To deploy a Ventura VM with SIP disabled, run:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/ventura:no-sip
```

