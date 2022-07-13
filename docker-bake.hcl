# ---- groups ----

group "default" {
  targets = ["image-local"]
}

group "publish" {
  targets = ["publish"]
}

# ---- variables ----

variable "TAUTULLI_RELEASE" {
    default = ""
}

# ---- targets ----

target "docker-metadata-action" {}

target "image" {
  inherits = ["docker-metadata-action"]
  dockerfile = "Dockerfile"
  context = "."
  args = {
    TAUTULLI_RELEASE = TAUTULLI_RELEASE
  }
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

target "publish" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}
