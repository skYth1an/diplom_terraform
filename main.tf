terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

#Provider settngs
provider "yandex" {
  cloud_id  = "${var.cloud_id}"
  folder_id = "${var.folder_id}"
  zone = "ru-central1-a"
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

resource "yandex_compute_instance" "kuber" {
  count = 2
  name           = "kuber-zone1-${count.index + 1}"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

    metadata = {
      ssh-keys = "ubuntu:${file("/home/vagrant/.ssh/id_rsa.pub")}"
    }

}

resource "yandex_compute_instance" "kuber2" {
  count = 1
  name           = "kuber-zone2-${count.index + 1}"

  resources {
    cores  = 2
    memory = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public2.id
    nat       = true
  }

    metadata = {
      ssh-keys = "ubuntu:${file("/home/vagrant/.ssh/id_rsa.pub")}"
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
  network_id     = yandex_vpc_network.network.id
  folder_id      = "${var.folder_id}"
}

resource "yandex_vpc_subnet" "public2" {
  name = "public2"
  v4_cidr_blocks = ["10.2.0.0/16"]
  zone           = "${var.zone2}"
  network_id     = yandex_vpc_network.network.id
  folder_id      = "${var.folder_id}"
}


