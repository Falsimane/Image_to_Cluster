packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "nginx" {
  image  = "nginx:alpine"
  commit = true
  changes = [
    "EXPOSE 80",
    "CMD [\"nginx\", \"-g\", \"daemon off;\"]"
  ]
}

build {
  name = "pro-builder"
  sources = ["source.docker.nginx"]

  # C'est ici qu'on récupère votre fichier déplacé dans src/
  provisioner "file" {
    source      = "../src/index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  post-processors {
    post-processor "docker-tag" {
      repository = "custom-nginx"
      tags       = ["latest"]
    }
  }
}