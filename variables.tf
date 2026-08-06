variable "vms" {
  description = "The 10 beamline lab VMs: name => { ip, memory (MiB baseline), vcpu, disk_gb, id, virtio_mem }. 'id' is a stable 2-digit number (matches the IP's last octet) used to generate deterministic per-VM MAC addresses. 'virtio_mem' is optional."
  type = map(object({
    ip         = string
    memory     = number
    memory_max = optional(number)
    vcpu       = number
    disk_gb    = number
    id         = number
    virtio_mem = optional(object({
      target_size    = number
      requested_size = number
      block_size     = optional(number, 2)
    }))
  }))

  default = {
    "admin.beamline" = { ip = "10.10.10.11", memory = 2048, vcpu = 2, disk_gb = 20, id = 11,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "gitlab.beamline" = { ip = "10.10.10.12", memory = 6144, vcpu = 2, disk_gb = 40, id = 12,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "pkg.beamline" = { ip = "10.10.10.13", memory = 2048, vcpu = 2, disk_gb = 30, id = 13,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "puppet.beamline" = { ip = "10.10.10.14", memory = 2048, vcpu = 2, disk_gb = 20, id = 14,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "k8cp.beamline" = { ip = "10.10.10.21", memory = 4096, vcpu = 2, disk_gb = 30, id = 21,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "k8w1.beamline" = { ip = "10.10.10.22", memory = 2048, vcpu = 2, disk_gb = 30, id = 22,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "k8w2.beamline" = { ip = "10.10.10.23", memory = 2048, vcpu = 2, disk_gb = 30, id = 23,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "tango-db.beamline" = { ip = "10.10.10.31", memory = 2048, vcpu = 2, disk_gb = 30, id = 31,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "tango-ds.beamline" = { ip = "10.10.10.32", memory = 2048, vcpu = 2, disk_gb = 20, id = 32,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
    "obs.beamline" = { ip = "10.10.10.41", memory = 2048, vcpu = 2, disk_gb = 30, id = 41,
    virtio_mem = { target_size = 2048, requested_size = 512 } }
  }
}

variable "ssh_public_key_path" {
  default = "/home/falak/.ssh/beamline_vms.pub"
}

variable "admin_username" {
  default = "falak"
}

variable "cloudinit_staging_dir" {
  description = "Local directory to stage cloud-init ISOs in before upload to libvirt. Must persist across host reboots (do not point this at /tmp or any tmpfs-backed path)."
  default     = ".cloudinit-staging"
}
