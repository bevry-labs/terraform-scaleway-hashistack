variable "output_path" {
  type = "string"
}

variable "private_key_path" {
  type = "string"
}

variable "type" {
  type = "string" # origin, master, slave
}

variable "count" {
  type    = "string"
  default = 1
}

variable "join" {
  type    = "string"
  default = ""
}

variable "region" {
  type = "string"
}

variable "image" {
  type = "string"
}

variable "bootscript" {
  type    = "string"
  default = ""
}

variable "consul_expect" {
  type    = "string"
  default = 0
}

variable "nomad_expect" {
  type    = "string"
  default = 0
}

variable "nomad_token" {
  type    = "string"
  default = ""
}
