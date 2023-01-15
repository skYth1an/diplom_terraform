terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


resource "yandex_iam_service_account" "sa" {
  name = "k8s"
  folder_id      = "${var.folder_id}"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "creator" {
  folder_id = "${var.folder_id}"
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

#Группа хостов
resource "yandex_compute_instance_group" "group1" {
  name                = "group1"
  folder_id = "${var.folder_id}"
  service_account_id  = "${yandex_iam_service_account.sa.id}"
  deletion_protection = false
  instance_template {
    resources {
      memory = 2
      cores  = 2
      core_fraction = 20
    }
    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }
    network_interface {
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
      nat = true
    }

    metadata = {
      user-data = "${file("data.txt")}"
      #ssh-keys = "ubuntu:${file("/home/vagrant/.ssh/id_rsa.pub")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["${var.zone}"]
  }

  deploy_policy {
    max_unavailable = 3
    max_creating    = 3
    max_expansion   = 3
    max_deleting    = 3
  }
}



resource "yandex_vpc_network" "network" {
  name = "network"
  folder_id      = "${var.folder_id}"
}

resource "yandex_vpc_subnet" "public" {
  name = "public"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "${var.zone}"
  network_id     = "${yandex_vpc_network.network.id}"
  folder_id      = "${var.folder_id}"
}


