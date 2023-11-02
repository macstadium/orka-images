# Orka Images

Repository with Orka 3.0 OCI-compatible images.

To get started, run:

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
