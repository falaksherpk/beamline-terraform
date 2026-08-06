resource "libvirt_volume" "base" {
  name = "ubuntu2404-base.qcow2"
  pool = "default"
  target = {
    format = { type = "qcow2" }
  }
  create = {
    content = {
      url = "file:///home/falak/isos/ubuntu-24.04-server-cloudimg-amd64.img"
    }
  }
}

resource "libvirt_volume" "disk" {
  for_each = var.vms
  name     = "${each.key}.qcow2"
  pool     = "default"
  capacity = each.value.disk_gb * 1024 * 1024 * 1024
  target = {
    format = { type = "qcow2" }
  }
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
}

resource "libvirt_cloudinit_disk" "seed" {
  for_each  = var.vms
  name      = "${each.key}-cloudinit"
  staging_directory = "${path.module}/${var.cloudinit_staging_dir}"

  user_data = templatefile("${path.module}/cloud-init/user-data.tmpl", {
    hostname       = each.key
    username       = var.admin_username
    ssh_public_key = trimspace(file(var.ssh_public_key_path))
    ip             = each.value.ip
    mac_lab        = format("52:54:00:10:10:%02x", each.value.id)
    mac_nat        = format("52:54:00:20:10:%02x", each.value.id)
  })

  meta_data = yamlencode({
    instance-id    = each.key
    local-hostname = each.key
  })
}

resource "libvirt_volume" "cloudinit_iso" {
  for_each = var.vms
  name     = "${each.key}-cloudinit.iso"
  pool     = "default"
  create = {
    content = {
      url = libvirt_cloudinit_disk.seed[each.key].path
    }
  }
}

resource "libvirt_domain" "vm" {
  for_each             = var.vms
  name                 = each.key
  memory               = coalesce(each.value.memory_max, each.value.memory)
  current_memory       = each.value.memory
  maximum_memory       = each.value.virtio_mem != null ? coalesce(each.value.memory_max, each.value.memory) + each.value.virtio_mem.target_size : null
  maximum_memory_unit  = each.value.virtio_mem != null ? "MiB" : null
  maximum_memory_slots = each.value.virtio_mem != null ? 1 : null
  memory_unit          = "MiB"
  current_memory_unit  = "MiB"
  vcpu                 = each.value.vcpu
  type                 = "kvm"
  running              = true

  cpu = {
    mode = "host-passthrough"
    numa = each.value.virtio_mem == null ? null : {
      cell = [
        {
          cpus   = "0-${each.value.vcpu - 1}"
          memory = each.value.memory * 1024
          unit   = "KiB"
        }
      ]
    }
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        driver = { type = "qcow2" }
        source = { file = { file = libvirt_volume.disk[each.key].path } }
        target = { dev = "vda", bus = "virtio" }
      },
      {
        driver = { type = "raw" }
        source = { file = { file = libvirt_volume.cloudinit_iso[each.key].path } }
        target = { dev = "vdb", bus = "virtio" }
      }
    ]
    interfaces = [
      {
        model  = { type = "virtio" }
        mac    = { address = format("52:54:00:10:10:%02x", each.value.id) }
        source = { network = { network = "beamlinenet" } }
      },
      {
        model  = { type = "virtio" }
        mac    = { address = format("52:54:00:20:10:%02x", each.value.id) }
        source = { network = { network = "default" } }
      }
    ]
    memorydevs = each.value.virtio_mem == null ? [] : [
      {
        model = "virtio-mem"
        target = {
          size           = each.value.virtio_mem.target_size
          size_unit      = "MiB"
          block          = coalesce(each.value.virtio_mem.block_size, 2)
          block_unit     = "MiB"
          requested      = each.value.virtio_mem.requested_size
          requested_unit = "MiB"
          node           = 0
        }
      }
    ]
    serials = [
      {
        type   = "pty"
        target = { port = 0 }
      }
    ]
    consoles = [
      {
        type   = "pty"
        target = { type = "serial", port = 0 }
      }
    ]
  }
}

output "vm_ips" {
  value = { for k, v in var.vms : k => v.ip }
}
