variable "common" {
  type = object({
    env        = string
    region     = string
    account_id = string
  })
}

variable "target" {
  type = object({
    email_addresses = list(string)
  })
}

variable "cloudtrail" {
  type = object({
    log_group_name = string
  })
}
