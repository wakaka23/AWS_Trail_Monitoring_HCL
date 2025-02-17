variable "target" {
  type = object({
    email_addresses = list(string)
  })
}

variable "bucket" {
  type = object({
    bucket_name_for_TrailLog       = string
    bucket_name_for_TrailAccessLog = string
  })
}
