// Configure the Google Cloud provider
provider "google" {
  credentials = file(var.credentials)
  project = var.project_id
  region  = var.region
}

// Create GCP instance JENKINS
resource "google_compute_instance" "JENKINS" {
  name = var.jenkins_name
  machine_type = var.jenkins_machine_type
  zone = var.zone
  tags = var.tags
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    network = var.network

    access_config {
      nat_ip = var.ip_addr_jenkins
    }
  }

// Install ansible to Jenkins instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "sleep 30",
      "sudo apt-get -y update && sudo apt-get -y upgrade",
      "sudo apt-get -y install ansible",


    ]

  }

// COPY ansible files to JENKINS instance
  provisioner "file" {
    source      = "./ansible_files"
    destination = "~/ansible_files"

    connection {
      type     = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }

  provisioner "file" {
    source      = "./docker_files"
    destination = "~/docker_files"

    connection {
      type     = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }
  provisioner "file" {
    source      = "./jenkins_files"
    destination = "~/jenkins_files"

    connection {
      type     = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }

  provisioner "file" {
    source      = "./nginx_files"
    destination = "~/nginx_files"

    connection {
      type     = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }

  metadata = {
    ssh-keys = "inception:${file(var.ssh_key_public)}"
  }


// RUN ansible-playbook in Jenkins instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "ansible-playbook ~/ansible_files/deploy.yml",

    ]

  }
// RUN Docker image with JENKINS
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "mkdir -p ~/Jenkins-Docker/Jenkins_Data",
      "mkdir -p ~/nginx-conf/conf.d",
      "cp ~/nginx_files/nginx.conf ~/nginx-conf/conf.d/nginx.conf",
      "tar -zxf ~/jenkins_files/jenkins_home.tar.gz --directory ~/Jenkins-Docker/Jenkins_Data",
      "docker-compose -f ~/docker_files/jenkins.docker-compose.yml up -d",

    ]

  }
}

// Create GCP instance DEV
resource "google_compute_instance" "DEV" {
  name = var.dev_instance_name
  machine_type = var.dev_machine_type
  zone = var.zone
  tags = var.tags
  boot_disk {
    initialize_params {
      image = var.image
      type = "pd-ssd"
    }
  }
  network_interface {
    network = var.network

    access_config {
      nat_ip = var.ip_addr_dev_instance
      # Ephemeral
    }
  }

//// Install ansible to DEV instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "sleep 30",
      "sudo apt-get -y update && sudo apt-get -y upgrade",
      "sudo apt-get -y install ansible",


    ]

  }

// COPY ansible files to DEV instance
  provisioner "file" {
    source      = "./ansible_files"
    destination = "~/ansible_files"

    connection {
      type     = "ssh"
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }

  metadata = {
    ssh-keys = "inception:${file(var.ssh_key_public)}"
  }

//// RUN ansible-playbook in  DEV instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "ansible-playbook ~/ansible_files/deploy.yml",

    ]

  }
}

// Create GCP instance PROD
resource "google_compute_instance" "PROD" {
  name = var.prod_instance_name
  machine_type = var.prod_machine_type
  zone = var.zone
  tags = var.tags
  boot_disk {
    initialize_params {
      image = var.image
      type = "pd-ssd"
    }
  }
  network_interface {
    network = var.network

    access_config {
      nat_ip = var.ip_addr_prod_instance
    }
  }

  // Install ansible to PROD instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "sleep 30",
      "sudo apt-get -y update && sudo apt-get -y upgrade",
      "sudo apt-get -y install ansible",


    ]

  }

  // COPY ansible files to PROD instance
  provisioner "file" {
    source      = "./ansible_files"
    destination = "~/ansible_files"

    connection {
      type     = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
      agent = "false"
    }
  }

  metadata = {
    ssh-keys = "inception:${file(var.ssh_key_public)}"
  }

  // RUN ansible-playbook in PROD instance
  provisioner "remote-exec" {
    connection {
      type        = var.connection_type
      host        = self.network_interface[0].access_config[0].nat_ip
      user        = var.user
      timeout     = var.connection_timeout
      private_key = file(var.ssh_key_private)
    }

    inline = [
      "ansible-playbook ~/ansible_files/deploy.yml",

    ]

  }
}