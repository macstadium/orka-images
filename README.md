# Orka Images

Repository with Orka 3.2 OCI-compatible images. 

These images can be used with Orka Desktop (via the GUI), or with Orka via the [orka3 CLI](https://orkadocs.macstadium.com/docs/cli-reference)

## Using with Orka Desktop
To get started with [Orka Desktop](https://github.com/macstadium/orka-desktop), click the 'Create New VM', choose 'Pull from Image', and use the following OCI image name:

```sh
ghcr.io/macstadium/orka-images/sequoia:latest
```

## Using with Orka
To [get started with Orka](https://orkadocs.macstadium.com/docs/orka-cluster-32-introduction), run:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sequoia:latest
```

Alternatively, create a VM directly with `kubectl apply` or `kubectl create` using the following definition:

```yaml
apiVersion: orka.macstadium.com/v1
kind: VirtualMachineInstance
metadata:
  name: my-orka-vm
  namespace: orka-default
spec:
  image: ghcr.io/macstadium/orka-images/sequoia:latest
```

## SIP Disabled Sequoia

To deploy a Sequoia VM with SIP (system integrity protection) disabled, deploy with the following image label:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sequoia:latest-no-sip
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

