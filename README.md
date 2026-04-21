# Orka Images

OCI-compatible macOS VM images for use with [Orka](https://docs.macstadium.com) and [Orka Desktop](https://github.com/macstadium/orka-desktop).

### Using with the Orka CLI

To [get started with Orka](https://docs.macstadium.com), run:

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

### Using with Orka Desktop

In Orka Desktop, click **Create New VM**, select **Pull from Image**, and enter an OCI image name:

```
ghcr.io/macstadium/orka-images/sequoia:latest
```

### VM setup from IPSW script

To set up a VM from an IPSW file using Orka Desktop, see the [setup.sh script](./setup/README.md).

---

## macOS Tahoe (26.x)

Orka supports macOS Tahoe as a guest OS. The current latest image is `tahoe:latest` (26.4.1). Version-specific tags are available for all minor releases in the 26.x line.

**Version support:** Customers can upgrade to the latest minor release within the 26.x line without issues. Any 26.x guest image is expected to run on any supported Orka cluster, regardless of the exact minor version of the host OS.

**Orka version requirement:** Orka 3.5.0 or later is required to run Tahoe guest VMs.

**Host OS requirement:** A macOS Sequoia (15.5 or later) host is required.

> [!NOTE]
> macOS 26.1 introduced [changes to the Virtualization framework](https://developer.apple.com/documentation/macos-release-notes/macos-26_1-release-notes#Virtualization) that affect certain VM functionality. Review the Apple release notes to determine if your workflows are impacted before deploying 26.1+ VMs in production.

#### Deploy with the CLI

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:latest
```

To deploy a specific version:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:26.4.1
```

Available version tags: `latest`, `26.4.1`, `26.3`, `26.2`, `26.1`, `26.0.1`

#### Deploy with Orka Desktop

1. Click **+ Create New VM**
2. Select **Pull from OCI registry**
3. Name the VM and set parameters (CPUs, memory, disk size)
4. In the **OCI Image Name** field, enter: `ghcr.io/macstadium/orka-images/tahoe:latest`

---

## SIP-disabled images

SIP-disabled images are required for workflows that automate TCC permissions (for example, Citrix VDA provisioning via Ansible). Deploy with the Orka CLI using the image tags below.

#### macOS Sequoia

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sequoia:latest-no-sip
```

#### macOS Tahoe

SIP-disabled Tahoe images are available for 26.1 and 26.2:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:26.2-no-sip
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:26.1-no-sip
```

#### macOS Sonoma

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sonoma:latest-no-sip
```

#### macOS Ventura

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/ventura:no-sip
```

---

## 200 GB images

Larger disk variants are available for Sequoia and Tahoe:

```sh
orka3 vm deploy --image ghcr.io/macstadium/orka-images/sequoia:200-gb
orka3 vm deploy --image ghcr.io/macstadium/orka-images/tahoe:200-gb
```
