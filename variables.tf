variable "data_path" {
  type = "string"
}

variable "private_key_path" {
  type = "string"
}

variable "type" {
  type = "string" # origin, master, slave
}

variable "state" {
  type    = "string"  # running, stopped
  default = "running"
}

variable "hostname" {
  type = "string"
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
